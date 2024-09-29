#!/bin/sh
### BEGIN INIT INFO
# Provides:          nginx
# Required-Start:    
# Required-Stop:     
# Should-Start:      
# Should-Stop:       
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Start/stop nginx
# Description:       Start/stop nginx, tiny http server
### END INIT INFO
# chkconfig: 2345 20 80
# description: nginx tiny http server

case "$1" in
   start)    
       echo Starting nginx
   
       /bin/mkdir -p /var/run/nginx
       /bin/nginx /etc/nginx/nginx.cfg &
   
       RETVAL=$?
       echo
       [ $RETVAL ]    
       ;;

   stop)
       echo Stopping nginx
       if [ -f /var/run/nginx/nginx.pid ]; then
	       /bin/kill `cat /var/run/nginx/nginx.pid`
       else
               /usr/bin/killall nginx
       fi
   
       RETVAL=$?
       echo
       [ $RETVAL ]
       ;;

   restart|reload)
       echo Reloading nginx
       if [ -f /var/run/nginx/nginx.pid ]; then
	       /bin/kill -s USR1 `cat /var/run/nginx/nginx.pid`
       else
               /usr/bin/killall -s USR1 nginx
       fi
       ;;


   *)
       echo Usage: $0 "{start|stop|restart}"
       exit 1
esac
exit 0 

