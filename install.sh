#!/bin/bash

# /*=================================
# =            VARIABLES            =
# =================================*/
INSTALL_NGINX_INSTEAD=0
WELCOME_MESSAGE='
Welcome to my lamp box!
You can visit me at joaocosta.info, follow me on Twitter @JonnyDevv or github.com/jonnydevv.
'

reboot_webserver_helper() {

    if [ $INSTALL_NGINX_INSTEAD != 1 ]; then
        sudo service apache2 restart
    fi

    if [ $INSTALL_NGINX_INSTEAD == 1 ]; then
        sudo systemctl restart php7.3-fpm
        sudo systemctl restart nginx
    fi

    echo 'Rebooting your webserver'
}





# /*=========================================
# =            CORE / BASE STUFF            =
# =========================================*/
sudo apt-get update

# The following is "sudo apt-get -y upgrade" without any prompts
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade

sudo apt-get install -y build-essential
sudo apt-get install -y tcl
sudo apt-get install -y software-properties-common
sudo apt-get install -y python-software-properties
sudo apt-get -y install vim
sudo apt-get -y install git

# Weird Vagrant issue fix
sudo apt-get install -y ifupdown



# /*======================================
# =            INSTALL APACHE            =
# ======================================*/
if [ $INSTALL_NGINX_INSTEAD != 1 ]; then

    # Install the package
    sudo add-apt-repository -y ppa:ondrej/apache2 # Super Latest Version
    sudo apt-get update
    sudo apt-get -y install apache2

    # Remove "html" and add public
    mv /var/www/html /var/www/public

    # Clean VHOST with full permissions
    MY_WEB_CONFIG='<VirtualHost *:80>
        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/public
        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined
        <Directory "/var/www/public">
            Options Indexes FollowSymLinks
            AllowOverride all
            Require all granted
        </Directory>
    </VirtualHost>'
    echo "$MY_WEB_CONFIG" | sudo tee /etc/apache2/sites-available/000-default.conf

    # Squash annoying FQDN warning
    echo "ServerName mylamp73" | sudo tee /etc/apache2/conf-available/servername.conf
    sudo a2enconf servername

    # Enabled missing h5bp modules (https://github.com/h5bp/server-configs-apache)
    sudo a2enmod expires
    sudo a2enmod headers
    sudo a2enmod include
    sudo a2enmod rewrite

    sudo service apache2 restart

fi







# /*=====================================
# =            INSTALL NGINX            =
# =====================================*/
if [ $INSTALL_NGINX_INSTEAD == 1 ]; then

    # Install Nginx
    sudo add-apt-repository -y ppa:ondrej/nginx-mainline # Super Latest Version
    sudo apt-get update
    sudo apt-get -y install nginx
    sudo systemctl enable nginx

    # Remove "html" and add public
    mv /var/www/html /var/www/public

    # Make sure your web server knows you did this...
    MY_WEB_CONFIG='server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/public;
        index index.html index.htm index.nginx-debian.html;

        server_name _;

        location = /favicon.ico { access_log off; log_not_found off; }
        location = /robots.txt  { access_log off; log_not_found off; }

        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }
    }'
    echo "$MY_WEB_CONFIG" | sudo tee /etc/nginx/sites-available/default

    sudo systemctl restart nginx

fi








# /*===================================
# =            INSTALL PHP            =
# ===================================*/

# Install PHP
sudo add-apt-repository -y ppa:ondrej/php # Super Latest Version (currently 7.3)
sudo apt-get update
sudo apt-get install -y php7.3

# Make PHP and Apache friends
if [ $INSTALL_NGINX_INSTEAD != 1 ]; then

    sudo apt-get -y install libapache2-mod-php

    # Add index.php to readable file types
    MAKE_PHP_PRIORITY='<IfModule mod_dir.c>
        DirectoryIndex index.php index.html index.cgi index.pl index.xhtml index.htm
    </IfModule>'
    echo "$MAKE_PHP_PRIORITY" | sudo tee /etc/apache2/mods-enabled/dir.conf

    sudo service apache2 restart

fi

