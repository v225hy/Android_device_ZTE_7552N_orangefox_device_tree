#
# Copyright (C) 2026 The Android Open Source Project
# Copyright (C) 2026 SebaUbuntu's TWRP device tree generator
#
# SPDX-License-Identifier: Apache-2.0
#
# OrangeFox 12.1 product makefile for ZTE 7552N (P720S20 / Unisoc UMS9620)
#
# OrangeFox 12.1 expects the "omni_" product name (lunch omni_<device>-eng).
# twrp_P720S20.mk already inherits fox_P720S20.mk (all OF_* OrangeFox
# settings), so this product reuses the exact same device + OrangeFox
# configuration and only overrides PRODUCT_NAME.

DEVICE_PATH := device/zte/P720S20

$(call inherit-product, $(DEVICE_PATH)/twrp_P720S20.mk)

PRODUCT_NAME := omni_P720S20
