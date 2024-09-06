#!/bin/bash

# 定义脚本版本
SCRIPT_VERSION="1.0.0"

# 定义颜色变量
NC='\033[0m'           # 无颜色（用于重置颜色）
RED='\033[0;31m'       # 红色
GREEN='\033[0;32m'     # 绿色
YELLOW='\033[1;33m'    # 黄色
BLUE='\033[0;34m'      # 蓝色
PURPLE='\033[0;35m'    # 紫色
CYAN='\033[0;36m'      # 青色
WHITE='\033[1;37m'     # 白色（亮白）

# 复制文件到 /usr/local/bin 并重命名为 scsh，忽略输出
cp ./shengcai.sh /usr/local/bin/scsh > /dev/null 2>&1

# 检查依赖函数
function check_dependency() {
    command -v "$1" >/dev/null 2>&1 || {
        echo -e "${RED}$1 未安装。请安装后重试。${NC}"
        exit 1
    }
}

# 定义函数，用于检查所有必要的依赖
function check_dependencies() {
    check_dependency "curl"         # 检查 curl 是否安装
    check_dependency "awk"          # 检查 awk 是否安装
    check_dependency "lsb_release"  # 检查 lsb_release 是否安装
    check_dependency "docker"       # 检查 docker 是否安装
    check_dependency "iptables"     # 检查 iptables 是否安装
    check_dependency "ss"            # 检查 ss 命令是否安装
}

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

# 定义安装依赖的函数，安装 wget、socat、unzip 和 tar 软件包
function install_dependency() {
    clear
    install wget socat unzip tar
}

