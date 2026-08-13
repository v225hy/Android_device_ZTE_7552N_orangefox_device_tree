#
# Copyright (C) 2026 The Android Open Source Project
# Copyright (C) 2026 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/twrp_P720S20.mk \
    $(LOCAL_DIR)/omni_P720S20.mk

COMMON_LUNCH_CHOICES := \
    twrp_P720S20-user \
    twrp_P720S20-userdebug \
    twrp_P720S20-eng \
    omni_P720S20-user \
    omni_P720S20-userdebug \
    omni_P720S20-eng
