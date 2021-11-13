#!/bin/bash

# Auto install script for a new rocky nextcloud server
# Edited : 26/10/2021 09:21
# Author : Fabian INGREMEAU
# Version : 0.1

# Colors
N="\e[0m"
B="\e[1m"
G="\e[32m"
R="\e[31m"
Y="\e[33m"

# Globals
hostname=""
nextcloud_domain_name=""
reverse_nextcloud_domain_name=""
netdata_domain_name=""
reverse_netdata_domain_name=""
mysql_root_password=""
mysql_nextcloud_password=""
ip_ssh_firewall=""

function check_root() {
  if [[ $(id -u) -ne 0 ]] ; then
    >&2 echo -e "${R}${B}[ERROR]${N} This script must be run as root."
    exit 1
  fi
}

function check_error() {
     if [[ $? -ne 0 ]] ; then
    >&2 echo -e "${R}${B}[ERROR]${N} Failed to execute a command in the script !\nError code : $?"
    exit 1
  fi
}

function get_infos() {
    echo -n "Enter new machine hostname : "
    read hostname

    echo -n "Enter nextcloud domain name : "
    read nextcloud_domain_name

    echo -n "Enter reversed nextcloud  domain name (toto.tata.com => com.tata.toto) : "
    read reverse_nextcloud_domain_name

    echo -n "Enter netdata domain name : "
    read netdata_domain_name

    echo -n "Enter reversed netdata domain name (toto.tata.com => com.tata.toto) : "
    read reverse_netdata_domain_name

    echo -n "Enter ssl cert path : "
    read ssl_crt_path

    echo -n "Enter ssl certificate key path : "
    read ssl_crt_key_path

    echo -n "Enter mysql root password (max 32 ch) : "
    read mysql_root_password

    echo -n "Enter mysql nextcloud password (max 32 ch) : "
    read mysql_nextcloud_password

    echo -n "Enter your ip for ssh connection (X.X.X.X/XX) : "
    read ip_ssh_firewall
}


# Install required packets
function install_packets() {
    # Nextcloud
    dnf update -y
    check_error
    dnf install -y epel-release dnf-plugins-core
    check_error
    dnf config-manager --set-enabled powertools
    check_error
    dnf update -y
    check_error
    dnf install -y python3 bind-utils nmap git nc tcpdump vim mariadb-server https://rpms.remirepo.net/enterprise/remi-release-8.rpm
    check_error
    dnf module enable -y php:remi-7.4
    check_error
    dnf install -y httpd mariadb-server vim wget zip unzip libxml2 openssl php74-php php74-php-ctype php74-php-curl php74-php-gd php74-php-iconv php74-php-json php74-php-libxml php74-php-mbstring php74-php-openssl php74-php-posix php74-php-session php74-php-xml php74-php-zip php74-php-zlib php74-php-pdo php74-php-mysqlnd php74-php-intl php74-php-bcmath php74-php-gmp
    check_error

    # Vim 
    git clone --depth=1 https://github.com/amix/vimrc.git /opt/vim_runtime
    check_error
    pushd /opt/vim_runtime/
    ./install_awesome_parameterized.sh /opt/vim_runtime --all
    check_error
    popd
}

function configure_apache() {
    time_zone=$(timedatectl | grep -i zone | awk '{print $3}')
    mkdir /etc/httpd/sites-available /etc/httpd/sites-enabled
    check_error

    # Setup config file
    cp nextcloud_server_conf /etc/httpd/sites-available/$reverse_nextcloud_domain_name
    check_error
    sed -i -e "s/__SERVER__NAME__/$nextcloud_domain_name/g" /etc/httpd/sites-available/$reverse_nextcloud_domain_name
    check_error
    sed -i -e "s/__REVERSE__DOMAIN__NAME__/$reverse_nextcloud_domain_name/g" /etc/httpd/sites-available/$reverse_nextcloud_domain_name
    check_error
    sed -i -e "s/;date.timezone =/date.timezone = ${time_zone/\//\\\/}/g" /etc/opt/remi/php74/php.ini
    check_error

    systemctl enable httpd
    check_error
    ln -s /etc/httpd/sites-available/$reverse_nextcloud_domain_name /etc/httpd/sites-enabled/
    check_error
    mkdir -p /var/www/sub-domains/$reverse_nextcloud_domain_name/html
    check_error

    echo "IncludeOptional sites-enabled/*" >> /etc/httpd/conf/httpd.conf
}

