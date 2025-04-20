#!/bin/bash
#
# Fedora 存储设备健康检查脚本 (改进版)
# 支持SATA、SAS和NVMe设备健康检查
#

# 定义颜色
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # 无颜色

# 检查是否以root运行
if [ "$(id -u)" -ne 0 ]; then
    echo -e "${RED}错误: 此脚本需要root权限运行${NC}"
    echo "请使用 sudo ./disk_health_check.sh 重新运行"
    exit 1
fi

# 检查依赖软件
check_dependency() {
    if ! command -v $1 &>/dev/null; then
        echo -e "${YELLOW}未检测到$1，正在安装...${NC}"
        dnf install -y $2
    fi
}

check_dependency smartctl smartmontools
check_dependency nvme nvme-cli

# 分析SATA/SAS设备
analyze_sata_device() {
    local device=$1

    echo -e "\n${BLUE}============================================${NC}"
    echo -e "${BLUE}分析设备: /dev/${device}${NC}"
    echo -e "${BLUE}============================================${NC}"

    # 获取设备信息
    echo -e "${YELLOW}设备信息:${NC}"
    smartctl -i /dev/${device} | grep -E 'Model|Capacity|SMART support is'

    # 检查设备是否支持SMART
    if ! smartctl -i /dev/${device} | grep -q "SMART support is: Enabled"; then
        if smartctl -i /dev/${device} | grep -q "SMART support is: Available"; then
            echo -e "${YELLOW}警告: 该设备支持SMART但未启用，尝试启用...${NC}"
            smartctl -s on /dev/${device}
        else
            echo -e "${YELLOW}警告: 该设备不支持SMART${NC}"
            return
        fi
    fi

    # 获取健康状态
    echo -e "\n${YELLOW}整体健康状态:${NC}"
    health=$(smartctl -H /dev/${device} | grep -E "SMART overall-health|test result")
    if echo "$health" | grep -q "PASSED"; then
        echo -e "${GREEN}$health${NC}"
    else
        echo -e "${RED}$health${NC}"
    fi

    # 获取关键属性
    echo -e "\n${YELLOW}关键健康指标:${NC}"

    # 检查是否为SSD
    is_ssd=false
    if smartctl -a /dev/${device} | grep -q -i "Solid State Device"; then
        is_ssd=true
        echo -e "${BLUE}设备类型: SSD${NC}"
    else
        echo -e "${BLUE}设备类型: HDD${NC}"
    fi

    # 检查重分配扇区计数
    reallocated=$(smartctl -a /dev/${device} | grep -E "Reallocated_Sector_Ct")
    if [ -n "$reallocated" ]; then
        raw_value=$(echo "$reallocated" | awk '{print $NF}')
        if [ "$raw_value" -eq 0 ]; then
            echo -e "${GREEN}重分配扇区计数: $raw_value (良好)${NC}"
        elif [ "$raw_value" -lt 10 ]; then
            echo -e "${YELLOW}重分配扇区计数: $raw_value (警告)${NC}"
        else
            echo -e "${RED}重分配扇区计数: $raw_value (危险)${NC}"
        fi
    fi

    # 检查通电时间 (修复语法错误)
    power_on=$(smartctl -a /dev/${device} | grep -E "Power_On_Hours")
    if [ -n "$power_on" ]; then
        # 提取最后一列的数值
        hours=$(echo "$power_on" | awk '{print $NF}')
        # 确保hours是数字
        if [[ "$hours" =~ ^[0-9]+$ ]]; then
            days=$(awk "BEGIN {printf \"%.1f\", $hours/24}")
            echo -e "${BLUE}通电时间: $hours 小时 (约 $days 天)${NC}"
        else
            echo -e "${BLUE}通电时间: 未知${NC}"
        fi
    fi

    # 检查温度
    temp=$(smartctl -a /dev/${device} | grep -E "Temperature_Celsius" | awk '{print $10}')
    if [ -n "$temp" ]; then
        if [ "$temp" -lt 40 ]; then
            echo -e "${GREEN}温度: ${temp}°C (正常)${NC}"
        elif [ "$temp" -lt 50 ]; then
            echo -e "${YELLOW}温度: ${temp}°C (偏高)${NC}"
        else
            echo -e "${RED}温度: ${temp}°C (过高)${NC}"
        fi
    fi

    # 显示最近的SMART错误
    echo -e "\n${YELLOW}SMART错误日志:${NC}"
    errors=$(smartctl -l error /dev/${device} | grep -A 2 "SMART Error Log")
    if echo "$errors" | grep -q "No Errors Logged"; then
        echo -e "${GREEN}无错误记录${NC}"
    else
        echo -e "${RED}检测到错误:${NC}"
        smartctl -l error /dev/${device} | grep -A 10 "SMART Error Log"
    fi

    # 检查自检状态
    echo -e "\n${YELLOW}自检状态:${NC}"
    selftest_status=$(smartctl -l selftest /dev/${device} | grep -A 1 "SMART Self-test log")

    if echo "$selftest_status" | grep -q "No self-tests have been logged"; then
        echo -e "${BLUE}无自检记录${NC}"
        offer_selftest=true
    elif smartctl -c /dev/${device} | grep -q "Self-test routine in progress"; then
        progress=$(smartctl -c /dev/${device} | grep "Self-test routine in progress" | grep -oP "\d+%")
        echo -e "${YELLOW}自检正在进行中，完成度: $progress${NC}"
        offer_selftest=false
    else
        echo -e "${BLUE}最近一次自检结果:${NC}"
        smartctl -l selftest /dev/${device} | grep -A 5 "SMART Self-test log" | tail -n 5
        offer_selftest=true
    fi

    # 执行快速自检
    if [ "$offer_selftest" = true ]; then
        echo -e "\n${YELLOW}是否执行快速自检? (y/n)${NC}"
        read -r answer
        if [[ $answer =~ ^[Yy]$ ]]; then
            echo -e "${BLUE}正在执行快速自检...${NC}"
            smartctl -t short /dev/${device}
            wait_time=2 # 快速测试通常需要2分钟
            echo "测试需要大约 $wait_time 分钟完成"
            echo "你可以稍后运行以下命令查看结果:"
            echo -e "${BLUE}sudo smartctl -l selftest /dev/${device}${NC}"
        fi
    else
        echo -e "\n${YELLOW}已有自检正在进行中，跳过新自检${NC}"
    fi
}

