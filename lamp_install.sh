#!/usr/bin/env bash

# Update system
sudo apt-get -qq update -y

# Install required packages for building from source
sudo apt-get -qq install -y build-essential libtool autoconf bison pkg-config libxml2-dev libpcre2-dev libssl-dev libcurl4-openssl-dev cmake libtool-bin libsqlite3-dev libboost-all-dev librocksdb-dev

expat_ver=2.6.2
expat_ver_under=${expat_ver//./_}
apr_ver=1.7.4
apr_util_ver=1.6.3
pcre2_ver=10.43
apache_ver=2.4.59
ncurses_ver=6.1
mariadb_ver=10.6.17
php_ver=8.3.6

install_path=/opt

# Apache dependencies
#EXPAT
if [ ! -d "$install_path"/expat ] ; then
    wget https://github.com/libexpat/libexpat/releases/download/R_"$expat_ver_under"/expat-"$expat_ver".tar.gz
    tar xzf expat-"$expat_ver".tar.gz
    rm expat-"$expat_ver".tar.gz
    cd expat-"$expat_ver"
    ./configure --prefix="$install_path"/expat
    make -j`nproc`
    sudo make install
    cd ..
    rm -rf expat-"$expat_ver"/
	clear
else 
    echo "expat already installed"
fi

#APR
if [ ! -d "$install_path"/apr ] ; then
    wget https://dlcdn.apache.org//apr/apr-"$apr_ver".tar.gz
    tar xzf apr-"$apr_ver".tar.gz
    rm apr-"$apr_ver".tar.gz
    cd apr-"$apr_ver"/
    ./configure --prefix="$install_path"/apr
    make -j`nproc`
    sudo make install
    cd ..
    rm -rf apr-"$apr_ver"/
	clear
else 
    echo "APR already installed"
fi

#APR-UTIL

if [ ! -d "$install_path"/apr-util ] ; then
    wget https://dlcdn.apache.org//apr/apr-util-"$apr_util_ver".tar.gz
    tar xzf apr-util-"$apr_util_ver".tar.gz
    rm apr-util-"$apr_util_ver".tar.gz
    cd apr-util-"$apr_util_ver"
    ./configure --prefix="$install_path"/apr-util --with-apr="$install_path"/apr -with-expat="$install_path"/expat
    make -j`nproc`
    sudo make install
    cd ..
    rm -rf apr-util-"$apr_util_ver"/
	clear
else
    echo "apr-util already installed"
fi

#PCRE2
if [ ! -d "$install_path"/pcre2 ] ; then
    wget https://github.com/PCRE2Project/pcre2/releases/download/pcre2-"$pcre2_ver"/pcre2-"$pcre2_ver".tar.gz
    tar xzf pcre2-"$pcre2_ver".tar.gz
    rm pcre2-"$pcre2_ver".tar.gz
    cd pcre2-"$pcre2_ver"/
    ./configure --prefix="$install_path"/pcre2
    make -j`nproc`
    sudo make install
    cd .. 
    rm -rf pcre2-"$pcre2_ver"/
	clear
else
    echo "pcre2 alreaddy installed"
fi

# Apache
if [ ! -d "$install_path"/apache ] ; then
    wget https://dlcdn.apache.org/httpd/httpd-"$apache_ver".tar.gz
    tar xzf httpd-"$apache_ver".tar.gz  
    rm httpd-"$apache_ver".tar.gz
    cd httpd-"$apache_ver"
    ./configure --prefix="$install_path"/apache --with-apr="$install_path"/apr --with-apr-util="$install_path"/apr-util --with-pcre="$install_path"/pcre2 --enable-so
    make -j`nproc`
    sudo make install
    cd ..
    rm -rf httpd-"$apache_ver"/
	
    #php test file
    touch info.php
    echo "<?php" >> info.php
    echo "phpinfo();" >> info.php
    echo "?>" >> info.php
	sudo mv ./info.php "$install_path"/apache/htdocs
	
    # something that makes php work on apache
    cp "$install_path"/apache/conf/httpd.conf .
    echo "<FilesMatch \.php$>" >> httpd.conf
    echo -e "\tSetHandler application/x-httpd-php" >> httpd.conf
    echo "</FilesMatch>" >> httpd.conf
	sudo mv ./httpd.conf "$install_path"/apache/conf/
	
    #cd /lib/systemd/system/
	touch apache.service
    echo "[Unit]" >> apache.service
    echo "Description=The Apache HTTP Server" >> apache.service
    echo "After=network.target" >> apache.service
    echo "[Service]" >> apache.service
    echo "Type=forking" >> apache.service
	#sudo echo "ExecStart=" >> apache.service
    echo "ExecStart="$install_path"/apache/bin/apachectl start" >> apache.service
    echo "ExecStop="$install_path"/apache/bin/apachectl stop" >> apache.service
    echo "ExecReload="$install_path"/apache/bin/apachectl graceful" >> apache.service
    echo "TimeoutSec=10" >> apache.service
    echo "PrivateTmp=true" >> apache.service
    echo "[Install]" >> apache.service
    echo "WantedBy=multi-user.target" >> apache.service
    sudo mv ./apache.service /lib/systemd/system/ 
    sudo systemctl enable apache
    sudo systemctl daemon-reload
    sudo systemctl start apache
	clear
else
    echo "apache already installed"
fi



#start apache on boot

# MariaDB dependencies
#NCURSES
if [ ! -d "$install_path"/ncurses ] ; then
    wget https://invisible-mirror.net/archives/ncurses/ncurses-"$ncurses_ver".tar.gz
    tar xzf ncurses-"$ncurses_ver".tar.gz 
    rm ncurses-"$ncurses_ver".tar.gz
    cd ncurses-"$ncurses_ver"/
    ./configure --prefix="$install_path"/ncurses
    make -j`nproc`
    sudo make install
    cd ..
    rm -rf ncurses-"$ncurses_ver"/
	clear
else
    echo "ncurses already installed"
fi

# MariaDB
if [ ! -d "$install_path"/mariadb ] ; then
    wget https://mariadb.mirror.serveriai.lt/mariadb-"$mariadb_ver"/source/mariadb-"$mariadb_ver".tar.gz
    tar xzf mariadb-"$mariadb_ver".tar.gz 
    rm mariadb-"$mariadb_ver".tar.gz
    cd mariadb-"$mariadb_ver"
    sudo apt -qq build-dep -y mariadb-server
    cmake . -DCMAKE_INSTALL_PREFIX:PATH="$install_path"/mariadb -DCMAKE_INCLUDE_PATH="$install_path"/ncurses/include -DCMAKE_LIBRARY_PATH="$install_path"/ncurses/lib
    make -j`nproc`
    sudo make install
    cd ..
    rm -rf mariadb-"$mariadb_ver"/
    #setup MariaDB and run on boot
    sudo groupadd mysql
    sudo useradd -g mysql mysql
    touch my.cnf
    echo "[mysqld]" >> my.cnf 
    echo "datadir="$install_path"/mariadb/data" >> my.cnf
    echo "socket=/var/run/mysqld/mysqld.sock" >> my.cnf
    echo "user=mysql" >>my.cnf
    sudo mv ./my.cnf "$install_path"/mariadb 
    sudo "$install_path"/mariadb/scripts/mariadb-install-db --basedir="$install_path"/mariadb --user=mysql --datadir=/opt/mariadb/data
    sudo cp "$install_path"/mariadb/support-files/systemd/mariadb.service /lib/systemd/system/
    sudo chown -R mysql:mysql /opt/mariadb
    sudo chgrp -R mysql /opt/mariadb
    sudo systemctl enable mariadb.service
    sudo systemctl daemon-reload
    sudo systemctl start mariadb.service
	clear
else 
    echo "MariaDB already installed"
fi


# PHP
if [ ! -d "$install_path"/php ] ; then
    wget https://www.php.net/distributions/php-"$php_ver".tar.gz
    tar xzf php-"$php_ver".tar.gz 
    rm php-"$php_ver".tar.gz
    cd php-"$php_ver"
    ./configure --prefix="$install_path"/php --with-apxs2="$install_path"/apache/bin/apxs --with-pdo-mysql
    make -j`nproc`
    sudo make install
    sudo cp php.ini-development "$install_path"/php/lib/php.ini
    libtool --finish /home/ubunutu/php-"$php_ver"/libs
    cd ..
    rm -rf php-"$php_ver"
	clear
else
    echo "PHP already installed"
fi

sudo systemctl restart apache
sudo systemctl restart mariadb

wget -q localhost/info.php
cat info.php | grep -q "PHP License"
if [ $? -eq 0 ] ; then
    echo "Apache is working with PHP"
else
    echo "Apache isn't executing PHP files"
fi
rm info.php

"$install_path"/mariadb/bin/mysqladmin ping | grep -q "mysqld is alive"
if [ $? -eq 0 ] ; then
    echo "MariaDB is up and running"
else
    echo "Mariadb is not running"
fi

echo "MariaDB installed in "$install_path"/mariadb database dir is "$install_path"/mariadb/data."
echo "Created user mysql to access MariaDB"
echo "Apache server installed in "$install_path"/apache and configured to work with php."
echo "To check you can visit localhost/info.php to check"
echo -e "PHP installed in "$install_path"/php\n"
echo "MariaDB and Apache server starts at boot time"

