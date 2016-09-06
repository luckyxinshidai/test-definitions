#!/bin/sh

. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"

[ -d "${OUTPUT}" ] && mv "${OUTPUT}" "${OUTPUT}_$(date +%Y%m%d%H%M%S)"
mkdir -p "${OUTPUT}"

# Install lamp.
dist_name
case "${dist}" in
  Debian)
    title="Apache2 Debian Default Page: It works"
    pkgs="curl apache2 mysql-server php5-mysql php5-common libapache2-mod-php5"
    install_deps "${pkgs}"
    systemctl start apache2
    systemctl start mysql
    ;;
  CentOS)
    title="Apache HTTP Server Test Page powered by CentOS"
    pkgs="curl httpd mariadb-server mariadb php php-mysql"
    install_deps "${pkgs}"
    systemctl start httpd.service
    systemctl start mariadb
    ;;
  *)
    error_info "Unsupported distribution"
esac

# Test Apache.
curl http://localhost | grep "${title}"
check_return "apache2"

# Test mysql.
mysql -u root -e 'show databases'
check_return "mysql"

# Test php.
echo "<?php phpinfo(); ?>" > /var/www/html/info.php
curl http://localhost/info.php | grep "PHP Version"
check_return "php"
