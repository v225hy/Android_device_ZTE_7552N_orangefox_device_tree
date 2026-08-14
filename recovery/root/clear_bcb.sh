#!/sbin/sh
# Clear the bootloader control block (BCB) "boot-recovery" command on recovery
# entry. The Unisoc UMS9620 bootloader stores "boot-recovery" in the misc
# partition's BCB; OrangeFox/TWRP's own clear_bootloader_message path does not
# reliably clear it on this device, so the phone re-enters recovery after every
# reboot. Zeroing the command field (first 32 bytes) makes the bootloader boot
# the system on the next power-on instead of looping back into recovery.
#
# This runs on recovery entry only (triggered by init.recovery.common.rc), so
# it never touches the normal system boot.

# Locate a usable dd (toybox applet injected by the OrangeFox build).
DD=""
for d in /sbin/dd /system/bin/dd /system/xbin/dd /busybox/dd; do
    if [ -x "$d" ]; then DD="$d"; break; fi
done
[ -z "$DD" ] && exit 0

# Locate the misc partition (by-name preferred, raw block device fallback).
MISC=""
for m in /dev/block/by-name/misc /dev/block/sda3; do
    if [ -b "$m" ]; then MISC="$m"; break; fi
done
[ -z "$MISC" ] && exit 0

# command field is char command[32]; zero it in place.
"$DD" if=/dev/zero of="$MISC" bs=1 count=32 conv=notrunc 2>/dev/null

exit 0
