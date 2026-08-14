# OrangeFox device tree for ZTE 7552N / P720S20

fork from https://github.com/byf3332/ZTE-7552N-P720S20-devicetree

This repository contains the OrangeFox Recovery (TWRP-based, fox_12.1 / R12)
device tree for the ZTE 7552N (`P720S20`, `ums9620_2h10`).

## Status

**Functional** — builds a working OrangeFox 12.1 `vendor_boot` image.
Decryption, backup/restore, MTP, adb and Magisk work. The previous
"infinite recovery loop" bug is fixed (see below).

Known limitations are listed in [Known Issues](#known-issues).

## Device specifications

| Component | Value |
| --- | --- |
| Device | ZTE 7552N |
| Product | P720S20 |
| Platform | Unisoc UMS9620 |
| Board | ums9620_2h10 |
| Android version | Android 13 |
| Architecture | arm64 |
| Partition scheme | A/B |
| Recovery location | `vendor_boot` |
| Vendor boot header | Version 4 |
| Vendor boot partition size | 104857600 bytes |
| Vendor ramdisk compression | Legacy LZ4 |

## Boot image layout

The device has no standalone recovery partition. Recovery resources are stored
in `vendor_boot` using the stock layout:

- one vendor ramdisk table entry of type `PLATFORM`
- no separate `RECOVERY` vendor ramdisk fragment
- no separate `DLKM` vendor ramdisk fragment
- generic kernel image boot flow
- stock device tree blob

The corresponding build configuration uses:

```make
BOARD_USES_GENERIC_KERNEL_IMAGE := true
BOARD_MOVE_RECOVERY_RESOURCES_TO_VENDOR_BOOT := true
TARGET_NO_RECOVERY := true
```

`BOARD_INCLUDE_RECOVERY_RAMDISK_IN_VENDOR_BOOT` is left unset to preserve the
single-`PLATFORM` vendor ramdisk layout.

## Implementation

The vendor ramdisk is constructed from the stock platform ramdisk and the TWRP
recovery root.

The tree includes build-time handling for:

- stock first-stage ramdisk files and fstab variants
- stock kernel modules and recovery module load list
- Virtual A/B and `snapuserd` support
- Unisoc recovery init and ueventd configuration
- first-stage fstab preparation
- ramdisk file permission metadata
- TWRP recovery SELinux policy and contexts
- Unisoc configfs USB setup
- Unisoc DRM/KMS display support
- ext4, F2FS, EROFS and VFAT filesystems
- fastbootd and recovery repacking tools
- Android FBE and metadata encryption support

The display build hook installs TeamWin's generic DRM/KMS backend before
`libminuitwrp` is compiled. The backend uses standard KMS CRTC and page-flip
operations suitable for the device's `sprd-drm` driver.

## Recovery bootloop fix (BCB / misc workaround)

The Unisoc UMS9620 bootloader stores a `boot-recovery` command in the **misc**
partition's Bootloader Control Block (BCB). OrangeFox/TWRP's own
`clear_bootloader_message()` path does not reliably clear this flag on this
device, so after entering recovery once the phone would re-enter recovery on
every subsequent reboot (including "Reboot to system" and "Reboot to bootloader"
from recovery) — an infinite recovery loop.

This tree fixes it at the ramdisk level:

- `recovery/root/clear_bcb.sh` zeroes the BCB command field (first 32 bytes of
  `/dev/block/by-name/misc`) using a robust `dd`/misc-path lookup.
- `recovery/root/init.recovery.common.rc` starts the `clear_bcb` service from
  the **`on property:ro.bootmode=recovery`** block (the only block that reliably
  fires in this recovery's init; `on boot` does **not** fire here), so the
  `boot-recovery` flag is cleared every time recovery starts. After that, the
  next reboot goes to the system instead of looping.

> Note: hooking `clear_bcb` to `on boot` does not work on this device — only
> `on property:ro.bootmode=recovery` is triggered by the recovery init.

If you ever get stuck in the loop with an older image, the escape is:
`fastboot erase misc` (clears the whole misc partition), or from recovery
`adb shell dd if=/dev/zero of=/dev/block/by-name/misc bs=1 count=32 conv=notrunc`
followed by `adb reboot`.

## Screen / UI notes

The recovery framebuffer is 480x854 (portrait). The OrangeFox theme base
resolution is 1080x1920, so the GUI scales uniformly by ~0.444 on both axes.

**Do not set `OF_SCREEN_H`** in `fox_P720S20.mk`: forcing it to 854 makes the
height scale 1.0 while the width stays 0.444, producing a 2.25x horizontal
stretch (stretched icons, oversized bottom bar, broken keyboard scaling).
Letting `OF_SCREEN_H` default to 1920 keeps the aspect ratio uniform.
`OF_STATUS_H` is in theme-base px (1920-tall); `54` ≈ 24 physical px.

## Known Issues

### 1. "Reboot to Fastboot" enters recovery instead of fastbootd
`TW_INCLUDE_FASTBOOTD := true` is enabled and the `fastbootd` binary is present
in the ramdisk at `/system/bin/fastbootd`, but the Unisoc UMS9620 bootloader
does not appear to support userspace `fastbootd` mode (`reboot fastboot`), so it
boots `vendor_boot` in recovery mode instead. This is a bootloader/firmware
limitation, not a ramdisk bug.

**Workaround:** reach the bootloader's `fastboot` (not fastbootd) mode via the
hardware key combo (Power + Vol Down at boot) or `adb reboot bootloader`. All
standard `fastboot` commands (flash, boot, etc.) work there.

### 2. Data (FBE) user-0 not decrypted after metadata decryption
On boot the recovery decrypts the metadata-encrypted `/data`
(`/dev/block/dm-6`) and mounts it, then attempts File-Based Encryption (FBE)
decryption for user 0. If the device has a lock screen, user-0 decryption
requires the lock-screen credential (PIN / pattern / password) at the recovery
decryption prompt. Until that is entered, `User 0 is not decrypted` and the
per-user files remain encrypted — this is expected FBE behavior, not a failure.

**If decryption appears to fail:** make sure you enter the correct lock-screen
credential when the prompt appears; a wrong/absent credential leaves user 0
encrypted. (Metadata decryption itself works.)

### 3. Intermittent hang on the OrangeFox logo
Occasionally entering OrangeFox hangs on the splash/logo and never reaches the
GUI. This is an intermittent display/theme init race and is not reproducible on
demand.

**Workaround:** force-reboot (hold Power ~10s) and re-enter recovery. If it
persists across reboots, re-flash `vendor_boot`.

## Build

Built with the OrangeFox 12.1 (`fox_12.1`) manifest via the
OrangeFox-Recovery-Builder workflow. Key device flags live in
`fox_P720S20.mk`:

- `FOX_AB_DEVICE := 1` — A/B device; recovery in `vendor_boot`.
- `OF_STATUS_H := 54` — status-bar height (see Screen notes).
- `OF_DEFAULT_KEYMASTER_VERSION := 2.0`, `OF_SKIP_FBE_DECRYPTION := 0` —
  Unisoc Trusty KeyMint 2.0 / Gatekeeper 1.0 FBE support.
- `TW_INCLUDE_FASTBOOTD := true`, `TW_INCLUDE_CRYPTO := true`.