# Make PHP and NGINX friends
if [ $INSTALL_NGINX_INSTEAD == 1 ]; then

    # FPM STUFF
    sudo apt-get -y install php7.3-fpm
    sudo systemctl enable php7.3-fpm
    sudo systemctl start php7.3-fpm

    # Fix path FPM setting
    echo 'cgi.fix_pathinfo = 0' | sudo tee -a /etc/php/7.3/fpm/conf.d/user.ini
    sudo systemctl restart php7.3-fpm

    # Add index.php to readable file types and enable PHP FPM since PHP alone won't work
    MY_WEB_CONFIG='server {
        listen 80 default_server;
        listen [::]:80 default_server;

        root /var/www/public;
        index index.php index.html index.htm index.nginx-debian.html;

        server_name _;

        location = /favicon.ico { access_log off; log_not_found off; }
        location = /robots.txt  { access_log off; log_not_found off; }

        location / {
            try_files $uri $uri/ /index.php?$query_string;
        }

        location ~ \.php$ {
            include snippets/fastcgi-php.conf;
            fastcgi_pass unix:/run/php/php7.3-fpm.sock;
        }

        location ~ /\.ht {
            deny all;
        }
    }'
    echo "$MY_WEB_CONFIG" | sudo tee /etc/nginx/sites-available/default

    sudo systemctl restart nginx

fi








# /*===================================
# =            PHP MODULES            =
# ===================================*/

# Base Stuff
sudo apt-get -y install php7.3-common
sudo apt-get -y install php7.3-dev

# Common Useful Stuff (some of these are probably already installed)
sudo apt-get -y install php7.3-bcmath
sudo apt-get -y install php7.3-bz2
sudo apt-get -y install php7.3-cgi
sudo apt-get -y install php7.3-cli
sudo apt-get -y install php7.3-fpm
sudo apt-get -y install php7.3-gd
sudo apt-get -y install php7.3-imap
sudo apt-get -y install php7.3-intl
sudo apt-get -y install php7.3-json
sudo apt-get -y install php7.3-mbstring
sudo apt-get -y install php7.3-mcrypt
sudo apt-get -y install php7.3-odbc
sudo apt-get -y install php-pear
sudo apt-get -y install php7.3-pspell
sudo apt-get -y install php7.3-soap
sudo apt-get -y install php7.3-tidy
sudo apt-get -y install php7.3-xmlrpc
sudo apt-get -y install php7.3-zip

# Enchant
sudo apt-get -y install libenchant-dev
sudo apt-get -y install php7.3-enchant

# LDAP
sudo apt-get -y install ldap-utils
sudo apt-get -y install php7.3-ldap

# CURL
sudo apt-get -y install curl
sudo apt-get -y install php7.3-curl

# IMAGE MAGIC
sudo apt-get -y install imagemagick
sudo apt-get -y install php7.3-imagick

sudo apt -y install php7.0-dev 

sudo apt-get -y install gcc make autoconf libc-dev pkg-config
sudo apt-get -y install libmcrypt-dev
echo yes | sudo pecl install mcrypt-1.0.2

sudo bash -c "echo extension=/usr/lib/php/20180731/mcrypt.so > /etc/php/7.3/cli/conf.d/mcrypt.ini"
sudo bash -c "echo extension=/usr/lib/php/20180731/mcrypt.so > /etc/php/7.3/apache2/conf.d/mcrypt.ini"

# XDEBUG
sudo apt-get -y install php7.3-xdebug
echo "xdebug.remote_enable=true" | sudo tee --append /etc/php/7.3/mods-available/xdebug.ini
echo "xdebug.remote_connect_back=true" | sudo tee --append /etc/php/7.3/mods-available/xdebug.ini
echo "xdebug.idekey=vagrant" | sudo tee --append /etc/php/7.3/mods-available/xdebug.ini




# /*===========================================
# =            CUSTOM PHP SETTINGS            =
# ===========================================*/
if [ $INSTALL_NGINX_INSTEAD == 1 ]; then
    PHP_USER_INI_PATH=/etc/php/7.3/fpm/conf.d/user.ini
else
    PHP_USER_INI_PATH=/etc/php/7.3/apache2/conf.d/user.ini
fi

