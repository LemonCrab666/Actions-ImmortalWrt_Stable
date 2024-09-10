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
rm -rf feeds/luci/applications/luci-app-openclash
git clone -b master --single-branch --filter=blob:none https://github.com/vernesong/OpenClash.git feeds/luci/applications/luci-app-openclash
git clone https://github.com/rufengsuixing/luci-app-adguardhome package/luci-app-adguardhome
git clone -b main --single-branch --filter=blob:none https://github.com/morytyann/OpenWrt-mihomo
mv OpenWrt-mihomo/luci-app-mihomo package/
mv OpenWrt-mihomo/mihomo package/

#将nlbwmon从服务目录移动到菜单栏
#sed -i -e '/"path": "admin\/services\/nlbw\/display"/d' -e 's/services\///g' -e 's/"type": "alias"/"type": "firstchild"/' package/feeds/luci/luci-app-nlbwmon/root/usr/share/luci/menu.d/luci-app-nlbwmon.json
#sed -i 's|admin/services/nlbw/backup|admin/nlbw/backup|g' package/feeds/luci/luci-app-nlbwmon/htdocs/luci-static/resources/view/nlbw/config.js

#由于内核参数 net.core.rmem_max 的限制，缓冲区大小被限制为 212992 字节，永久设置 Netlink 接收缓冲区大小为 524288 字节。
#mkdir -p files/etc
#echo "# Defaults are configured in /etc/sysctl.d/* and can be customized in this file" > files/etc/sysctl.conf
#echo "net.core.rmem_max=524288" >> files/etc/sysctl.conf

#修改sysguarde备份列表
mkdir -p files/etc

cat <<EOF > files/etc/sysupgrade.conf
## This file contains files and directories that should
## be preserved during an upgrade.

# /etc/example.conf
# /etc/openvpn/
/etc/AdGuardHome.yaml
/usr/bin/AdGuardHome/
/www/luci-static/argon/background/
/usr/share/wechatpush/api/OpenWrt.jpg
/root/backup_openwrt.sh
/root/sshpass
EOF

chmod 0644 files/etc/sysupgrade.conf

#将clash内核、TUN内核、Meta内核编译进目录
mkdir -p files/etc/openclash/core
curl -L https://raw.githubusercontent.com/vernesong/OpenClash/core/master/dev/clash-linux-amd64.tar.gz | tar -xz -C /tmp
mv /tmp/clash files/etc/openclash/core/clash
chmod 0755 files/etc/openclash/core/clash
curl -L https://raw.githubusercontent.com/vernesong/OpenClash/core/master/premium/clash-linux-amd64-2023.08.17-13-gdcc8d87.gz | gunzip -c > /tmp/clash_tun
mv /tmp/clash_tun files/etc/openclash/core/clash_tun
chmod 0755 files/etc/openclash/core/clash_tun
curl -L https://raw.githubusercontent.com/vernesong/OpenClash/core/master/meta/clash-linux-amd64.tar.gz | tar -xz -C /tmp
mv /tmp/clash files/etc/openclash/core/clash_meta
chmod 0755 files/etc/openclash/core/clash_meta

#将AdGuardHome核心文件编译进目录
curl -s https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest \
| grep "browser_download_url.*AdGuardHome_linux_amd64.tar.gz" \
| cut -d : -f 2,3 \
| tr -d \" \
| xargs curl -L -o /tmp/AdGuardHome_linux_amd64.tar.gz && \
tar -xzvf /tmp/AdGuardHome_linux_amd64.tar.gz -C /tmp/ --strip-components=1 && \
mkdir -p files/usr/bin/AdGuardHome && \
mv /tmp/AdGuardHome/AdGuardHome files/usr/bin/AdGuardHome/
chmod 0755 files/usr/bin/AdGuardHome/AdGuardHome

# 修改固件MD5值
# 生成VerMagic文件
echo "c5f84ade92103ce978361a1c59890df1" > vermagic
# 检查VerMagic文件是否生成成功
if [ ! -f "vermagic" ]; then
    echo "VerMagic文件生成失败！"
    exit 1
fi

# 修改include/kernel-defaults.mk
# 设置变量
pattern="grep '=[ym]' \$(LINUX_DIR)/.config.set | LC_ALL=C sort | \$(MKHASH) md5 > \$(LINUX_DIR)/.vermagic"
replacement="cp \$(TOPDIR)/vermagic \$(LINUX_DIR)/.vermagic"
# 对pattern中的特殊字符进行转义处理
escaped_pattern=$(printf '%s\n' "$pattern" | sed -e 's/[][\/$*.^|[]/\\&/g')
# 使用sed命令替换整段语句
sed -i "s|$escaped_pattern|$replacement|g" include/kernel-defaults.mk
# 检查替换是否成功
if [ $? -ne 0 ]; then
    echo "include/kernel-defaults.mk 替换失败！"
    exit 1
fi

# 修改package/kernel/linux/Makefile
sed -i 's/STAMP_BUILT:=$(STAMP_BUILT)_$(shell $(SCRIPT_DIR)\/kconfig.pl $(LINUX_DIR)\/.config | $(MKHASH) md5)/STAMP_BUILT:=$(STAMP_BUILT)_$(shell cat $(LINUX_DIR)\/.vermagic)/g' package/kernel/linux/Makefile
# 检查替换是否成功
if [ $? -ne 0 ]; then
    echo "package/kernel/linux/Makefile 替换失败！"
    exit 1
fi

# 输出成功信息
echo "替换成功！"
