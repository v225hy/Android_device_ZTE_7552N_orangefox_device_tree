#
#	This file is part of the OrangeFox Recovery Project
# 	Copyright (C) 2026 The OrangeFox Recovery Project
#
#	OrangeFox is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	any later version.
#
#	OrangeFox is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
# 	This software is released under GPL version 3 or any later version.
#	See <http://www.gnu.org/licenses/>.
#
# 	Please maintain this if you use this script or any part of it
#

# OrangeFox-specific settings for ZTE 7552N (P720S20 / Unisoc UMS9620)
#
# NOTE: device-tree configuration variables use the OF_* prefix
# (OrangeFox R12 / fox_12.1). The FOX_* prefix is only used internally by
# the build system (build/make, vendor/recovery/OrangeFox_A12.sh) and by
# envsetup-time environment variables.

# === Screen settings ===
# ZTE 7552N: 5.0" 480x854 IPS TFT
OF_SCREEN_H := 854
OF_STATUS_H := 24
OF_STATUS_INDENT_LEFT := 0
OF_STATUS_INDENT_RIGHT := 0
OF_CLOCK_POS := 1
OF_OPTIONS_LIST_NUM := 5
OF_HIDE_NOTCH := 0
OF_SPLASH_MAX_SIZE := 130

# === Device type ===
# A/B device; recovery lives in vendor_boot (no standalone recovery partition)
FOX_AB_DEVICE := 1
TW_MAX_BRIGHTNESS := 255

# === Binary tool selection ===
OF_USE_LZ4_BINARY := 1
OF_USE_XZ_UTILS := 1
OF_USE_ZSTD_BINARY := 1
OF_USE_TAR_BINARY := 1
OF_USE_BUSYBOX_BINARY := 1
OF_USE_SED_BINARY := 1
OF_USE_GREP_BINARY := 1
OF_USE_DATE_BINARY := 1
OF_USE_DD_BINARY := 1
OF_USE_BASH_SHELL := 1
OF_USE_MAGISKBOOT := 1
OF_USE_FSCK_EROFS_BINARY := 1
OF_USE_PATCHELF_BINARY := 1
OF_REPLACE_BUSYBOX := 1
OF_DELETE_AROMAFM := 1
OF_ENABLE_ALL_PARTITION_TOOLS := 1

# === Encryption / FBE (Unisoc Trusty KeyMint 2.0 / Gatekeeper 1.0) ===
OF_DEFAULT_KEYMASTER_VERSION := 2.0
OF_SKIP_FBE_DECRYPTION := 0
OF_FORCE_DATA_FORMAT_F2FS := 1
OF_WIPE_METADATA_AFTER_DATAFORMAT := 1
OF_DISABLE_MIUI_OTA_BY_DEFAULT := 1

# === Workarounds ===
OF_NO_TREBLE_COMPATIBILITY_CHECK := 1
OF_NO_RELOAD_AFTER_DECRYPTION := 1
OF_USE_LEGACY_TIME_FIXUP := 1
OF_ENABLE_FRP_ADDON := 1
FOX_VANILLA_BUILD := 1
OF_ALLOW_EARLY_SETTINGS_LOAD := 1

# === Misc ===
OF_QUICK_BACKUP_LIST := /boot;/data;
OF_SETTINGS_ROOT_DIRECTORY := /data/recovery
OF_MISCELLANEOUS_ROOT_DIRECTORY := /sdcard
OF_USE_UPDATED_MAGISKBOOT := 1
OF_MOVE_MAGISK_INSTALLER_TO_RAMDISK := 1
OF_USE_TWRP_FEEDBACK := 0