echo 'display_startup_errors = On' | sudo tee -a $PHP_USER_INI_PATH
echo 'display_errors = On' | sudo tee -a $PHP_USER_INI_PATH
echo 'error_reporting = E_ALL' | sudo tee -a $PHP_USER_INI_PATH
echo 'short_open_tag = On' | sudo tee -a $PHP_USER_INI_PATH
echo 'upload_max_filesize = 128M' | sudo tee -a $PHP_USER_INI_PATH
echo 'post_max_size = 128M' | sudo tee -a $PHP_USER_INI_PATH
reboot_webserver_helper

# Disable PHP Zend OPcache
echo 'opache.enable = 0' | sudo tee -a $PHP_USER_INI_PATH

# Absolutely Force Zend OPcache off...
if [ $INSTALL_NGINX_INSTEAD == 1 ]; then
    sudo sed -i s,\;opcache.enable=0,opcache.enable=0,g /etc/php/7.3/fpm/php.ini
else
    sudo sed -i s,\;opcache.enable=0,opcache.enable=0,g /etc/php/7.3/apache2/php.ini
fi
reboot_webserver_helper







# /*================================
# =            PHP UNIT            =
# ================================*/
sudo wget https://phar.phpunit.de/phpunit-8.phar
sudo chmod +x phpunit-8.phar
sudo mv phpunit-8.phar /usr/local/bin/phpunit
reboot_webserver_helper







# /*=============================
# =            MYSQL            =
# =============================*/ 

export DEBIAN_FRONTEND="noninteractive";
sudo apt-get update
sudo apt-get install -y debconf-utils vim curl
sudo debconf-set-selections <<< 'mysql-apt-config mysql-apt-config/select-server select mysql-8.0'
wget https://repo.mysql.com/mysql-apt-config_0.8.14-1_all.deb
sudo -E dpkg -i mysql-apt-config_0.8.14-1_all.deb
sudo apt-get update
echo "Installing MySQL 8..."
sudo debconf-set-selections <<< 'mysql-community-server mysql-community-server/re-root-pass password root'
sudo debconf-set-selections <<< 'myvsql-community-server mysql-community-server/root-pass password root'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password password root'
sudo debconf-set-selections <<< 'mysql-server mysql-server/root_password_again password root'
sudo -E apt-get -y install mysql-server
sudo mysqladmin -uroot -proot create database
sudo apt-get -y install php7.3-mysql
reboot_webserver_helper

sudo tee -a /etc/mysql/mysql.cnf  <<EOL

[mysqld]
character-set-server=utf8mb4
collation-server = utf8mb4_unicode_ci

EOL

sudo service mysql restart

echo Y | mysqladmin -uroot -proot drop database
sudo mysqladmin -uroot -proot create database

reboot_webserver_helper








# /*=================================
# =            PostreSQL            =
# =================================*/
sudo apt-get -y install postgresql postgresql-contrib
echo "CREATE ROLE root WITH LOGIN ENCRYPTED PASSWORD 'root';" | sudo -i -u postgres psql
sudo -i -u postgres createdb --owner=root database
sudo apt-get -y install php7.3-pgsql
reboot_webserver_helper







# /*==============================
# =            SQLITE            =
# ===============================*/
sudo apt-get -y install sqlite
sudo apt-get -y install php7.3-sqlite3
reboot_webserver_helper







# /*===============================
# =            MONGODB            =
# ===============================*/
sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EA312927
echo "deb http://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.2 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-3.2.list
sudo apt-get update
sudo apt-get install -y mongodb-org

sudo tee /lib/systemd/system/mongod.service  <<EOL
[Unit]
Description=High-performance, schema-free document-oriented database
After=network.target
Documentation=https://docs.mongodb.org/manual

[Service]
User=mongodb
Group=mongodb
ExecStart=/usr/bin/mongod --quiet --config /etc/mongod.conf

[Install]
WantedBy=multi-user.target
EOL
sudo systemctl enable mongod
sudo service mongod start

# Enable it for PHP
sudo pecl install mongodb
sudo apt-get install -y php7.3-mongodb

reboot_webserver_helper