# 定义卸载函数，用于卸载传入的软件包
function remove() {
    if [ $# -eq 0 ]; then
        echo -e "${RED}未提供软件包参数!${NC}"  
        return 1  
    fi

    for package in "$@"; do
        if command -v dnf &>/dev/null; then
            dnf remove -y "${package}*"
        elif command -v yum &>/dev/null; then
            yum remove -y "${package}*"
        elif command -v apt &>/dev/null; then
            apt purge -y "${package}*"
        elif command -v apk &>/dev/null; then
            apk del "${package}*"
        else
            echo -e "${RED}未知的包管理器!${NC}"
            return 1
        fi
    done
    return 0
}

# 操作结束提示函数
function break_end() {
    echo -e "${GREEN}操作完成${NC}"
    echo "按任意键继续..."
    read -n 1 -s -r -p ""
    echo ""
    clear
}

# 检查指定端口是否被占用，判断是否由 Nginx Docker 容器占用
function check_port() {
    PORT=443
    result=$(ss -tulpn | grep ":$PORT")

    if [ -n "$result" ]; then
        is_nginx_container=$(docker ps --format '{{.Names}}' | grep 'nginx')
        if [ -n "$is_nginx_container" ]; then
            echo ""
        else
            clear
            echo -e "${RED}端口 ${YELLOW}$PORT${RED} 已被占用，无法安装环境，卸载以下程序后重试！${NC}"
            echo "$result"
            break_end
        fi
    else
        echo ""
    fi
}

# 安装并启动 Docker 和 Docker Compose
function install_add_docker() {
    if [ -f "/etc/alpine-release" ]; then
        apk update
        apk add docker docker-compose
        rc-update add docker default
        service docker start
    else
        curl -fsSL https://get.docker.com | sh
        systemctl start docker
        systemctl enable docker
    fi
    sleep 2
}

# 检查并安装 Docker 环境
function install_docker() {
    if ! command -v docker &>/dev/null; then
        install_add_docker
    else
        echo -e "${GREEN}Docker 环境已经安装${NC}"
    fi
}

# 重启 Docker 服务
function docker_restart() {
    if [ -f "/etc/alpine-release" ]; then
        service docker restart
    else
        systemctl restart docker
    fi
}

# Docker 应用管理函数
function docker_app() {
    # 检查系统的 IPv4 和 IPv6 地址
    has_ipv4_has_ipv6

    # 定义 Docker 应用相关变量
    # 请根据实际情况修改以下变量
    docker_name="your_docker_container_name"       # Docker 容器名称
    docker_img="your_docker_image_name"            # Docker 镜像名称
    docker_run="docker run -d --name your_docker_container_name your_docker_image_name"  # 运行 Docker 容器的命令
    docker_port="8080"                              # 应用访问端口
    docker_describe="这是一个示例 Docker 应用。"        # 应用描述
    docker_url="https://example.com"                # 应用相关网址
    docker_use="echo -e '${GREEN}应用已启动，可正常使用。${NC}'"      # 启动后执行的命令
    docker_passwd="echo -e '${GREEN}默认密码已设置。${NC}'"          # 启动后执行的命令

    # 检查 Docker 容器是否存在
    if docker inspect "$docker_name" &>/dev/null; then
        clear
        echo -e "${GREEN}$docker_name 已安装，访问地址:${NC}"
        if $has_ipv4; then
            echo -e "HTTP 地址: http://$ipv4_address:$docker_port"
        fi
        if $has_ipv6; then
            echo -e "HTTP 地址: http://[$ipv6_address]:$docker_port"
        fi
        echo ""
        echo "应用操作"
        echo "------------------------"
        echo "1. 更新应用             2. 卸载应用"
        echo "------------------------"
        echo "0. 返回上一级选单"
        echo "------------------------"
        read -p "请输入你的选择: " sub_choice

        case $sub_choice in
            1)
                clear
                echo "正在更新应用..."
                docker rm -f "$docker_name"
                docker rmi -f "$docker_img"
                $docker_run
                clear
                echo -e "${GREEN}$docker_name 已经安装完成${NC}"
                echo "------------------------"
                if $has_ipv4; then
                    echo -e "HTTP 地址: http://$ipv4_address:$docker_port"
                fi
                if $has_ipv6; then
                    echo -e "HTTP 地址: http://[$ipv6_address]:$docker_port"
                fi
                echo ""
                $docker_use
                $docker_passwd
                ;;
            2)
                clear
                echo "正在卸载应用..."
                docker rm -f "$docker_name"
                docker rmi -f "$docker_img"
                rm -rf "/home/docker/$docker_name"
                echo -e "${GREEN}应用已卸载${NC}"
                ;;
            0)
                show_menu ;;
            *)
                echo -e "${RED}无效的选项，请重新选择。${NC}"
                sleep 2
                docker_app ;;
        esac
    else
        clear
        echo "安装提示"
        echo -e "${CYAN}$docker_describe${NC}"
        echo -e "${CYAN}$docker_url${NC}"
        echo ""
        read -p "确定安装吗？(Y/N): " choice
        case "$choice" in
            [Yy])
                clear
                install_docker
                $docker_run
                clear
                echo -e "${GREEN}$docker_name 已经安装完成${NC}"
                echo "------------------------"
                if $has_ipv4; then
                    echo -e "HTTP 地址: http://$ipv4_address:$docker_port"
                fi
                if $has_ipv6; then
                    echo -e "HTTP 地址: http://[$ipv6_address]:$docker_port"
                fi
                echo ""
                $docker_use
                $docker_passwd
                ;;
            [Nn])
                echo -e "${YELLOW}已取消安装.${NC}"
                ;;
            *)
                echo -e "${RED}无效的选择，请输入 Y 或 N。${NC}"
                sleep 2
                docker_app ;;
        esac
    fi
}


# 开启 Docker 的 IPv6 支持
function docker_ipv6_on() {
    mkdir -p /etc/docker &>/dev/null
    cat > /etc/docker/daemon.json << EOF
{
  "ipv6": true,
  "fixed-cidr-v6": "2001:db8:1::/64"
}
EOF
    docker_restart
    echo -e "${GREEN}Docker 已开启 IPv6 访问${NC}"
}

# # 关闭 Docker 的 IPv6 支持
# function docker_ipv6_off() {
#     rm -rf /etc/docker/daemon.json &>/dev/null
#     docker_restart
#     echo -e "${GREEN}Docker 已关闭 IPv6 访问${NC}"
# }

# # 设置 iptables 规则，开放所有端口
# function iptables_open() {
#     iptables -P INPUT ACCEPT
#     iptables -P FORWARD ACCEPT
#     iptables -P OUTPUT ACCEPT
#     iptables -F 

#     ip6tables -P INPUT ACCEPT
#     ip6tables -P FORWARD ACCEPT
#     ip6tables -P OUTPUT ACCEPT
#     ip6tables -F
# }

# 系统清理函数
function system_cleanup() {
    display_header
    echo "正在清理系统..."
    sudo apt-get autoremove -y && sudo apt-get autoclean -y
    echo -e "${GREEN}系统清理完成！${NC}"
    read -rp "按任意键返回主菜单..." -n1
    show_menu
}

