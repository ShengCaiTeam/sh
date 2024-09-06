#!/bin/bash

# 定义脚本版本
SCRIPT_VERSION="1.0.0" # echo -e "${BLUE}Script Version: $SCRIPT_VERSION${NC}"

# 定义颜色变量
NC='\033[0m'           # 无颜色（用于重置颜色）
RED='\033[0;31m'       # 红色
GREEN='\033[0;32m'     # 绿色
YELLOW='\033[1;33m'    # 黄色
BLUE='\033[0;34m'      # 蓝色
PURPLE='\033[0;35m'    # 紫色
CYAN='\033[0;36m'      # 青色
WHITE='\033[1;37m'     # 白色（亮白）

# 显示顶部标题
function display_header() {
    clear
    echo -e "${BLUE}========================================================================${NC}"
    echo -e "${GREEN}   _____ _                         _____      _ ${NC}"
    echo -e "${GREEN}  / ____| |                       / ____|    (_)${NC}"
    echo -e "${GREEN} | (___ | |__   ___ _ __   __ _  | |     __ _ _ ${NC}"
    echo -e "${GREEN}  \\___ \\| '_ \\ / _ \\ '_ \\ / _\` | | |    / _\` | |${NC}"
    echo -e "${GREEN}  ____) | | | |  __/ | | | (_| | | |___| (_| | |${NC}"
    echo -e "${GREEN} |_____/|_| |_|\\___|_| |_|\\__, |  \\_____\\__,_|_|${NC}"
    echo -e "${GREEN}                           __/ |                ${NC}"
    echo -e "${GREEN}                          |___/                 ${NC}"
    echo -e "${BLUE}========================================================================${NC}"
}

# 检查依赖的函数
function check_dependency() {
    command -v "$1" >/dev/null 2>&1 || {
        echo -e "${RED}$1 未安装。请安装后重试。${NC}"
        exit 1
    }
}

# 检查所有必要的依赖
function check_dependencies() {
    check_dependency "curl"
    check_dependency "awk"
    check_dependency "lsb_release"
}

# 系统清理函数
function system_cleanup() {
    display_header
    echo "正在清理系统..."
    sudo apt-get autoremove -y && sudo apt-get autoclean -y
    echo "系统清理完成！"
    read -rp "按任意键返回主菜单..." -n1
    show_menu
}

