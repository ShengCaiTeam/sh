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
    check_dependency "curl"
    check_dependency "awk"
    check_dependency "lsb_release"
    check_dependency "docker"
    check_dependency "iptables"
    check_dependency "ss"
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
    docker_name="your_docker_container_name"
    docker_img="your_docker_image_name"
    docker_run="docker run -d --name your_docker_container_name your_docker_image_name"
    docker_port="8080"
    docker_describe="这是一个示例 Docker 应用。"
    docker_url="https://example.com"
    docker_use="echo -e '${GREEN}应用已启动，可正常使用。${NC}'"
    docker_passwd="echo -e '${GREEN}默认密码已设置。${NC}'"

    if docker inspect "$docker_name" &>/dev/null; then
        clear
        echo -e "${GREEN}$docker_name 已安装，访问地址:${NC}"
        if $has_ipv4; then
            echo -e "HTTP 地址: http://$ipv4_address:$docker_port"
        fi
        if $has_ipv6; then
            echo -e "HTTP 地址: http://[$ipv6_address]:$docker_port"
        fi
        echo "1. 更新应用             2. 卸载应用"
        echo "0. 返回上一级选单"
        read -p "请输入你的选择: " sub_choice

        case $sub_choice in
            1) docker rm -f "$docker_name"
               docker rmi -f "$docker_img"
               $docker_run
               echo -e "${GREEN}$docker_name 已经安装完成${NC}"
               ;;
            2) docker rm -f "$docker_name"
               docker rmi -f "$docker_img"
               rm -rf "/home/docker/$docker_name"
               echo -e "${GREEN}应用已卸载${NC}"
               ;;
            0) show_menu ;;
            *) echo -e "${RED}无效的选项，请重新选择。${NC}"
               docker_app ;;
        esac
    else
        clear
        echo -e "${CYAN}$docker_describe${NC}"
        echo -e "${CYAN}$docker_url${NC}"
        read -p "确定安装吗？(Y/N): " choice
        case "$choice" in
            [Yy]) install_docker
                  $docker_run
                  echo -e "${GREEN}$docker_name 已经安装完成${NC}"
                  $docker_use
                  $docker_passwd ;;
            [Nn]) echo -e "${YELLOW}已取消安装.${NC}" ;;
            *) echo -e "${RED}无效的选择，请输入 Y 或 N。${NC}"
               docker_app ;;
        esac
    fi
}

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
    hostname=$(hostname)
    isp_info=$(curl -s https://ipinfo.io/org)
    os_info=$(lsb_release -d | awk -F "\t" '{print $2}')
    kernel_version=$(uname -r)
    cpu_arch=$(uname -m)
    cpu_info=$(lscpu | grep 'Model name' | awk -F ':' '{print $2}' | sed 's/^ *//g')
    cpu_cores=$(nproc)
    cpu_usage_percent=$(top -bn1 | grep "Cpu(s)" | awk '{print 100 - $1}')
    mem_info=$(free -h | grep 'Mem:' | awk '{print $2}')
    swap_info=$(free -h | grep 'Swap:' | awk '{print $2}')
    disk_info=$(df -h --total | grep 'total' | awk '{print $3 " / " $2 " (" $5 ")"}')
    ipv4_address=$(curl -s https://ipinfo.io/ip)
    ipv6_address=$(curl -s https://ifconfig.co/ip)
    current_time=$(date '+%Y-%m-%d %H:%M:%S')
    runtime=$(uptime -p)

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
    echo -e "${CYAN}系统时间: ${WHITE}$current_time${NC}"
    echo -e "${CYAN}系统运行时长: ${WHITE}$runtime${NC}"
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
                dnf -y install "$package"
            elif command -v yum &>/dev/null; then
                yum -y install "$package"
            elif command -v apt &>/dev/null; then
                apt install -y "$package"
            elif command -v apk &>/dev/null; then
                apk add "$package"
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

# 检查系统 IPv4 和 IPv6 地址
function has_ipv4_has_ipv6() {
    ipv4_address=$(curl -s https://ipinfo.io/ip)
    ipv6_address=$(curl -s https://ifconfig.co/ip)
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

# Docker 应用管理
function docker_app() {
    has_ipv4_has_ipv6
    docker_name="your_docker_container_name"
    docker_img="your_docker_image_name"
    docker_run="docker run -d --name your_docker_container_name your_docker_image_name"
    docker_port="8080"
    docker_describe="这是一个示例 Docker 应用。"
    docker_url="https://example.com"
    docker_use="echo -e '${GREEN}应用已启动，可正常使用。${NC}'"
    docker_passwd="echo -e '${GREEN}默认密码已设置。${NC}'"

    if docker inspect "$docker_name" &>/dev/null; then
        clear
        echo -e "${GREEN}$docker_name 已安装，访问地址:${NC}"
        if $has_ipv4; then
            echo -e "HTTP 地址: http://$ipv4_address:$docker_port"
        fi
        if $has_ipv6; then
            echo -e "HTTP 地址: http://[$ipv6_address]:$docker_port"
        fi
        echo "1. 更新应用             2. 卸载应用"
        echo "0. 返回上一级选单"
        read -p "请输入你的选择: " sub_choice
        case $sub_choice in
            1) docker rm -f "$docker_name"
               docker rmi -f "$docker_img"
               $docker_run
               echo -e "${GREEN}$docker_name 已经安装完成${NC}"
               ;;
            2) docker rm -f "$docker_name"
               docker rmi -f "$docker_img"
               rm -rf "/home/docker/$docker_name"
               echo -e "${GREEN}应用已卸载${NC}"
               ;;
            0) show_menu ;;
            *) echo -e "${RED}无效的选项，请重新选择。${NC}"
               docker_app ;;
        esac
    else
        clear
        echo -e "${CYAN}$docker_describe${NC}"
        echo -e "${CYAN}$docker_url${NC}"
        read -p "确定安装吗？(Y/N): " choice
        case "$choice" in
            [Yy]) install_docker
                  $docker_run
                  echo -e "${GREEN}$docker_name 已经安装完成${NC}"
                  $docker_use
                  $docker_passwd ;;
            [Nn]) echo -e "${YELLOW}已取消安装.${NC}" ;;
            *) echo -e "${RED}无效的选择，请输入 Y 或 N。${NC}"
               docker_app ;;
        esac
    fi
}

