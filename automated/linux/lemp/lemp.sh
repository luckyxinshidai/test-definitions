#!/bin/sh -ex

# shellcheck disable=SC1091
. ../../lib/sh-test-lib
OUTPUT="$(pwd)/output"
RESULT_FILE="${OUTPUT}/result.txt"
export RESULT_FILE

! check_root && error_msg "This script must be run as root"
[ -d "${OUTPUT}" ] && mv "${OUTPUT}" "${OUTPUT}_$(date +%Y%m%d%H%M%S)"
mkdir -p "${OUTPUT}"

# Install LEMP and use systemctl to start/restart services.
# systemctl available on Debian 8, CentOS 7 and newer releases.
dist_name
# shellcheck disable=SC2154
case "${dist}" in
    Debian)
        # Install packages.
        pkgs="nginx mysql-server php5-mysql php5-fpm curl"
        install_deps "${pkgs}"

        # Copy pre-defined html/php files to root directory.
        mv /usr/share/nginx/html /usr/share/nginx/html.bak
        mkdir -p /usr/share/nginx/html
        cp ./html/* /usr/share/nginx/html/

        # Stop apache server in case it is installed and running.
        systemctl stop apache2 > /dev/null 2>&1 || true

        systemctl restart nginx
        systemctl restart mysql

        # Config PHP.
        cp /etc/php5/fpm/php.ini /etc/php5/fpm/php.ini.bak
        sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php5/fpm/php.ini
        systemctl restart php5-fpm

        # Configure NGINX for PHP.
        mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
        cp ./debian-nginx.conf /etc/nginx/sites-available/default
        systemctl restart nginx
        ;;
    CentOS)
        # Install packages. x86_64 nginx package can be installed from epel
        # repo. However, epel project doesn't support ARM arch yet.
        # TODO: check on RPB build if nginx available.
        install_deps "epel-release"
        pkgs="nginx mariadb-server mariadb php php-mysql php-fpm curl"
        install_deps "${pkgs}"

        # Copy pre-defined html/php files to root directory.
        mv /usr/share/nginx/www /usr/share/nginx/www.bak
        mkdir -p /usr/share/nginx/www
        cp ./html/* /usr/share/nginx/www/

        # Stop apache server in case it is installed and running.
        systemctl stop httpd.service > /dev/null 2>&1 || true

        systemctl restart nginx
        systemctl restart mariadb

        # Configure PHP.
        cp /etc/php.ini /etc/php.ini.bak
        sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php.ini
        sed -i "s/listen.allowed_clients = 127.0.0.1/listen = \/run\/php-fpm\/php-fpm.sock/" /etc/php-fpm.d/www.conf
        sed -i "s/;listen.owner = nobody/listen.owner = nginx/" /etc/php-fpm.d/www.conf
        sed -i "s/;listen.group = nobody/listen.group = nginx/" /etc/php-fpm.d/www.conf
        sed -i "s/user = apache/user = nginx/" /etc/php-fpm.d/www.conf
        sed -i "s/group = apache/group = nginx/" /etc/php-fpm.d/www.conf
        # This creates the needed php-fpm.sock file
        systemctl restart php-fpm
        chmod 666 /run/php-fpm/php-fpm.sock
        chown nginx:nginx /run/php-fpm/php-fpm.sock
        systemctl restart php-fpm

        # Configure NGINX for PHP.
        mv /etc/nginx/default.d/default.conf /etc/nginx/default.d/default.conf.bak
        cp ./centos-nginx.conf /etc/nginx/default.d/default.conf
        systemctl restart nginx
        ;;
    *)
        info_msg "Supported distributions: Debian, CentOS"
        error_msg "Unsupported distribution: ${dist}"
        ;;
esac

# Test Nginx.
skip_list="mysql-show-databases phpinfo php-connect-db php-create-db
    php-create-table php-add-record php-select-record php-delete-record"
curl -o "${OUTPUT}/index.html" "http://localhost/index.html"
test_command="grep 'Test Page for the Nginx HTTP Server' ${OUTPUT}/index.html"
run_test_case "${test_command}" "test-nginx-server" "${skip_list}"

# Test MySQL.
skip_list="phpinfo php-connect-db php-create-db php-create-table
    php-add-record php-select-record php-delete-record"
mysqladmin -u root password lemptest
test_command="mysql --user='root' --password='lemptest' -e 'show databases'"
run_test_case "${test_command}" "mysql-show-databases" "${skip_list}"

# Test PHP.
skip_list="php-connect-db php-create-db php-create-table php-add-record
    php-select-record php-delete-record"
curl -o "${OUTPUT}/phpinfo.html" "http://localhost/info.php"
test_command="grep 'PHP Version' ${OUTPUT}/phpinfo.html"
run_test_case "${test_command}" "test-phpinfo" "${skip_list}"

# PHP Connect to MySQL.
skip_list="php-create-db php-create-table php-add-record php-select-record php-delete-record"
curl -o "${OUTPUT}/connect-db" "http://localhost/connect-db.php"
test_command="grep 'Connected successfully' ${OUTPUT}/connect-db"
run_test_case "${test_command}" "php-connect-db" "${skip_list}"

# PHP Create a MySQL Database.
skip_list="php-create-table php-add-record php-select-record php-delete-record"
curl -o "${OUTPUT}/create-db" "http://localhost/create-db.php"
test_command="grep 'Database created successfully' ${OUTPUT}/create-db"
run_test_case "${test_command}" "php-create-db" "${skip_list}"

# PHP Create MySQL table.
skip_list="php-add-record php-select-record php-delete-record"
curl -o "${OUTPUT}/create-table" "http://localhost/create-table.php"
test_command="grep 'Table MyGuests created successfully' ${OUTPUT}/create-table"
run_test_case "${test_command}" "php-create-table" "${skip_list}"

# PHP add record to MySQL table.
skip_list="php-select-record php-delete-record"
curl -o "${OUTPUT}/add-record" "http://localhost/add-record.php"
test_command="grep 'New record created successfully' ${OUTPUT}/add-record"
run_test_case "${test_command}" "php-create-recoard" "${skip_list}"

# PHP select record from MySQL table.
skip_list="php-delete-record"
curl -o "${OUTPUT}/select-record" "http://localhost/select-record.php"
test_command="grep 'id: 1 - Name: John Doe' ${OUTPUT}/select-record"
run_test_case "${test_command}" "php-select-record" "${skip_list}"

# PHP delete record from MySQL table.
curl -o "${OUTPUT}/delete-record" "http://localhost/delete-record.php"
test_command="grep 'Record deleted successfully' ${OUTPUT}/delete-record"
run_test_case "${test_command}" "php-delete-record"

# Cleanup.
# Delete myDB for the next run.
mysql --user='root' --password='lemptest' -e 'DROP DATABASE myDB'

# Restore from backups.
# shellcheck disable=SC2154
case "${dist}" in
    Debian)
        mv /usr/share/nginx/html.bak /usr/share/nginx/html
        mv /etc/php5/fpm/php.ini.bak /etc/php5/fpm/php.ini
        mv /etc/nginx/sites-available/default.bak /etc/nginx/sites-available/default
        ;;
    CentOS)
        mv /usr/share/nginx/www.bak /usr/share/nginx/www
        cp /etc/php.ini.bak /etc/php.ini
        mv /etc/nginx/default.d/default.conf.bak /etc/nginx/default.d/default.conf
        ;;
esac
