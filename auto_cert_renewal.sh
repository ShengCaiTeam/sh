#!/bin/bash

# 定义证书存储目录和续签提前天数
certs_directory="/home/web/certs/"  # 存储证书的目录
days_before_expiry=5  # 设置在证书到期前几天触发续签

# 遍历所有符合模式的证书文件（_cert.pem 结尾的文件）
for cert_file in $certs_directory*_cert.pem; do
    # 获取域名
    domain=$(basename "$cert_file" "_cert.pem")

    # 输出正在检查的证书信息
    echo "检查证书过期日期： ${domain}"

    # 获取证书的过期日期
    expiration_date=$(openssl x509 -enddate -noout -in "${certs_directory}${domain}_cert.pem" | cut -d "=" -f 2-)

    # 输出证书的过期日期
    echo "过期日期： ${expiration_date}"

    # 将过期日期转换为时间戳
    expiration_timestamp=$(date -d "${expiration_date}" +%s)
    current_timestamp=$(date +%s)

    # 计算距离过期的天数
    days_until_expiry=$(( ($expiration_timestamp - $current_timestamp) / 86400 ))

    # 检查是否需要续签
    if [ $days_until_expiry -le $days_before_expiry ]; then
        echo "证书将在 ${days_before_expiry} 天内过期，正在进行自动续签。"

        # 停止 Nginx 服务
        docker stop nginx

        # 临时开放所有 iptables 规则，防止续签过程中被防火墙阻挡
        iptables -P INPUT ACCEPT
        iptables -P FORWARD ACCEPT
        iptables -P OUTPUT ACCEPT
        iptables -F
    
        ip6tables -P INPUT ACCEPT
        ip6tables -P FORWARD ACCEPT
        ip6tables -P OUTPUT ACCEPT
        ip6tables -F

        # 续签证书，使用 certbot 的 standalone 模式
        certbot certonly --standalone -d $domain --email your@email.com --agree-tos --no-eff-email --force-renewal --key-type ecdsa

        # 复制续签后的证书和私钥到指定目录
        cp /etc/letsencrypt/live/$domain/fullchain.pem ${certs_directory}${domain}_cert.pem
        cp /etc/letsencrypt/live/$domain/privkey.pem ${certs_directory}${domain}_key.pem

        # 重新启动 Nginx 服务
        docker start nginx

        echo "证书已成功续签。"
    else
        # 如果证书仍然有效，则输出剩余的有效天数
        echo "证书仍然有效，距离过期还有 ${days_until_expiry} 天。"
    fi

    # 输出分隔线
    echo "--------------------------"
done
