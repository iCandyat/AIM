#!/bin/bash

# 更新系统软件包
echo "正在更新系统软件包..."
sudo yum update -y || { echo "系统软件包更新失败，但继续执行..."; }

# 移除旧的MySQL仓库
if rpm -q mysql57-community-release; then
    echo "检测到旧的MySQL 5.7仓库，正在移除..."
    sudo rpm -e mysql57-community-release || { echo "移除旧的MySQL 5.7仓库失败，但继续执行..."; }
else
    echo "未检测到旧的MySQL 5.7仓库，跳过移除步骤..."
fi

# 清理yum缓存
echo "正在清理yum缓存..."
sudo yum clean all || { echo "清理yum缓存失败，但继续执行..."; }

# 自动换源为阿里云镜像源
echo "正在备份原始的CentOS-Base.repo..."
sudo cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup || { echo "备份原始的CentOS-Base.repo失败，但继续执行..."; }

echo "正在下载并替换为阿里云镜像源..."
sudo wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo || { echo "下载并替换为阿里云镜像源失败，但继续执行..."; }

echo "正在清理并重建yum缓存..."
sudo yum clean all || { echo "清理yum缓存失败，但继续执行..."; }
sudo yum makecache || { echo "重建yum缓存失败，但继续执行..."; }

# 重新添加MySQL官方yum仓库
echo "正在下载并添加MySQL 8.0官方yum仓库..."
wget https://dev.mysql.com/get/mysql80-community-release-el7-3.noarch.rpm || { echo "下载MySQL 8.0官方yum仓库失败，但继续执行..."; }
sudo rpm -ivh mysql80-community-release-el7-3.noarch.rpm --force --nodeps || { echo "添加MySQL 8.0官方yum仓库失败，但继续执行..."; }

# 检查并禁用不需要的MySQL版本
echo "正在禁用不需要的MySQL 5.7版本..."
sudo sed -i '/\[mysql57-community\]/,/^\[/ s/enabled=1/enabled=0/' /etc/yum.repos.d/mysql-community.repo || { echo "禁用MySQL 5.7版本失败，但继续执行..."; }

# 安装MySQL
echo "正在安装MySQL 8.0..."
sudo yum install mysql-community-server -y --nogpgcheck || { echo "安装MySQL 8.0失败，但继续执行..."; }

# 启动MySQL服务
echo "正在启动MySQL服务..."
sudo systemctl start mysqld || { echo "启动MySQL服务失败，但继续执行..."; }
sudo systemctl enable mysqld || { echo "设置MySQL开机自启失败，但继续执行..."; }

# 获取临时密码
echo "正在获取MySQL临时密码..."
temp_password=$(sudo grep 'temporary password' /var/log/mysqld.log | awk '{print $NF}')
if [ -z "$temp_password" ]; then
    echo "未找到MySQL临时密码，可能日志文件位置或内容不正确。"
else
    echo "临时密码: $temp_password"
fi

# 自动执行mysql_secure_installation
echo "正在执行mysql_secure_installation..."
sudo mysql_secure_installation <<EOF

$temp_password
Y
你的新密码
你的新密码
Y
Y
Y
Y
EOF

# 自动登录MySQL
echo "正在自动登录MySQL..."
mysql -u root -p <<EOF
你的新密码
EOF
