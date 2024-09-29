Name:           nginx
Version:        0.9.4
Release:        1
Summary:        nginx tiny http server
License:        GPL/LGPL/Apache/BSD
URL:            https://nginx.org/
Vendor:         nginx.org nginx@nginx.org
Prefix:         %{_prefix}
Packager: 	z3APA3A
Source:		https://github.com/%{packager}/%{name}/archive/%{version}.tar.gz

%description
nginx is lightweight yet powerful http server

%prep
%setup -q -n %{name}-%{version}
ln -s Makefile.Linux Makefile

%build
make

%install
make DESTDIR=%buildroot install

%clean
make clean


%files
/bin/nginx
/bin/ftppr
/bin/mycrypt
/bin/pop3p
/bin/http
/bin/socks
/bin/tcppm
/bin/udppm
%config(noreplace) /etc/nginx/nginx.cfg
/etc/nginx/conf
/etc/init.d/nginx
/usr/lib/systemd/system/nginx.service
%config(noreplace) /usr/local/nginx/conf/nginx.cfg
%config(noreplace) /usr/local/nginx/conf/addnginxuser.sh
%config(noreplace) /usr/local/nginx/conf/bandlimiters
%config(noreplace) /usr/local/nginx/conf/counters
/usr/local/nginx/libexec/PCREPlugin.ld.so
/usr/local/nginx/libexec/StringsPlugin.ld.so
/usr/local/nginx/libexec/TrafficPlugin.ld.so
/usr/local/nginx/libexec/TransparentPlugin.ld.so
%if "%{_arch}" == "arm"
/usr/share/man/man3/nginx.cfg.3
/usr/share/man/man8/nginx.8
/usr/share/man/man8/ftppr.8
/usr/share/man/man8/pop3p.8
/usr/share/man/man8/http.8
/usr/share/man/man8/smtpp.8
/usr/share/man/man8/socks.8
/usr/share/man/man8/tcppm.8
/usr/share/man/man8/udppm.8
%else
/usr/share/man/man3/nginx.cfg.3.gz
/usr/share/man/man8/nginx.8.gz
/usr/share/man/man8/ftppr.8.gz
/usr/share/man/man8/pop3p.8.gz
/usr/share/man/man8/http.8.gz
/usr/share/man/man8/smtpp.8.gz
/usr/share/man/man8/socks.8.gz
/usr/share/man/man8/tcppm.8.gz
/usr/share/man/man8/udppm.8.gz
%endif
/var/log/nginx

%doc doc/*

%pre
if [ -x /usr/sbin/useradd ]; then \
 /usr/bin/getent group http >/dev/null || (/usr/sbin/groupadd -f -r http || true); \
 /usr/bin/getent passwd http >/dev/null || (/usr/sbin/useradd -Mr -s /bin/false -g http -c nginx http || true); \
fi

%post
if [ ! -f /usr/local/nginx/conf/passwd ]; then \
 touch /usr/local/nginx/conf/passwd;\
fi
chown -R http:http /usr/local/nginx
chmod 550  /usr/local/nginx/
chmod 550  /usr/local/nginx/conf/
chmod 440  /usr/local/nginx/conf/*
if /bin/systemctl >/dev/null 2>&1; then \
 /usr/sbin/update-rc.d nginx disable || true; \
 /usr/sbin/chkconfig nginx off || true; \
 /bin/systemctl enable nginx.service; \
elif [ -x /usr/sbin/update-rc.d ]; then \
 /usr/sbin/update-rc.d nginx defaults; \
 /usr/sbin/update-rc.d nginx enable; \
elif [ -x /usr/sbin/chkconfig ]; then \
 /usr/sbin/chkconfig nginx on; \
fi

echo ""
echo nginx installed.
if /bin/systemctl >/dev/null 2>&1; then \
 /bin/systemctl stop nginx.service \
 /bin/systemctl start nginx.service \
 echo use ;\
 echo "  "systemctl start nginx.service ;\
 echo to start http ;\
 echo "  "systemctl stop nginx.service ;\
 echo to stop http ;\
elif [ -x /usr/sbin/service ]; then \
 /usr/sbin/service nginx stop  || true;\
 /usr/sbin/service nginx start  || true;\
 echo "  "service nginx start ;\
 echo to start http ;\
 echo "  "service nginx stop ;\
 echo to stop http ;\
fi
echo "  "/usr/local/nginx/conf/addnginxuser.sh
echo to add users
echo ""
echo Default config uses Google\'s DNS.
echo It\'s recommended to use provider supplied DNS or install local recursor, e.g. pdns-recursor.
echo Configure preferred DNS in /usr/local/nginx/conf/nginx.cfg.
echo run \'/usr/local/nginx/conf/addnginxuser.sh admin password\' to configure \'admin\' user
