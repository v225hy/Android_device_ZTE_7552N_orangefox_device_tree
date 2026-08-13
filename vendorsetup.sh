#
# vendorsetup.sh - P720S20 OrangeFox build preparation
#
# This script patches the recovery and vold source trees for Unisoc UMS9620
# compatibility, then sets OrangeFox build environment variables.
#
# When building with the OrangeFox manifest, the bootable/recovery source is
# OrangeFox's fork of TWRP. Most patches apply cleanly, but some may fail if
# OrangeFox has already modified the same code areas. Failed patches print a
# warning but do not abort the build.
#

# Legacy compatibility. AndroidProducts.mk is the authoritative lunch list.
add_lunch_combo twrp_P720S20-eng

# === OrangeFox environment variables ===
export LC_ALL="C"
export FOX_BUILD_DEVICE="P720S20"
export FOX_AB_DEVICE=1
export FOX_USE_LZ4_BINARY=1
export FOX_USE_SED_BINARY=1
export FOX_USE_GREP_BINARY=1
export FOX_USE_BUSYBOX_BINARY=1
export FOX_USE_XZ_UTILS=1
export FOX_USE_ZSTD_BINARY=1
export FOX_USE_DATE_BINARY=1
export FOX_USE_TAR_BINARY=1
export FOX_USE_FSCK_EROFS_BINARY=1
export FOX_USE_PATCHELF_BINARY=1
export FOX_DELETE_AROMAFM=1
export FOX_VANILLA_BUILD=1
export FOX_ALLOW_EARLY_SETTINGS_LOAD=1
export FOX_SETTINGS_ROOT_DIRECTORY=/data/recovery
export FOX_MISCELLANEOUS_ROOT_DIRECTORY=/sdcard
export FOX_USE_UPDATED_MAGISKBOOT=1
export FOX_MOVE_MAGISK_INSTALLER_TO_RAMDISK=1

# === Locate build root and device tree ===
_p720s20_tree_dir="$(
    cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd
)"
_p720s20_android_top="${ANDROID_BUILD_TOP:-}"
if [[ -z "${_p720s20_android_top}" ]] && declare -F gettop >/dev/null 2>&1; then
    _p720s20_android_top="$(gettop)"
fi
if [[ -z "${_p720s20_android_top}" ]]; then
    echo "P720S20: unable to locate Android build root" >&2
    return 1
fi

# Helper: apply a patch, warn (not fail) if it does not apply.
_p720s20_patch() {
    local patch_file="$1"
    local patch_name
    patch_name="$(basename "${patch_file}" .patch)"
    if patch -d "${_p720s20_android_top}/bootable/recovery" -p1 \
        --dry-run < "${patch_file}" 2>/dev/null; then
        patch -d "${_p720s20_android_top}/bootable/recovery" -p1 \
            < "${patch_file}"
        echo "[P720S20] Applied patch: ${patch_name}"
    else
        echo "[P720S20] WARNING: patch '${patch_name}' does not apply cleanly (OrangeFox source may differ). Skipping."
    fi
}

# Helper: run a Python source modifier, warn (not fail) on error.
_p720s20_pytool() {
    local tool="$1"
    shift
    local tool_name
    tool_name="$(basename "${tool}" .py)"
    if python3 "${tool}" "$@"; then
        echo "[P720S20] Applied tool: ${tool_name}"
    else
        echo "[P720S20] WARNING: tool '${tool_name}' failed (OrangeFox source may differ). Continuing."
    fi
}

# === Apply recovery source patches ===
# These modify TWRP/OrangeFox recovery source for Unisoc compatibility.
# Non-critical patches are allowed to fail without aborting.

_p720s20_patch "${_p720s20_tree_dir}/patches/default_timezone.patch"
_p720s20_patch "${_p720s20_tree_dir}/patches/load_default_language_before_decrypt.patch"
_p720s20_patch "${_p720s20_tree_dir}/patches/unisoc_fastboot_bootmode.patch"
_p720s20_patch "${_p720s20_tree_dir}/patches/single_user_decryption_state.patch"
_p720s20_patch "${_p720s20_tree_dir}/patches/hide_unsupported_advanced_actions.patch"
_p720s20_patch "${_p720s20_tree_dir}/patches/preserve_boot_fastboot_bcb.patch"
_p720s20_patch "${_p720s20_tree_dir}/patches/unisoc_mtp_ffs_v1.patch"

# === Install generic DRM/KMS backend ===
# CRITICAL: Unisoc sprd-drm is incompatible with TWRP's default Qualcomm SDE
# atomic backend. This replaces graphics_drm.cpp with a generic KMS backend.
# This should work with OrangeFox since the file structure is the same.
_p720s20_pytool "${_p720s20_tree_dir}/tools/install_generic_drm_backend.py" \
    "${_p720s20_tree_dir}/patches/graphics_drm.cpp" \
    "${_p720s20_android_top}/bootable/recovery/minuitwrp/graphics_drm.cpp"

# === Apply vold and recovery C++ source modifications ===
# These fix FBE metadata decryption, battery status, BCB reboot, and other
# Unisoc-specific issues. They use string matching and may fail if OrangeFox
# has modified the same source files.
_p720s20_pytool "${_p720s20_tree_dir}/tools/install_p720s20_reboot_bcb.py" \
    "${_p720s20_android_top}/bootable/recovery/twrp-functions.cpp"

_p720s20_pytool "${_p720s20_tree_dir}/tools/install_p720s20_battery_status.py" \
    "${_p720s20_android_top}/bootable/recovery/twrp.cpp"

_p720s20_pytool "${_p720s20_tree_dir}/tools/install_p720s20_keystore2_fix.py" \
    "${_p720s20_android_top}/system/vold/Keymaster.cpp" \
    "${_p720s20_android_top}/system/vold/Keymaster.h" \
    "${_p720s20_android_top}/system/vold/KeyStorage.cpp" \
    "${_p720s20_android_top}/system/vold/MetadataCrypt.cpp" \
    "${_p720s20_android_top}/system/vold/KeyUtil.cpp"

_p720s20_pytool "${_p720s20_tree_dir}/tools/install_p720s20_metadata_fbe_remount.py" \
    "${_p720s20_android_top}/bootable/recovery/partitionmanager.cpp"

_p720s20_pytool "${_p720s20_tree_dir}/tools/install_p720s20_gatekeeper_token_guard.py" \
    "${_p720s20_android_top}/system/vold/Decrypt.cpp"

_p720s20_pytool "${_p720s20_tree_dir}/tools/install_p720s20_fbe_compat.py" \
    "${_p720s20_android_top}/system/vold/FsCrypt.cpp" \
    "${_p720s20_android_top}/system/vold/Decrypt.cpp"

_p720s20_pytool "${_p720s20_tree_dir}/tools/install_p720s20_adb_reboot.py" \
    "${_p720s20_android_top}/system/core/reboot/reboot.c"

unset _p720s20_android_top _p720s20_tree_dir
unset -f _p720s20_patch _p720s20_pytool