# 系统信息查询函数
function system_info() {
    display_header
    
    hostname=$(hostname)
    isp_info=$(curl -s https://ipinfo.io/org)
    os_info=$(lsb_release -d | awk -F "\t" '{print $2}')
    kernel_version=$(uname -r)
    cpu_arch=$(uname -m)
    cpu_info=$(lscpu | grep 'Model name' | awk -F ':' '{print $2}' | sed 's/^ *//g')
    cpu_cores=$(nproc)
    cpu_usage_percent=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    mem_info=$(free -h | grep 'Mem:' | awk '{print $2}')
    swap_info=$(free -h | grep 'Swap:' | awk '{print $2}')
    disk_info=$(df -h --total | grep 'total' | awk '{print $3 " / " $2 " (" $5 ")"}')
    congestion_algorithm=$(sysctl net.ipv4.tcp_congestion_control | awk -F "=" '{print $2}' | sed 's/^ *//g')
    queue_algorithm=$(tc -s qdisc show | grep "qdisc fq_codel" | awk '{print $2}')
    ipv4_address=$(curl -s https://ipinfo.io/ip)
    ipv6_address=$(curl -s https://ifconfig.co/ip)
    country=$(curl -s https://ipinfo.io/country)
    city=$(curl -s https://ipinfo.io/city)
    timezone=$(timedatectl | grep "Time zone" | awk '{print $3}')
    current_time=$(date '+%Y-%m-%d %H:%M:%S')
    runtime=$(uptime -p)

    echo ""
    echo -e "${BLUE}系统信息查询${NC}"
    echo -e "${CYAN}------------------------${NC}"
    echo -e "${CYAN}主机名: ${WHITE}$hostname${NC}"
    echo -e "${CYAN}运营商: ${WHITE}$isp_info${NC}"
    echo -e "${CYAN}------------------------${NC}"
    echo -e "${CYAN}系统版本: ${WHITE}$os_info${NC}"
    echo -e "${CYAN}Linux版本: ${WHITE}$kernel_version${NC}"
    echo -e "${CYAN}------------------------${NC}"
    echo -e "${CYAN}CPU架构: ${WHITE}$cpu_arch${NC}"
    echo -e "${CYAN}CPU型号: ${WHITE}$cpu_info${NC}"
    echo -e "${CYAN}CPU核心数: ${WHITE}$cpu_cores${NC}"
    echo -e "${CYAN}------------------------${NC}"
    echo -e "${CYAN}CPU占用: ${WHITE}$cpu_usage_percent%${NC}"
    echo -e "${CYAN}物理内存: ${WHITE}$mem_info${NC}"
    echo -e "${CYAN}虚拟内存: ${WHITE}$swap_info${NC}"
    echo -e "${CYAN}硬盘占用: ${WHITE}$disk_info${NC}"
    echo -e "${CYAN}------------------------${NC}"
    echo -e "${CYAN}网络拥堵算法: ${WHITE}$congestion_algorithm $queue_algorithm${NC}"
    echo -e "${CYAN}------------------------${NC}"
    echo -e "${CYAN}公网IPv4地址: ${WHITE}$ipv4_address${NC}"
    echo -e "${CYAN}公网IPv6地址: ${WHITE}$ipv6_address${NC}"
    echo -e "${CYAN}------------------------${NC}"
    echo -e "${CYAN}地理位置: ${WHITE}$country $city${NC}"
    echo -e "${CYAN}系统时区: ${WHITE}$timezone${NC}"
    echo -e "${CYAN}系统时间: ${WHITE}$current_time${NC}"
    echo -e "${CYAN}------------------------${NC}"
    echo -e "${CYAN}系统运行时长: ${WHITE}$runtime${NC}"
    echo ""

    read -rp "按任意键返回主菜单..." -n1
    show_menu
}

# 系统更新函数
function system_update() {
    display_header
    echo "正在更新系统..."
    sudo apt-get update && sudo apt-get upgrade -y
    echo "系统更新完成！"
    read -rp "按任意键返回主菜单..." -n1
    show_menu
}

# 安装函数，用于检查并安装传入的软件包
function install() {
    if [ $# -eq 0 ]; then
        echo -e "${RED}未提供软件包参数!${NC}"  
        return 1  
    fi

    for package in "$@"; do
        if ! command -v "$package" &>/dev/null; then
            if command -v dnf &>/dev/null; then
                echo -e "${BLUE}使用 dnf 安装 $package${NC}"
                dnf -y update && dnf install -y "$package"
            elif command -v yum &>/dev/null; then
                echo -e "${BLUE}使用 yum 安装 $package${NC}"
                yum -y update && yum -y install "$package"
            elif command -v apt &>/dev/null; then
                echo -e "${BLUE}使用 apt 安装 $package${NC}"
                apt update -y && apt install -y "$package"
            elif command -v apk &>/dev/null; then
                echo -e "${BLUE}使用 apk 安装 $package${NC}"
                apk update && apk add "$package"
            else
                echo -e "${RED}未知的包管理器!${NC}"
                return 1
            fi
        else
            echo -e "${GREEN}$package 已经安装${NC}"
        fi
    done

    return 0
}

# 显示主菜单
function show_menu() {
    display_header
    echo "------------------------"
    echo -e "${YELLOW}Sheng Cai 一键脚本工具${NC}"
    echo "------------------------"
    echo "请选择一个系统管理任务："
    echo -e "1) ${YELLOW}系统信息查询${NC}"
    echo -e "2) ${YELLOW}系统更新${NC}"
    echo -e "3) ${YELLOW}系统清理${NC}"
    echo -e "0) ${RED}退出${NC}"
    read -rp "输入选项 [1-3]: " choice
    case $choice in
        1) system_info ;;
        2) system_update ;;
        3) system_cleanup ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效的选项，请重新选择。${NC}" && sleep 2 && show_menu ;;
    esac
}

# 运行前检测依赖
check_dependencies

# 启动主菜单
show_menu