# 系统信息查询函数
function system_info() {
    display_header
    # 系统信息变量定义与获取
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
    ipv4_address=$(curl -s https://ipinfo.io/ip)
    ipv6_address=$(curl -s https://ifconfig.co/ip)
    current_time=$(date '+%Y-%m-%d %H:%M:%S')
    runtime=$(uptime -p)

    # 判断是否有 IPv4 和 IPv6 地址
    if [[ -n "$ipv4_address" ]]; then
        has_ipv4=true
    else
        has_ipv4=false
    fi

    if [[ -n "$ipv6_address" ]]; then
        has_ipv6=true
    else
        has_ipv6=false
    fi

    # 输出系统信息
    echo -e "${BLUE}系统信息查询${NC}"
    echo -e "${CYAN}主机名: ${WHITE}$hostname${NC}"
    echo -e "${CYAN}运营商: ${WHITE}$isp_info${NC}"
    echo -e "${CYAN}系统版本: ${WHITE}$os_info${NC}"
    echo -e "${CYAN}Linux版本: ${WHITE}$kernel_version${NC}"
    echo -e "${CYAN}CPU架构: ${WHITE}$cpu_arch${NC}"
    echo -e "${CYAN}CPU型号: ${WHITE}$cpu_info${NC}"
    echo -e "${CYAN}CPU核心数: ${WHITE}$cpu_cores${NC}"
    echo -e "${CYAN}CPU占用: ${WHITE}$cpu_usage_percent%${NC}"
    echo -e "${CYAN}物理内存: ${WHITE}$mem_info${NC}"
    echo -e "${CYAN}虚拟内存: ${WHITE}$swap_info${NC}"
    echo -e "${CYAN}硬盘占用: ${WHITE}$disk_info${NC}"
    echo -e "${CYAN}公网IPv4地址: ${WHITE}$ipv4_address${NC}"
    echo -e "${CYAN}公网IPv6地址: ${WHITE}$ipv6_address${NC}"
    echo -e "${CYAN}系统时区: ${WHITE}$(timedatectl | grep "Time zone" | awk '{print $3}')${NC}"
    echo -e "${CYAN}系统时间: ${WHITE}$current_time${NC}"
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
    echo -e "${GREEN}系统更新完成！${NC}"
    read -rp "按任意键返回主菜单..." -n1
    show_menu
}

# 检查并安装传入的软件包
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

# 定义检查 IPv4 和 IPv6 地址的函数
function has_ipv4_has_ipv6() {
    if [[ -n "$ipv4_address" ]]; then
        has_ipv4=true
    else
        has_ipv4=false
    fi

    if [[ -n "$ipv6_address" ]]; then
        has_ipv6=true
    else
        has_ipv6=false
    fi
}

# Docker 应用管理函数
function docker_app() {
    # 检查系统的 IPv4 和 IPv6 地址
    has_ipv4_has_ipv6

    # 定义 Docker 应用相关变量
    # 请根据实际情况修改以下变量
    docker_name="your_docker_container_name"       # Docker 容器名称
    docker_img="your_docker_image_name"            # Docker 镜像名称
    docker_run="docker run -d --name your_docker_container_name your_docker_image_name"  # 运行 Docker 容器的命令
    docker_port="8080"                              # 应用访问端口
    docker_describe="这是一个示例 Docker 应用。"        # 应用描述
    docker_url="https://example.com"                # 应用相关网址
    docker_use="echo -e '${GREEN}应用已启动，可正常使用。${NC}'"      # 启动后执行的命令
    docker_passwd="echo -e '${GREEN}默认密码已设置。${NC}'"          # 启动后执行的命令

    # 检查 Docker 容器是否存在
    if docker inspect "$docker_name" &>/dev/null; then
        clear
        echo -e "${GREEN}$docker_name 已安装，访问地址:${NC}"
        # 如果有 IPv4 地址，则显示 IPv4 访问地址
        if $has_ipv4; then
            echo -e "HTTP 地址: http://$ipv4_address:$docker_port"
        fi
        # 如果有 IPv6 地址，则显示 IPv6 访问地址
        if $has_ipv6; then
            echo -e "HTTP 地址: http://[$ipv6_address]:$docker_port"
        fi
        echo ""
        echo "应用操作"
        echo "------------------------"
        echo "1. 更新应用             2. 卸载应用"
        echo "------------------------"
        echo "0. 返回上一级选单"
        echo "------------------------"
        read -p "请输入你的选择: " sub_choice

        case $sub_choice in
            1)
                clear
                echo "正在更新应用..."
                # 更新应用
                docker rm -f "$docker_name"       # 删除现有的 Docker 容器
                docker rmi -f "$docker_img"       # 删除现有的 Docker 镜像
                $docker_run                        # 重新运行应用程序的命令
                clear
                echo -e "${GREEN}$docker_name 已经安装完成${NC}"
                echo "------------------------"
                echo "您可以使用以下地址访问:"
                if $has_ipv4; then
                    echo -e "HTTP 地址: http://$ipv4_address:$docker_port"
                fi
                if $has_ipv6; then
                    echo -e "HTTP 地址: http://[$ipv6_address]:$docker_port"
                fi
                echo ""
                $docker_use
                $docker_passwd
                ;;
            2)
                clear
                echo "正在卸载应用..."
                # 卸载应用
                docker rm -f "$docker_name"           # 删除 Docker 容器
                docker rmi -f "$docker_img"           # 删除 Docker 镜像
                rm -rf "/home/docker/$docker_name"    # 删除相关的本地文件
                echo -e "${GREEN}应用已卸载${NC}"
                ;;
            0)
                # 返回上一级菜单
                show_menu
                ;;
            *)
                echo -e "${RED}无效的选项，请重新选择。${NC}"
                sleep 2
                docker_app
                ;;
        esac
    else
        clear
        echo "安装提示"
        echo -e "${CYAN}$docker_describe${NC}"
        echo -e "${CYAN}$docker_url${NC}"
        echo ""
        read -p "确定安装吗？(Y/N): " choice
        case "$choice" in
            [Yy])
                clear
                install_docker                             # 安装 Docker 的函数
                $docker_run                                # 运行应用程序的命令
                clear
                echo -e "${GREEN}$docker_name 已经安装完成${NC}"
                echo "------------------------"
                echo "您可以使用以下地址访问:"
                if $has_ipv4; then
                    echo -e "HTTP 地址: http://$ipv4_address:$docker_port"
                fi
                if $has_ipv6; then
                    echo -e "HTTP 地址: http://[$ipv6_address]:$docker_port"
                fi
                echo ""
                $docker_use
                $docker_passwd
                ;;
            [Nn])
                echo -e "${YELLOW}已取消安装.${NC}"
                ;;
            *)
                echo -e "${RED}无效的选择，请输入 Y 或 N。${NC}"
                sleep 2
                docker_app
                ;;
        esac
    fi
}

