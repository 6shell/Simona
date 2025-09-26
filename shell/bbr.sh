#!/bin/bash

echo "🔍 正在检测当前 TCP 拥塞控制算法..."
current_algo=$(sysctl -n net.ipv4.tcp_congestion_control)

if [ "$current_algo" == "bbr" ]; then
    echo "✅ 当前已启用 BBR，无需修改。"
    exit 0
fi

echo "⚠️ 当前使用的是 $current_algo，准备切换为 BBR..."

# 检查内核版本
kernel_version=$(uname -r | cut -d. -f1)
if [ "$kernel_version" -lt 4 ]; then
    echo "❌ 当前内核版本过低（$kernel_version），BBR 需要 4.9+，请先升级内核。"
    exit 1
fi

# 加载 BBR 模块
modprobe tcp_bbr 2>/dev/null

# 检查是否支持 BBR
if lsmod | grep -q bbr; then
    echo "✅ BBR 模块已加载，开始配置..."

    # 设置临时参数
    sysctl -w net.core.default_qdisc=fq
    sysctl -w net.ipv4.tcp_congestion_control=bbr

    # 写入永久配置
    if [ -f /etc/sysctl.conf ]; then
        sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf
        sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf
        echo "net.core.default_qdisc = fq" >> /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
    fi

    sysctl -p
    echo "🎉 BBR 已成功启用！当前算法为：$(sysctl -n net.ipv4.tcp_congestion_control)"
else
    echo "❌ 当前系统未加载 BBR 模块，可能不支持。请确认内核版本 ≥ 4.9 且已启用模块。"
fi
