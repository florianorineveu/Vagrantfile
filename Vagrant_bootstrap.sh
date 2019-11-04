#!/usr/bin/env bash

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
apt-get install -y apt-transport-https lsb-release ca-certificates software-properties-common curl ntp dirmngr

# ---------------------------------------
#          Apache Setup
# ---------------------------------------
echo "---------------------------------------"
echo "Installing Apache and virtual host"
echo "---------------------------------------"

apt-get install -y apache2
a2enmod rewrite

touch /etc/apache2/sites-available/fnev.devlocal.conf

VHOST=$(cat <<EOF
<VirtualHost *:80>
    ServerName fnev.devlocal
    DirectoryIndex index.php
    DocumentRoot /home/vagrant/fnev.eu/public
    <Directory /home/vagrant/fnev.eu/public>
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
    <Directory /home/vagrant/fnev.eu/public/build>
        <IfModule mod_rewrite.c>
            RewriteEngine Off
        </IfModule>
    </Directory>
    ErrorLog /var/log/apache2/fnev_eu_error.log
    CustomLog /var/log/apache2/fnev_eu_access.log combined
</VirtualHost>
EOF
)
echo "${VHOST}" > /etc/apache2/sites-available/fnev.devlocal.conf
ln -s /etc/apache2/sites-available/fnev.devlocal.conf /etc/apache2/sites-enabled/fnev.devlocal.conf

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