# 服务器重启函数
function server_reboot() {
    # 询问是否重启服务器
    read -p "$(echo -e "${YELLOW}现在重启服务器吗？(Y/N): ${NC}")" rboot

    case "$rboot" in
        [Yy])
            echo -e "${GREEN}正在重启服务器...${NC}"
            reboot
            ;;
        [Nn])
            echo -e "${YELLOW}已取消重启.${NC}"
            ;;
        *)
            echo -e "${RED}无效的选择，请输入 Y 或 N。${NC}"
            sleep 2
            server_reboot
            ;;
    esac
}

# 显示主菜单
function show_menu() {
    display_header
    echo -e "${YELLOW}Sheng Cai 一键脚本工具${NC}"
    echo "请选择一个系统管理任务："
    echo -e "1) ${YELLOW}系统信息查询${NC}"
    echo -e "2) ${YELLOW}系统更新${NC}"
    echo -e "3) ${YELLOW}系统清理${NC}"
    echo -e "4) ${YELLOW}安装依赖${NC}"
    echo -e "5) ${YELLOW}卸载软件包${NC}"
    echo -e "6) ${YELLOW}检查端口占用${NC}"
    echo -e "7) ${YELLOW}安装 Docker${NC}"
    echo -e "8) ${YELLOW}Docker 应用管理${NC}"
    echo -e "9) ${YELLOW}服务器重启${NC}"
    echo -e "0) ${RED}退出${NC}"
    read -rp "输入选项 [0-9]: " choice
    case $choice in
        1) system_info ;;
        2) system_update ;;
        3) system_cleanup ;;
        4) install_dependency ;;
        5) 
            read -rp "请输入要卸载的软件包名称（多个请用空格分隔）: " packages
            remove $packages ;;
        6) check_port ;;
        7) install_docker ;;
        8) docker_app ;;
        9) server_reboot ;;
        0) exit 0 ;;
        *) 
            echo -e "${RED}无效的选项，请重新选择。${NC}" 
            sleep 2 
            show_menu ;;
    esac
}

# 运行前检测依赖
check_dependencies

# 启动主菜单
show_menu
