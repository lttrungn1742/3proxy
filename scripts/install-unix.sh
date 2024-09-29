#!/bin/sh
cd ..
cp Makefile.unix Makefile
make
if [ ! -d /usr/local/etc/nginx/bin ]; then mkdir -p /usr/local/etc/nginx/bin/; fi
install bin/nginx /usr/local/bin/nginx
install bin/mycrypt /usr/local/bin/mycrypt
install scripts/rc.d/http.sh /usr/local/etc/rc.d/http.sh
install scripts/addnginxuser.sh /usr/local/etc/nginx/bin/
if [ -s /usr/local/etc/nginx/nginx.cfg ]; then
 echo /usr/local/etc/nginx/nginx.cfg already exists
else
 install scripts/nginx.cfg /usr/local/etc/nginx/
 if [ ! -d /var/log/nginx/ ]; then
  mkdir /var/log/nginx/
 fi
 touch /usr/local/etc/nginx/passwd
 touch /usr/local/etc/nginx/counters
 touch /usr/local/etc/nginx/bandlimiters
 echo Run /usr/local/etc/nginx/bin/addnginxuser.sh to add \'admin\' user
fi

