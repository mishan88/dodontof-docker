#!/bin/sh
set -e

DB=dodontof
DBUSER=dodontof

echo generate DB password
if [ -z "$DBPASS" ]; then
  if [ -f /var/lib/mysql/.dbcreated ]; then
    . /var/lib/mysql/.dbcreated
  fi
  if [ -z "$DBPASS" ]; then
    DBPASS=$(openssl rand -hex 16)
    echo "DBPASS=\"$DBPASS\"" >> /var/lib/mysql/.dbcreated
  fi
fi

if [ -z "$MENTENANCEPASS" ]; then
  if [ -f /var/lib/mysql/.dbcreated ]; then
    . /var/lib/mysql/.dbcreated
  fi
  if [ -z "$MENTENANCEPASS" ]; then
    MENTENANCEPASS=$(openssl rand -hex 16)
    echo "MENTENANCEPASS=\"$MENTENANCEPASS\"" >> /var/lib/mysql/.dbcreated
  fi
fi

echo "DBPASS=$DBPASS"
echo "MENTENANCEPASS=$MENTENANCEPASS"

sed -e 's/!!!DBPASS!!!/'"$DBPASS"'/g' \
    -e 's/!!!MENTENANCEPASS!!!/'"$MENTENANCEPASS"'/g' \
    /var/www/html/src_ruby/config.rb.in >/var/www/html/src_ruby/config.rb

echo start mysqld
/usr/sbin/mysqld &

sleep 5

if [ -z "$DBSETUPED" ]; then
  echo "setup ${DB} database"
  mysql <<EOS
CREATE USER '${DBUSER}'@'localhost' IDENTIFIED BY '${DBPASS}';
CREATE DATABASE ${DB};
GRANT ALL ON ${DB}.* TO '${DBUSER}'@'localhost';
EOS
  echo "DBSETUPED=1" >> /var/lib/mysql/.dbcreated
else
  echo "DB:$DB is already created"
fi

echo "start fcgi"
/usr/bin/spawn-fcgi -u www-data -d /var/www/html/ -f /var/www/dodontoF-fcgi.rb -s /run/dodontof.sock -P /run/dodontof.pid -F 10
echo "start nginx"
/usr/sbin/nginx -g 'daemon off;'
