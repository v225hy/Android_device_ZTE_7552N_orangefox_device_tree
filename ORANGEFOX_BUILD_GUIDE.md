# OrangeFox 构建指南 — ZTE 7552N (P720S20)

## 设备信息

| 项目 | 值 |
|---|---|
| 设备 | ZTE 畅行60 (7552N) |
| 代号 | P720S20 |
| 平台 | Unisoc UMS9620 (Tanggula T760) |
| Android | 13 |
| 分区方案 | A/B |
| Recovery 位置 | vendor_boot (无独立 recovery 分区) |
| 屏幕分辨率 | 480 x 854 (5.0") |
| Vendor Boot Header | v4 |
| Ramdisk 压缩 | Legacy LZ4 |

## 适配说明

本设备树原始为 TWRP 12.1 设备树，已做以下 OrangeFox 适配：

1. **新增 `fox_P720S20.mk`** — OrangeFox 专用 OF_* 变量（屏幕、加密、功能开关）
2. **修改 `vendorsetup.sh`** — 添加 FOX_* 环境变量；补丁失败时打印警告而非中断构建（OrangeFox 源码与 TWRP 可能有差异）
3. **更新 `AndroidProducts.mk`** — 添加 user/userdebug lunch 选项

其余文件（BoardConfig.mk、device.mk、recovery.fstab、recovery/root/、patches/、tools/、prebuilt/）保持不变，因为：
- OrangeFox 基于 TWRP，`vendor/twrp/config/common.mk` 在 OrangeFox 源码树中会被替换为 OrangeFox 版本
- recovery.fstab 格式与 TWRP 完全兼容
- BOARD_RECOVERY_IMAGE_PREPARE 钩子操作的是构建产物而非源码，与 recovery 分支无关

## 构建方式

### 方式一：Linux 本地构建（推荐）

#### 1. 环境要求

- Ubuntu 20.04 或 22.04 (64-bit)
- 至少 16GB RAM（推荐 32GB）
- 至少 250GB 可用磁盘空间
- Python 2.7 + Python 3.x

```bash
# 安装构建依赖
sudo apt update

sudo apt -y upgrade
git clone https://gitlab.com/OrangeFox/misc/scripts
cd scripts
sudo bash setup/android_build_env.sh
```

#### 2. 同步 OrangeFox 源码

```bash
mkdir ~/OrangeFox_sync
cd ~/OrangeFox_sync
git clone https://gitlab.com/OrangeFox/sync.git
cd sync
./orangefox_sync.sh --branch 12.1 --path ~/fox_12.1
```

同步完成后，源码树位于 `~/fox_12.1/`。

#### 3. 放置设备树

```bash
cd ~/fox_12.1
git clone https://github.com/byf3332/ZTE-7552N-P720S20-devicetree.git device/zte/P720S20
```

> 如果你对设备树做了本地修改，直接复制到 `device/zte/P720S20/` 即可。

#### 4. 初始化构建环境

```bash
cd ~/fox_12.1
/bin/bash
source build/envsetup.sh
export ALLOW_MISSING_DEPENDENCIES=true
export FOX_BUILD_DEVICE=P720S20
export LC_ALL="C"
```

#### 5. 应用设备树补丁

```bash
. device/zte/P720S20/vendorsetup.sh
```

此脚本会：
- 对 `bootable/recovery` 应用 7 个补丁（时区、语言、fastboot 模式等）
- 安装 Unisoc 通用 DRM/KMS 后端（**关键**，否则屏幕无显示）
- 修改 vold 和 recovery C++ 源码以支持 FBE 元数据解密
- 设置 OrangeFox FOX_* 环境变量

> 注意：部分补丁可能因 OrangeFox 源码与 TWRP 有差异而跳过，脚本会打印 WARNING 但不会中断。

#### 6. 开始构建

```bash
lunch twrp_P720S20-eng
mka adbd vendorbootimage
```

> 构建目标为 `vendorbootimage`，因为本设备的 recovery 资源存储在 vendor_boot 分区中。

#### 7. 获取构建产物

```bash
ls -la out/target/product/P720S20/vendor_boot.img
# OrangeFox 产出的文件名通常为 OrangeFox-*.img
ls -la out/target/product/P720S20/OrangeFox*.img
```

#### 8. 刷入设备

```bash
# 进入 fastboot 模式
adb reboot bootloader

# 刷入 vendor_boot
fastboot flash vendor_boot out/target/product/P720S20/OrangeFox*.img

# 重启到 recovery
fastboot reboot recovery
```

### 方式二：GitHub Actions 云端构建

如果你没有 Linux 环境，可以使用 GitHub Actions 自动构建：

1. Fork [dien1122/OrangeFox-Recovery-Builder-2024](https://github.com/dien1122/OrangeFox-Recovery-Builder-2024)
2. 进入你 fork 的仓库 → Actions → "OrangeFox - Build" → Run workflow
3. 填写参数：

| 参数 | 值 |
|---|---|
| MANIFEST_BRANCH | `12.1` |
| DEVICE_TREE_URL | `https://github.com/byf3332/ZTE-7552N-P720S20-devicetree.git` |
| DEVICE_TREE_BRANCH | `main` |
| DEVICE_PATH | `device/zte/P720S20` |
| DEVICE_NAME | `P720S20` |
| BUILD_TARGET | `vendorboot` |
| LDCHECK | `system/bin/sprdstorageproxyd` |
| RECOVERY_INSTALLER | `true` |

4. 点击 "Run workflow" 开始构建（约 1-2 小时）
5. 构建完成后在 Releases 页面下载 `vendor_boot.img`

> **重要限制**：GitHub Actions 构建器不会自动执行 `vendorsetup.sh`，因此 DRM 后端替换和源码补丁不会被应用。这可能导致：
> - 屏幕无显示（缺少 Unisoc DRM 后端）
> - FBE 解密失败
> - fastboot 模式异常
>
> 如果使用此方式，你需要修改 workflow YAML，在 "Building OrangeFox" 步骤之前添加：
> ```bash
> . device/zte/P720S20/vendorsetup.sh
> ```

## 补丁说明

| 补丁/工具 | 作用 | 重要性 |
|---|---|---|
| `install_generic_drm_backend.py` | 替换 DRM 后端为通用 KMS（适配 Unisoc sprd-drm） | **关键** |
| `default_timezone.patch` | 默认时区改为东八区，24小时制 | 次要 |
| `load_default_language_before_decrypt.patch` | 解密前加载默认语言 | 次要 |
| `unisoc_fastboot_bootmode.patch` | 修复 Unisoc fastboot 模式检测 | 重要 |
| `single_user_decryption_state.patch` | 单用户解密状态 | 重要 |
| `hide_unsupported_advanced_actions.patch` | 隐藏不支持的高级操作 | 次要 |
| `preserve_boot_fastboot_bcb.patch` | 保留 boot/fastboot BCB 状态 | 重要 |
| `unisoc_mtp_ffs_v1.patch` | Unisoc MTP FFS v1 支持 | 重要 |
| `install_p720s20_keystore2_fix.py` | 修复 keystore2 FBE 兼容性 | **关键** |
| `install_p720s20_fbe_compat.py` | FBE 兼容性修复 | **关键** |
| `install_p720s20_gatekeeper_token_guard.py` | Gatekeeper token 保护 | 重要 |
| `install_p720s20_metadata_fbe_remount.py` | metadata 分区 FBE 重挂载 | 重要 |
| `install_p720s20_battery_status.py` | 电池状态读取 | 次要 |
| `install_p720s20_reboot_bcb.py` | BCB 重启修复 | 次要 |
| `install_p720s20_adb_reboot.py` | ADB 重启修复 | 次要 |

## 故障排查

### 构建失败

1. **Python 版本问题**：确保默认 python 是 2.x
   ```bash
   python --version  # 应为 Python 2.7.x
   ```

2. **内存不足**：增加 swap 空间
   ```bash
   sudo fallocate -l 24G /swapfile
   sudo mkswap /swapfile
   sudo swapon /swapfile
   ```

3. **补丁失败**：检查 OrangeFox 源码版本，可能需要手动调整补丁

4. **BOARD_RECOVERY_IMAGE_PREPARE 失败**：确保 `prebuilt/vendor_ramdisk_stock.lz4` 和 `prebuilt/dtb.img` 存在且完整

### Recovery 运行问题

1. **黑屏/无显示**：确认 DRM 后端已正确安装（检查 vendorsetup.sh 输出）
2. **无法解密 data**：确认 keystore2 修复和 FBE 兼容性补丁已应用
3. **卡在 OrangeFox logo**：尝试 `OF_DEFAULT_KEYMASTER_VERSION` 调整为 `4.0` 或 `4.1`
4. **MTP 不工作**：确认 `unisoc_mtp_ffs_v1.patch` 已应用
5. **触摸不工作**：检查触摸屏内核模块是否在 `modules.load.recovery` 中

## 文件结构

```
device/zte/P720S20/
├── AndroidProducts.mk          # Lunch 配置
├── Android.mk                  # 子目录 makefile 入口
├── Android.bp                  # Soong namespace
├── twrp_P720S20.mk             # 主产品 makefile (TWRP/OrangeFox 通用)
├── fox_P720S20.mk              # OrangeFox 专用变量 (新增)
├── BoardConfig.mk              # 板级配置
├── device.mk                   # 设备产品配置
├── recovery.fstab              # Recovery fstab
├── vendorsetup.sh              # 构建准备脚本 (已适配 OrangeFox)
├── prebuilt/
│   ├── dtb.img                 # 从 stock vendor_boot 提取的 DTB
│   └── vendor_ramdisk_stock.lz4 # Stock vendor ramdisk
├── recovery/root/              # Recovery root 文件
│   ├── first_stage_ramdisk/    # 第一阶段 ramdisk fstab
│   ├── lib/modules/            # 内核模块
│   ├── system/                 # HAL 服务和库
│   └── vendor/                 # VINTF manifest, firmware
├── patches/                    # 源码补丁
├── tools/                      # 构建工具脚本
├── stock_reference/            # Stock fstab 参考
└── BRINGUP_NOTES.md            # 开发笔记
```
