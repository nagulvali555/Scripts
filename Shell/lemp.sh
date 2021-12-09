#!/usr/bin/env bash

# LEMP(Linux, nginx, mysql, php) Fast cgi stack installation
# Supported platforms:
# 1. ubuntu
# 2. centos
# Script version: 1.0.0

header() {
  cat <<EOF
"###################################################"
"# Program: LEMP Installation Script               #"
"# Description: Installs and setup LEMP server     #"
"#              nginx, mariadb, php fast-cgi       #"
"# Supported Platforms: Ubuntu, CentOS             #"
"###################################################"
EOF
}

# log
logger() {
  level=$(echo "$1" | tr '[a-z]' '[A-Z]')
  message=$2
  echo "[$(date)]::[$level]:: $message"
}

# root user access
elevated_user_check() {
  if [[ $(id -u) -ne 0 ]]
  then
    logger 'error' 'Use elevated user (root) to run this script'
  fi
}

centos() {
  # update repos and install lemp stack
  yum update -y \
  && yum install -y epel-release \
  && yum install -y nginx \
  && systemctl start nginx \
  && systemctl enable nginx \
  && yum install -y mariadb-server mariadb \
  && systemctl -y enable mariadb \
  && yum install -y http://rpms.remirepo.net/enterprise/remi-release-7.rpm \
  && yum --disablerepo="*" --enablerepo="remi-safe" list php[7-9][0-9].x86_64 \
  && yum-config-manager --enable remi-php74 \
  && yum install -y php php-mysqlnd php-fpm \
  && logger 'info' 'Installations successful'

  logger 'info' 'Updating config files'
  cp -rf ../config/www.conf /etc/php-fpm.d/www.conf \
  && cp -rf ../config/nginx.conf /etc/nginx/nginx.conf \
  && systemctl start php-fpm \
  && systemctl restart nginx

  logger 'info' 'To setup database execute \"mysql_secure_installation\" command'
}

debian () {

  # update repos and install lemp stack
  apt update \
  && apt install nginx \
  && apt install mysql-server \
  && apt install php-fpm php-mysql \
  && systemctl enable nginx \
  && systemctl start nginx \
  && systemctl start mysqld \
  && systemctl enable mysqld

}

# Check platform
main() {

  # welcome message
  header

  # check elevated user
  elevated_user_check

  # Installation based on linux distribution
  case $(grep -i "^name" /etc/os-release | cut -d "\"" -f 2) in
  "Ubuntu")
    debian;;
  "CentOS Linux"|"Amazon Linux")
    centos;;
  *)
    logger 'error' 'Linux distribution is not compatible';;
  esac

}

# main
main