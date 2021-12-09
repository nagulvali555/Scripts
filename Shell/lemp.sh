#!/usr/bin/env bash

# LEMP(Linux, nginx, mysql, php) Fast cgi stack installation
# Supported platforms:
# 1. ubuntu
# 2. centos
# Script version: 1.0.0

# Issues: version dependencies

# log
logger() {
  level=$(echo "$1" | tr '[a-z]' '[A-Z]')
  message=$2
  echo "[$(date)]::[$level]:: $message"
  exit 1
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
  && yum install epel-release \
  && yum install nginx \
  && systemctl start nginx \
  && systemctl enable nginx \
  && yum install mariadb-server mariadb \
  && systemctl enable mariadb \
  && yum install http://rpms.remirepo.net/enterprise/remi-release-7.rpm \
  && yum --disablerepo="*" --enablerepo="remi-safe" list php[7-9][0-9].x86_64 \
  && yum-config-manager --enable remi-php74 \
  && yum install php php-mysqlnd php-fpm \
  && logger 'info' 'Installations successful'
}

debian () {
  echo
}

# Check platform
main() {
  # check elevated user
  elevated_user_check

  # Installation based on linux distribution
  case $(cat /etc/os-release | grep -i "^name" | cut -d "\"" -f 2) in
  "Ubuntu")
    debian;;
  "Centos"|"Amazon Linux")
    centos;;
  *)
    logger 'error' 'Linux distribution is not compatible';;
  esac
}

# main
main