function configure_mariadb() {
    systemctl enable --now mariadb
    check_error

    # Replacing mysql_secure_instalaltion
    mysql_secure_installation
    mysql --user=root --password=$mysql_root_password -e "CREATE USER 'nextcloud'@'localhost' IDENTIFIED BY '$mysql_nextcloud_password'"
    check_error
    mysql --user=root --password=$mysql_root_password -e "CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci"
    check_error
    mysql --user=root --password=$mysql_root_password -e "GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'localhost'"
    check_error
    mysql --user=root --password=$mysql_root_password -e "FLUSH PRIVILEGES"
    check_error
}

function install_nextcloud() {
    pushd ~
    wget https://download.nextcloud.com/server/releases/nextcloud-22.2.0.zip
    check_error
    unzip nextcloud-22.2.0.zip
    check_error
    mv nextcloud/* /var/www/sub-domains/$reverse_nextcloud_domain_name/html/
    check_error
    popd

    chown -Rf apache.apache /var/www/sub-domains/$reverse_nextcloud_domain_name/html
    check_error
}

function install_netdata() {
    bash <(curl -Ss https://my-netdata.io/kickstart.sh) --non-interactive
    check_error
    
    # Setup apache config
    cp netdata_server_conf /etc/httpd/sites-available/$reverse_netdata_domain_name
    check_error
    sed -i -e "s/__SERVER__NAME__/$reverse_netdata_domain_name/g" /etc/httpd/sites-available/$reverse_netdata_domain_name
    check_error
    ln -s /etc/httpd/sites-available/$reverse_netdata_domain_name /etc/httpd/sites-enabled/
    check_error
}

function configure_selinux() {
    semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/sub-domains/$reverse_nextcloud_domain_name/html/data(/.*)?"
    check_error
    semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/sub-domains/$reverse_nextcloud_domain_name/html/config(/.*)?"
    check_error
    semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/sub-domains/$reverse_nextcloud_domain_name/html/apps(/.*)?"
    check_error
    semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/sub-domains/$reverse_nextcloud_domain_name/html/.htaccess"
    check_error
    semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/sub-domains/$reverse_nextcloud_domain_name/html/.user.ini"
    check_error
    semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/sub-domains/$reverse_nextcloud_domain_name/html/3rdparty/aws/aws-sdk-php/src/data/logs(/.*)?"
    check_error

    restorecon -Rv "/var/www/sub-domains/$reverse_nextcloud_domain_name/html/"
    check_error
    setsebool httpd_unified on
    check_error
    setsebool httpd_can_network_connect on
    check_error
    setsebool httpd_can_network_connect on -P
    check_error
    setsebool httpd_read_user_content on
    check_error
}

function configure_firewall {
    interface_name="$(find /sys/class/net -mindepth 1 -maxdepth 1 ! -name lo -printf "%P")"
    check_error

    firewall-cmd --remove-service=cockpit
    check_error
    firewall-cmd --remove-service=dhcpv6-client
    check_error

    firewall-cmd --set-default-zone=drop
    check_error
    firewall-cmd --zone=drop --add-interface=$interface_name
    check_error

    firewall-cmd --new-zone=ssh --permanent
    check_error
    firewall-cmd --runtime-to-permanent
    check_error
    systemctl restart firewalld
    check_error

    firewall-cmd --zone=ssh --add-source=$ip_ssh_firewall
    check_error
    firewall-cmd --zone=ssh --add-service=ssh
    check_error

    firewall-cmd --add-service=http
    check_error
    firewall-cm --add-service=https
    check_error

    firewall-cmd --runtime-to-permanent
    check_error
    systemctl restart firewalld
    check_error
}

function finish_install() {
    systemctl restart httpd
    systemctl restart mariadb
}

function main() {
    check_root
    get_infos
    install_packets
    configure_apache
    configure_mariadb
    install_nextcloud
    install_netdata
    configure_selinux
    configure_firewall
    finish_install
}

main