# /*================================
# =            COMPOSER            =
# ================================*/
EXPECTED_SIGNATURE=$(wget -q -O - https://composer.github.io/installer.sig)
php -r "copy('https://getcomposer.org/installer', 'composer-setup.php');"
ACTUAL_SIGNATURE=$(php -r "echo hash_file('SHA384', 'composer-setup.php');")
php composer-setup.php --quiet
rm composer-setup.php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod 755 /usr/local/bin/composer








# /*==================================
# =            BEANSTALKD            =
# ==================================*/
sudo apt-get -y install beanstalkd







# /*==============================
# =            WP-CLI            =
# ==============================*/
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
sudo chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp








# /*=============================
# =            DRUSH            =
# =============================*/
wget -O drush.phar https://github.com/drush-ops/drush-launcher/releases/download/0.5.1/drush.phar
sudo chmod +x drush.phar
sudo mv drush.phar /usr/local/bin/drush








# /*=============================
# =            NGROK            =
# =============================*/
sudo apt-get install ngrok-client








# /*==============================
# =            NODEJS            =
# ==============================*/
sudo apt-get -y install nodejs
sudo apt-get -y install npm

# Use NVM though to make life easy
wget -qO- https://raw.github.com/creationix/nvm/master/install.sh | bash
source ~/.nvm/nvm.sh
nvm install 12.13.1

# Node Packages
sudo npm install -g gulp
sudo npm install -g grunt
sudo npm install -g bower
sudo npm install -g yo
sudo npm install -g browser-sync
sudo npm install -g browserify
sudo npm install -g pm2
sudo npm install -g webpack







# /*============================
# =            YARN            =
# ============================*/
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
sudo apt-get update
sudo apt-get -y install yarn








# /*============================
# =            RUBY            =
# ============================*/
sudo apt-get -y install ruby
sudo apt-get -y install ruby-dev

# Use RVM though to make life easy
gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
\curl -sSL https://get.rvm.io | bash -s stable
source ~/.rvm/scripts/rvm
rvm install 2.5.0
rvm use 2.5.0








# /*=============================
# =            REDIS            =
# =============================*/
sudo apt-get -y install redis-server
sudo apt-get -y install php7.3-redis
reboot_webserver_helper







# /*=================================
# =            MEMCACHED            =
# =================================*/
sudo apt-get -y install memcached
sudo apt-get -y install php7.3-memcached
reboot_webserver_helper








# /*==============================
# =            GOLANG            =
# ==============================*/
sudo add-apt-repository -y ppa:longsleep/golang-backports
sudo apt-get update
sudo apt-get -y install golang-go








# /*===============================
# =            MAILHOG            =
# ===============================*/
sudo wget --quiet -O ~/mailhog https://github.com/mailhog/MailHog/releases/download/v1.0.0/MailHog_linux_amd64
sudo chmod +x ~/mailhog

# Enable and Turn on
sudo tee /etc/systemd/system/mailhog.service <<EOL
[Unit]
Description=MailHog Service
After=network.service vagrant.mount
[Service]
Type=simple
ExecStart=/usr/bin/env /home/vagrant/mailhog > /dev/null 2>&1 &
[Install]
WantedBy=multi-user.target
EOL
sudo systemctl enable mailhog
sudo systemctl start mailhog

# Install Sendmail replacement for MailHog
sudo go get github.com/mailhog/mhsendmail
sudo ln ~/go/bin/mhsendmail /usr/bin/mhsendmail
sudo ln ~/go/bin/mhsendmail /usr/bin/sendmail
sudo ln ~/go/bin/mhsendmail /usr/bin/mail

# Make it work with PHP
if [ $INSTALL_NGINX_INSTEAD == 1 ]; then
    echo 'sendmail_path = /usr/bin/mhsendmail' | sudo tee -a /etc/php/7.3/fpm/conf.d/user.ini
else
    echo 'sendmail_path = /usr/bin/mhsendmail' | sudo tee -a /etc/php/7.3/apache2/conf.d/user.ini
fi

reboot_webserver_helper












# /*=======================================
# =            WELCOME MESSAGE            =
# =======================================*/

# Disable default messages by removing execute privilege
sudo chmod -x /etc/update-motd.d/*

# Set the new message
echo "$WELCOME_MESSAGE" | sudo tee /etc/motd





# /*===================================================
# =            FINAL GOOD MEASURE, WHY NOT            =
# ===================================================*/
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" upgrade
reboot_webserver_helper






# /*====================================
# =            YOU ARE DONE            =
# ====================================*/
echo 'Booooooooom! We are done. You are a hero. I love you.'