#!/bin/bash

# GOST Socks5 一键安装脚本
# 功能：自动下载安装 GOST 并启动 Socks5 代理服务
# 作者：根据用户需求生成
# 注意事项：运行前请确保有 root 权限

clear
echo "================================================"
echo " GOST Socks5 代理服务一键安装脚本"
echo "================================================"

# 检查root权限
if [ "$(id -u)" != "0" ]; then
    echo "错误：此脚本需要 root 权限运行！" 1>&2
    echo "请尝试使用 sudo 执行：sudo bash $0"
    exit 1
fi

# 交互式输入配置
read -p "请输入Socks5用户名（默认随机生成）: " username
read -p "请输入Socks5密码（默认随机生成）: " password
read -p "请输入监听端口（默认61230）: " port

# 设置默认值
[ -z "$username" ] && username=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 8)
[ -z "$password" ] && password=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 16)
[ -z "$port" ] && port=61230

# 显示配置信息
echo -e "\n=============== 配置确认 ==============="
echo "用户名: $username"
echo "密码: $password"
echo "端口: $port"
echo "========================================="
read -p "确认安装？(y/n) " -n 1 -r
echo

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "安装已取消"
    exit 0
fi

# 安装流程
echo -e "\n>>> 开始安装 GOST Socks5 代理服务..."

# 下载 GOST
echo "步骤1: 下载 GOST 二进制文件..."
gost_url="https://github.com/ginuerzh/gost/releases/download/v2.12.0/gost_2.12.0_linux_amd64.tar.gz"
wget -q --show-progress "$gost_url" -O gost.tar.gz || {
    echo "下载失败，请检查网络连接！"
    exit 1
}

# 解压安装
echo "步骤2: 解压安装 GOST..."
tar -zxvf gost.tar.gz gost >/dev/null 2>&1 || {
    echo "解压失败，文件可能损坏！"
    exit 1
}

mv gost /usr/bin/gost
chmod +x /usr/bin/gost

# 创建系统服务
echo "步骤3: 创建系统服务..."
cat > /etc/systemd/system/gost.service <<EOF
[Unit]
Description=GOST Socks5 Proxy Service
After=network.target

[Service]
ExecStart=/usr/bin/gost -L $username:$password@:$port socks5://:$port
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

# 启动服务
systemctl daemon-reload
systemctl enable gost >/dev/null 2>&1
systemctl start gost

# 清理安装包
rm -f gost.tar.gz

# 检查服务状态
if systemctl is-active --quiet gost; then
    echo -e "\n✔ 安装成功！GOST 服务正在运行"
else
    echo -e "\n⚠ 服务启动失败，请手动检查！"
    systemctl status gost
    exit 1
fi

# 显示连接信息
local_ip=$(curl -s http://ifconfig.me)
echo -e "\n=============== 使用说明 ==============="
echo "Socks5代理地址: $local_ip:$port"
echo "用户名: $username"
echo "密码: $password"
echo "========================================="
echo -e "\n管理命令："
echo "启动服务: systemctl start gost"
echo "停止服务: systemctl stop gost"
echo "查看状态: systemctl status gost"
echo "查看日志: journalctl -u gost -f"
echo "========================================="