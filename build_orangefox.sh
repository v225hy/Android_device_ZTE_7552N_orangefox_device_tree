#!/bin/bash
#
# build_orangefox.sh - One-click OrangeFox build script for ZTE 7552N (P720S20)
#
# Usage:  bash build_orangefox.sh [--sync-only] [--build-only] [--full]
#
# Requirements: Ubuntu 20.04/22.04, 16GB+ RAM, 250GB+ disk
#

set -e

# === Configuration ===
OF_BRANCH="12.1"
OF_SYNC_DIR="${HOME}/OrangeFox_sync"
OF_BUILD_DIR="${HOME}/fox_12.1"
DEVICE_TREE_URL="https://github.com/byf3332/ZTE-7552N-P720S20-devicetree.git"
DEVICE_TREE_BRANCH="main"
DEVICE_PATH="device/zte/P720S20"
DEVICE_NAME="P720S20"
BUILD_TARGET="vendorbootimage"

MODE="${1:---full}"

echo "============================================"
echo "  OrangeFox Build - ZTE 7552N (P720S20)"
echo "  Branch: OrangeFox-${OF_BRANCH}"
echo "  Target: ${BUILD_TARGET}"
echo "============================================"
echo ""

# === Step 1: Install build dependencies ===
if [[ "${MODE}" == "--full" || "${MODE}" == "--sync-only" ]]; then
    echo ">>> [1/5] Installing build dependencies..."
    sudo apt update
    sudo apt -y upgrade
    if [[ ! -d "${HOME}/scripts" ]]; then
        git clone https://gitlab.com/OrangeFox/misc/scripts "${HOME}/scripts"
    fi
    cd "${HOME}/scripts"
    sudo bash setup/android_build_env.sh
    echo ""
fi

# === Step 2: Sync OrangeFox source ===
if [[ "${MODE}" == "--full" || "${MODE}" == "--sync-only" ]]; then
    echo ">>> [2/5] Syncing OrangeFox source tree (this will take a while)..."
    mkdir -p "${OF_SYNC_DIR}"
    cd "${OF_SYNC_DIR}"
    if [[ ! -d "sync" ]]; then
        git clone https://gitlab.com/OrangeFox/sync.git
    fi
    cd sync
    ./orangefox_sync.sh --branch "${OF_BRANCH}" --path "${OF_BUILD_DIR}"
    echo ""
fi

# === Step 3: Clone device tree ===
if [[ "${MODE}" == "--full" || "${MODE}" == "--build-only" ]]; then
    echo ">>> [3/5] Cloning device tree..."
    cd "${OF_BUILD_DIR}"
    if [[ -d "${DEVICE_PATH}" ]]; then
        echo "    Device tree already exists, pulling latest..."
        cd "${DEVICE_PATH}"
        git pull origin "${DEVICE_TREE_BRANCH}" || true
        cd "${OF_BUILD_DIR}"
    else
        git clone -b "${DEVICE_TREE_BRANCH}" "${DEVICE_TREE_URL}" "${DEVICE_PATH}"
    fi
    echo ""
fi

# === Step 4: Initialize build environment ===
if [[ "${MODE}" == "--full" || "${MODE}" == "--build-only" ]]; then
    echo ">>> [4/5] Initializing build environment..."
    cd "${OF_BUILD_DIR}"
    /bin/bash
    source build/envsetup.sh
    export ALLOW_MISSING_DEPENDENCIES=true
    export FOX_BUILD_DEVICE="${DEVICE_NAME}"
    export LC_ALL="C"

    # Apply device tree patches and OrangeFox env vars
    echo "    Sourcing vendorsetup.sh..."
    . "${OF_BUILD_DIR}/${DEVICE_PATH}/vendorsetup.sh"
    echo ""
fi

# === Step 5: Build ===
if [[ "${MODE}" == "--full" || "${MODE}" == "--build-only" ]]; then
    echo ">>> [5/5] Building OrangeFox (this will take 1-2 hours)..."
    cd "${OF_BUILD_DIR}"
    lunch "twrp_${DEVICE_NAME}-eng"
    mka adbd "${BUILD_TARGET}"
    echo ""
    echo "============================================"
    echo "  Build complete!"
    echo "============================================"
    echo ""
    echo "Output files:"
    ls -la "${OF_BUILD_DIR}/out/target/product/${DEVICE_NAME}/"*.img 2>/dev/null || \
        echo "  (check out/target/product/${DEVICE_NAME}/ for output files)"
    echo ""
    echo "To flash:"
    echo "  adb reboot bootloader"
    echo "  fastboot flash vendor_boot ${OF_BUILD_DIR}/out/target/product/${DEVICE_NAME}/OrangeFox*.img"
    echo "  fastboot reboot recovery"
fi
