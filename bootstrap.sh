#!/usr/bin/env bash

DB_PASSWORD='root'
PROJECT_FOLDER=$1
PROJECT_DOMAIN=$2

# ---------------------------------------
#          Virtual Machine Setup
# ---------------------------------------
export DEBIAN_FRONTEND=noninteractive
echo "Europe/Paris" > /etc/timezone && \
    dpkg-reconfigure -f noninteractive tzdata && \
    sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    sed -i -e 's/# fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/' /etc/locale.gen && \
    echo 'LANG="fr_FR.UTF-8"'>/etc/default/locale && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=fr_FR.UTF-8

sed -i "s/deb http:\/\/deb.debian.org\/debian jessie-updates main*/#deb http:\/\/deb.debian.org\/debian jessie-updates main/" /etc/apt/sources.list
sed -i "s/deb-src http:\/\/deb.debian.org\/debian jessie-updates main*/#deb-src http:\/\/deb.debian.org\/debian jessie-updates main/" /etc/apt/sources.list

apt-get update
apt-get upgrade -y
apt-get install -y apt-transport-https lsb-release ca-certificates software-properties-common curl ntp dirmngr wget

# ---------------------------------------
#          Apache Setup
# ---------------------------------------
echo "---------------------------------------"
echo "Installing Apache and virtual host"
echo "---------------------------------------"

apt-get install -y apache2
a2enmod rewrite

touch /etc/apache2/sites-available/$PROJECT_FOLDER.conf

VHOST=$(cat <<EOF
<VirtualHost *:80>
    ServerName ${PROJECT_DOMAIN}
    DirectoryIndex index.php
    DocumentRoot "/home/vagrant/${PROJECT_FOLDER}/public"
    <Directory "/home/vagrant/${PROJECT_FOLDER}/public">
        AllowOverride None
        Order Allow,Deny
        Allow from All
        Require all granted
        Options FollowSymLinks
        <IfModule mod_rewrite.c>
            Options -MultiViews
            RewriteEngine On
            RewriteCond %{REQUEST_FILENAME} !-f
            RewriteRule ^(.*)$ index.php [QSA,L]
        </IfModule>
    </Directory>
    <Directory "/home/vagrant/${PROJECT_FOLDER}/public/build">
        <IfModule mod_rewrite.c>
            RewriteEngine Off
        </IfModule>
    </Directory>
    ErrorLog "/var/log/apache2/${PROJECT_FOLDER}_error.log"
    CustomLog "/var/log/apache2/${PROJECT_FOLDER}_access.log" combined
</VirtualHost>
EOF
)
echo "${VHOST}" > /etc/apache2/sites-available/$PROJECT_FOLDER.conf
ln -s /etc/apache2/sites-available/$PROJECT_FOLDER.conf /etc/apache2/sites-enabled/$PROJECT_FOLDER.conf

# ---------------------------------------
#          PHP Setup
# ---------------------------------------
echo "---------------------------------------"
echo "Installing PHP"
echo "---------------------------------------"
curl -fsSL https://packages.sury.org/php/apt.gpg | apt-key add -
echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list

apt-get update
apt-get install -y --no-install-recommends php7.3 php7.3-opcache libapache2-mod-php7.3 php7.3-mysql php7.3-curl php7.3-json php7.3-gd php7.3-memcached php7.3-intl php7.3-gmp php7.3-mbstring php7.3-cli php7.3-common php7.3-readline php7.3-xml php7.3-zip

sed -i "s/.*memory_limit.*/memory_limit = 256M/" ${php_ini}
sed -i "s/.*upload_max_filesize.*/upload_max_filesize = 50M/" ${php_ini}
sed -i "s/.*;realpath_cache_size.*/realpath_cache_size=4096K/" ${php_ini}
sed -i "s/.*;realpath_cache_ttl.*/realpath_cache_ttl=600/" ${php_ini}
sed -i "s/.*;opcache.enable.*/opcache.enable=1/" ${php_ini}
sed -i "s/.*;opcache.memory_consumption.*/opcache.memory_consumption=256/" ${php_ini}
sed -i "s/.*;opcache.max_accelerated_files.*/opcache.max_accelerated_files=2000/" ${php_ini}

curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
service apache2 restart

# ---------------------------------------
#          MySQL Setup
# ---------------------------------------
echo "---------------------------------------"
echo "Installing RDBMS"
echo "---------------------------------------"
wget https://dev.mysql.com/get/mysql-apt-config_0.8.14-1_all.deb
debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password $DB_PASSWORD"
debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password $DB_PASSWORD"
debconf-set-selections <<< "mysql-community-server mysql-server/default-auth-override select Use Legacy Authentication Method (Retain MySQL 5.x Compatibility)"

dpkg -i mysql-apt-config_0.8.14-1_all.deb
rm -rf mysql-apt-config_0.8.14-1_all.deb

apt-get update
apt-get install -y mysql-server

sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/my.cnf
mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'root';"

service mysql restart

# ---------------------------------------
#          Tools Setup
# ---------------------------------------
echo "---------------------------------------"
echo "Installing various tools"
echo "---------------------------------------"
apt-get install -y --no-install-recommends vim ntp zip unzip openssl build-essential libssl-dev libxrender-dev libx11-dev libxext-dev libfontconfig1-dev libfreetype6-dev fontconfig

apt-get autoremove

# ---------------------------------------
#          Front Setup
# ---------------------------------------
echo "---------------------------------------"
echo "Installing front tools"
echo "---------------------------------------"
curl -sL https://deb.nodesource.com/setup_10.x | bash -

apt-get install -y nodejs
curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
apt-get update && apt-get install yarn


mkdir -p /var/dev/$PROJECT_FOLDER
chown -R vagrant: /var/dev

echo -e "\n\n---------------------------------------"
echo "Project installed ! Ready to work !"
echo "---------------------------------------"