# 分析NVMe设备
analyze_nvme_device() {
    local device=$1

    echo -e "\n${BLUE}============================================${NC}"
    echo -e "${BLUE}分析NVMe设备: /dev/${device}${NC}"
    echo -e "${BLUE}============================================${NC}"

    # 获取设备信息
    echo -e "${YELLOW}设备信息:${NC}"
    nvme list | grep -E "/dev/${device}"
    nvme id-ctrl /dev/${device} | grep -E "mn|fr|sn" | sed 's/^[ \t]*//'

    # 获取智能日志
    echo -e "\n${YELLOW}NVMe智能日志:${NC}"
    smartlog=$(nvme smart-log /dev/${device})

    # 提取关键健康指标
    critical_warning=$(echo "$smartlog" | grep "critical_warning" | awk '{print $3}')
    media_errors=$(echo "$smartlog" | grep "media_errors" | awk '{print $3}')
    temperature=$(echo "$smartlog" | grep "temperature" | head -1 | awk '{print $3}')
    available_spare=$(echo "$smartlog" | grep "available_spare" | awk '{print $3}')
    percentage_used=$(echo "$smartlog" | grep "percentage_used" | awk '{print $3}')
    data_units_read=$(echo "$smartlog" | grep "data_units_read" | awk '{print $3}')
    data_units_written=$(echo "$smartlog" | grep "data_units_written" | awk '{print $3}')
    host_read_commands=$(echo "$smartlog" | grep "host_read_commands" | awk '{print $3}')
    host_write_commands=$(echo "$smartlog" | grep "host_write_commands" | awk '{print $3}')
    power_cycles=$(echo "$smartlog" | grep "power_cycles" | awk '{print $3}')
    power_on_hours=$(echo "$smartlog" | grep "power_on_hours" | awk '{print $3}')

    # 显示健康状态
    echo -e "\n${YELLOW}整体健康状态:${NC}"
    if [ "$critical_warning" -eq 0 ]; then
        echo -e "${GREEN}健康状态正常 (无关键警告)${NC}"
    else
        echo -e "${RED}警告: 设备存在问题，关键警告值: $critical_warning${NC}"
    fi

    # 修复NVMe温度计算
    temperature=$(echo "$smartlog" | grep "temperature" | head -1 | awk '{print $3}')
    if [ -n "$temperature" ]; then
        # 如果温度是开尔文，需要减去273.15转换为摄氏度
        # 但有些NVMe设备直接报告摄氏度，所以需要判断
        if [ "$temperature" -gt 200 ]; then
            celsius=$(awk "BEGIN {printf \"%.1f\", ($temperature - 273.15)}")
        else
            celsius=$temperature
        fi

        if (($(echo "$celsius < 50" | bc -l))); then
            echo -e "${GREEN}温度: ${celsius}°C (正常)${NC}"
        elif (($(echo "$celsius < 70" | bc -l))); then
            echo -e "${YELLOW}温度: ${celsius}°C (偏高)${NC}"
        else
            echo -e "${RED}温度: ${celsius}°C (过高)${NC}"
        fi
    fi

    # 显示介质错误
    if [ "$media_errors" -eq 0 ]; then
        echo -e "${GREEN}介质错误: $media_errors (无错误)${NC}"
    else
        echo -e "${RED}介质错误: $media_errors (检测到错误)${NC}"
    fi

    # 修复可用备用空间和SSD寿命计算
    available_spare=$(echo "$smartlog" | grep "available_spare" | awk '{print $3}' | tr -d '%')
    if [ -n "$available_spare" ]; then
        if [ "$available_spare" -gt 10 ]; then
            echo -e "${GREEN}可用备用空间: ${available_spare}% (正常)${NC}"
        else
            echo -e "${RED}可用备用空间: ${available_spare}% (不足)${NC}"
        fi
    fi

    # 显示已使用寿命百分比
    percentage_used=$(echo "$smartlog" | grep "percentage_used" | awk '{print $3}' | tr -d '%')
    if [ -n "$percentage_used" ]; then
        remaining_life=$((100 - percentage_used))
        if [ "$percentage_used" -lt 80 ]; then
            echo -e "${GREEN}SSD剩余寿命: 约${remaining_life}%${NC}"
        elif [ "$percentage_used" -lt 95 ]; then
            echo -e "${YELLOW}SSD剩余寿命: 约${remaining_life}%${NC}"
        else
            echo -e "${RED}SSD剩余寿命: 约${remaining_life}% (考虑更换)${NC}"
        fi
    fi

    # 显示数据读写总量
    read_tb=$(awk "BEGIN {printf \"%.2f\", $data_units_read * 512000 / 1000 / 1000 / 1000 / 1000}")
    written_tb=$(awk "BEGIN {printf \"%.2f\", $data_units_written * 512000 / 1000 / 1000 / 1000 / 1000}")
    echo -e "${BLUE}已读取数据总量: ${read_tb} TB${NC}"
    echo -e "${BLUE}已写入数据总量: ${written_tb} TB${NC}"

    # 显示通电时间和启动次数
    days=$(awk "BEGIN {printf \"%.1f\", $power_on_hours/24}")
    echo -e "${BLUE}通电时间: $power_on_hours 小时 (约 $days 天)${NC}"
    echo -e "${BLUE}开机次数: $power_cycles 次${NC}"

    # 检查TRIM支持
    echo -e "\n${YELLOW}TRIM检查:${NC}"
    fs_type=$(df -T /dev/${device}* 2>/dev/null | grep -v "Filesystem" | awk '{print $2}' | head -1)
    if [ -n "$fs_type" ]; then
        echo -e "${BLUE}文件系统类型: $fs_type${NC}"
        if [[ "$fs_type" =~ ^(ext4|xfs|btrfs|f2fs)$ ]]; then
            echo -e "${GREEN}文件系统支持TRIM${NC}"
        else
            echo -e "${YELLOW}文件系统可能不支持TRIM${NC}"
        fi
    fi

    if systemctl is-enabled fstrim.timer &>/dev/null; then
        echo -e "${GREEN}fstrim.timer服务已启用${NC}"
    else
        echo -e "${YELLOW}fstrim.timer服务未启用, 建议启用:${NC}"
        echo -e "  sudo systemctl enable --now fstrim.timer"
    fi

    # 自检选项
    echo -e "\n${YELLOW}是否执行NVMe自检? (y/n)${NC}"
    read -r answer
    if [[ $answer =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}正在执行NVMe自检...${NC}"
        nvme device-self-test -s 1 /dev/${device}
        echo "测试已开始，你可以稍后运行以下命令查看结果:"
        echo -e "${BLUE}sudo nvme device-self-test-log /dev/${device}${NC}"
    fi
}

# 主程序开始

# 获取所有SATA设备
echo -e "${BLUE}正在检测系统中的存储设备...${NC}"
SATA_DEVICES=($(lsblk -d -o NAME,TYPE | grep disk | grep -v nvme | awk '{print $1}'))
NVME_DEVICES=($(lsblk -d -o NAME,TYPE | grep disk | grep nvme | awk '{print $1}'))

total_devices=$((${#SATA_DEVICES[@]} + ${#NVME_DEVICES[@]}))
echo -e "${GREEN}检测到 $total_devices 个存储设备${NC}"

# 分析SATA设备
for device in "${SATA_DEVICES[@]}"; do
    # 跳过虚拟设备
    if [[ $device == loop* || $device == ram* || $device == zram* ]]; then
        continue
    fi
    analyze_sata_device $device
done

# 分析NVMe设备
for device in "${NVME_DEVICES[@]}"; do
    analyze_nvme_device $device
done

echo -e "\n${GREEN}存储设备健康检查完成!${NC}"
echo -e "${YELLOW}建议:${NC}"
echo "1. 对于健康状况不佳的设备，考虑备份数据并更换"
echo "2. 定期运行此脚本监控存储设备健康状况"
echo "3. 对于SSD，确保启用TRIM功能以延长使用寿命"
echo "4. 温度过高的设备，考虑改善散热条件"

# 提供一个总体评估
echo -e "\n${BLUE}系统存储设备总体评估:${NC}"
failed_sata=0
for device in "${SATA_DEVICES[@]}"; do
    if [[ $device == loop* || $device == ram* || $device == zram* ]]; then
        continue
    fi
    health=$(smartctl -H /dev/${device} 2>/dev/null | grep -E "SMART overall-health|test result")
    if ! echo "$health" | grep -q "PASSED"; then
        failed_sata=$((failed_sata + 1))
    fi
done

failed_nvme=0
for device in "${NVME_DEVICES[@]}"; do
    crit_warn=$(nvme smart-log /dev/${device} 2>/dev/null | grep "critical_warning" | awk '{print $3}')
    if [ -n "$crit_warn" ] && [ "$crit_warn" -ne 0 ]; then
        failed_nvme=$((failed_nvme + 1))
    fi
done

failed_devices=$((failed_sata + failed_nvme))
if [ "$failed_devices" -eq 0 ]; then
    echo -e "${GREEN}所有存储设备健康状况良好${NC}"
else
    echo -e "${RED}有 $failed_devices 个设备健康状况异常，请注意检查${NC}"
fi
