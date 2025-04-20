#!/bin/bash

# 设置颜色输出
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查命令执行状态
check_status() {
    if [ $? -eq 0 ]; then
        log_info "$1 成功"
        return 0
    else
        log_error "$1 失败"
        return 1
    fi
}

# 检查是否为 root 用户
if [ "$EUID" -ne 0 ]; then
    log_error "请使用 sudo 运行此脚本"
    exit 1
fi

# 检查并安装必要的包
log_info "检查并安装必要的软件包..."
dnf install -y fwupd gnome-firmware > /dev/null 2>&1
check_status "安装必要软件包" || exit 1

# 确保 fwupd 服务运行
log_info "启动 fwupd 服务..."
systemctl start fwupd
sleep 2  # 等待服务完全启动
check_status "启动 fwupd 服务" || exit 1

# 刷新固件列表
log_info "刷新固件列表..."
yes | fwupdmgr refresh
sleep 3  # 等待刷新完成
check_status "刷新固件列表" || exit 1

# 检查可用更新
log_info "检查可用的固件更新..."
UPGRADES=$(fwupdmgr get-upgrades 2>/dev/null)
if [ -z "$UPGRADES" ]; then
    log_info "没有可用的固件更新"
    exit 0
else
    log_info "发现可用更新："
    echo "$UPGRADES"
fi

# 询问用户是否继续
read -p "是否继续更新固件？(y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "用户取消更新"
    exit 0
fi

# 执行更新
log_info "开始更新固件..."
yes | fwupdmgr update
UPDATE_STATUS=$?

if [ $UPDATE_STATUS -eq 0 ]; then
    log_info "固件更新成功完成"
    
    # 检查是否需要重启
    if [ -f "/var/run/reboot-required" ]; then
        log_warn "系统需要重启以完成更新"
        read -p "是否现在重启？(y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "系统将在 10 秒后重启..."
            sleep 10
            reboot
        else
            log_warn "请记得稍后重启系统以完成更新"
        fi
    fi
else
    log_error "固件更新过程中出现错误"
    
    # 清理缓存
    log_info "清理更新缓存..."
    fwupdmgr clear-history
    fwupdmgr clear-offline
    
    exit 1
fi

# 显示更新历史
log_info "更新历史："
fwupdmgr get-history

exit 0
