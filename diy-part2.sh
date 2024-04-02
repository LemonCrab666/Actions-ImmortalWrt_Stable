#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# 更改默认IP
#sed -i 's/192.168.1.1/192.168.50.5/g' package/base-files/files/bin/config_generate

#添加软件包
#rm -rf feeds/luci/applications/luci-app-openclash
#git clone -b master --single-branch --filter=blob:none https://github.com/vernesong/OpenClash.git feeds/luci/applications/luci-app-openclash
git clone https://github.com/rufengsuixing/luci-app-adguardhome package/luci-app-adguardhome

#!/bin/bash

# 生成vermagic文件
echo "317eb6a6d9828371f8f0ca9cfaff251a" > vermagic

# 修改include/kernel-defaults.mk文件
sed -i '/grep '=[ym]' $(LINUX_DIR)\/.config.set | LC_ALL=C sort | $(MKHASH) md5 > $(LINUX_DIR)\/.vermagic/s/^/#/' /workdir/openwrt/include/kernel-defaults.mk
sed -i '/grep '=[ym]' $(LINUX_DIR)\/.config.set | LC_ALL=C sort | $(MKHASH) md5 > $(LINUX_DIR)\/.vermagic/a\cp $(TOPDIR)\/vermagic $(LINUX_DIR)\/.vermagic' /workdir/openwrt/include/kernel-defaults.mk

# 修改package/kernel/linux/Makefile文件
sed -i 's/STAMP_BUILT:=$(STAMP_BUILT)_$(shell $(SCRIPT_DIR)\/kconfig.pl $(LINUX_DIR)\/.config | $(MKHASH) md5)/# &/' /workdir/openwrt/package/kernel/linux/Makefile
sed -i '/STAMP_BUILT:=$(STAMP_BUILT)_$(shell $(SCRIPT_DIR)\/kconfig.pl $(LINUX_DIR)\/.config | $(MKHASH) md5)/a\STAMP_BUILT:=$(STAMP_BUILT)_$(shell cat $(LINUX_DIR)\/.vermagic)' /workdir/openwrt/package/kernel/linux/Makefile