# 增加交换空间函数
add_swap() {
    swap_partitions=$(grep -E '^/dev/' /proc/swaps | awk '{print $1}')
    for partition in $swap_partitions; do
      swapoff "$partition"
      wipefs -a "$partition"
      mkswap -f "$partition"
    done

    swapoff /swapfile
    rm -f /swapfile
    dd if=/dev/zero of=/swapfile bs=1M count=$new_swap
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile

    if [ -f /etc/alpine-release ]; then
        echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
        echo "nohup swapon /swapfile" >> /etc/local.d/swap.start
        chmod +x /etc/local.d/swap.start
        rc-update add local
    else
        echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
    fi
    echo -e "虚拟内存大小已调整为${YELLOW}${new_swap}${NC}MB"
}

# LDNMP 环境版本检查函数
ldnmp_v() {
    nginx_version=$(docker exec nginx nginx -v 2>&1 | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
    dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
    mysql_version=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
    php_version=$(docker exec php php -v 2>/dev/null | grep -oP "PHP \K[0-9]+\.[0-9]+\.[0-9]+")
    redis_version=$(docker exec redis redis-server -v 2>&1 | grep -oP "v=+\K[0-9]+\.[0-9]+")
    echo -e "nginx : ${YELLOW}v$nginx_version${NC}            mysql : ${YELLOW}v$mysql_version${NC}            php : ${YELLOW}v$php_version${NC}            redis : ${YELLOW}v$redis_version${NC}"
    echo "------------------------"
}

# 安装 LDNMP 环境
install_ldnmp() {
    new_swap=1024
    add_swap
    cd /home/web && docker compose up -d
    clear
    echo "正在配置LDNMP环境，请耐心稍等……"

    commands=(
        "docker exec nginx chmod -R 777 /var/www/html"
        "docker restart nginx"
        "docker exec php apk update"
        "docker exec php74 apk update"
        "docker exec php install-php-extensions mysqli pdo_mysql gd intl zip exif bcmath opcache imagick redis"
        "docker exec php74 install-php-extensions mysqli pdo_mysql gd intl zip exif bcmath opcache imagick redis"
        "docker exec php sh -c 'echo \"upload_max_filesize=50M \" > /usr/local/etc/php/conf.d/uploads.ini'"
        "docker exec php sh -c 'echo \"post_max_size=50M \" > /usr/local/etc/php/conf.d/post.ini'"
        "docker exec php sh -c 'echo \"memory_limit=256M\" > /usr/local/etc/php/conf.d/memory.ini'"
        "docker restart php"
        "docker restart php74"
    )

    total_commands=${#commands[@]}

    for ((i = 0; i < total_commands; i++)); do
        command="${commands[i]}"
        eval $command
        percentage=$(( (i + 1) * 100 / total_commands ))
        completed=$(( percentage / 2 ))
        remaining=$(( 50 - completed ))
        progressBar="["
        for ((j = 0; j < completed; j++)); do
            progressBar+="#"
        done
        for ((j = 0; j < remaining; j++)); do
            progressBar+="."
        done
        progressBar+="]"
        echo -ne "\r[${GREEN}$percentage%${NC}] $progressBar"
    done

    echo
    clear
    echo "LDNMP环境安装完毕"
    ldnmp_v
}

# 安装 Certbot 函数
install_certbot() {
    if command -v yum &>/dev/null; then
        install epel-release certbot
    elif command -v apt &>/dev/null; then
        install snapd
        snap install core
        snap install --classic certbot
        rm /usr/bin/certbot
        ln -s /snap/bin/certbot /usr/bin/certbot
    else
        install certbot
    fi

    cd ~ || exit
    curl -O https://raw.gitmirror.com/shengcaiteam/shengcai.sh/main/auto_cert_renewal.sh
    chmod +x auto_cert_renewal.sh

    cron_job="0 0 * * * ~/auto_cert_renewal.sh"
    existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")
    if [ -z "$existing_cron" ]; then
        (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
        echo "续签任务已添加"
    else
        echo "续签任务已存在，无需添加"
    fi
}

# 主菜单函数
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
    echo -e "9) ${YELLOW}安装 Certbot${NC}"
    echo -e "10) ${YELLOW}管理交换空间${NC}"
    echo -e "11) ${YELLOW}安装 LDNMP 环境${NC}"
    echo -e "0) ${RED}退出${NC}"
    read -rp "输入选项 [0-11]: " choice
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
        9) install_certbot ;;
        10) read -rp "请输入交换空间大小（单位MB）: " new_swap
            add_swap ;;
        11) install_ldnmp ;;
        0) exit 0 ;;
        *) echo -e "${RED}无效的选项，请重新选择。${NC}"
           sleep 2
           show_menu ;;
    esac
}

# 运行前检测依赖
check_dependencies

# 启动主菜单
show_menu
