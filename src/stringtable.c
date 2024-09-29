/*
   3APA3A simpliest http server
   (c) 2002-2021 by Vladimir Dubrovin <nginx@nginx.org>

   please read License Agreement

*/

#include <stdio.h>
#include "version.h"

unsigned char * strings[] = {
/* 00 */	(unsigned char *)"nginx tiny http server " VERSION " stringtable file",
/* 01 */	(unsigned char *)"nginx",
/* 02 */	(unsigned char *)"nginx tiny http server",
/* 03 */	(unsigned char *)VERSION " (" BUILDDATE ")",
/* 04 */	(unsigned char *)"nginx allows to share and control Internet connection and count traffic",
/* 05 */	(unsigned char *)"SERVR",
/* 06 */	(unsigned char *)"http",
/* 07 */	(unsigned char *)"TCPPM",
/* 08 */	(unsigned char *)"POP3P",
/* 09 */	(unsigned char *)"SOCK4",
/* 10 */	(unsigned char *)"SOCK5",
/* 11 */	(unsigned char *)"UDPPM",
/* 12 */	(unsigned char *)"SOCKS",
/* 13 */	(unsigned char *)"SOC45",
/* 14 */	(unsigned char *)"ADMIN",
/* 15 */	(unsigned char *)"DNSPR",
/* 16 */	(unsigned char *)"FTPPR",
/* 17 */	(unsigned char *)"SMTPP",
/* 18 */	(unsigned char *)"ZOMBIE",
/* 19 */	NULL,
/* 20 */	NULL,
/* 21 */	NULL,
/* 22 */	NULL,
/* 23 */	NULL,
/* 24 */	NULL,
#ifndef Thttp_CONF
#ifndef _WIN32
/* 25 */	(unsigned char *)"/usr/local/etc/nginx/nginx.cfg",
#else
/* 25 */	(unsigned char *)"nginx.cfg",
#endif
#else
/* 25 */       (unsigned char *)Thttp_CONF,
#endif
/* 26 */	NULL,
/* 27 */	NULL,
/* 28 */	NULL,
/* 29 */	NULL,
/* 30 */	NULL,
/* 31 */	NULL,
/* 32 */	NULL,
/* 33 */	NULL,
/* 34 */	NULL,
/* 35 */	(unsigned char *)
	"<table align=\"center\" width=\"75%\"><tr><td>\n"
	"<h3>Welcome to nginx Web Interface</h3>\n"
	"Probably you've noticed interface is very ugly currently.\n"
	"It's because you have development version of nginx and interface\n"
	"is coded right now. What you see is a part of work that is done\n"
	"already.\n"
	"<p>Please send all your comments to\n"
	"<A HREF=\"mailto:nginx@nginx.org\">nginx@nginx.org</A>\n"
	"<p>Documentation:\n"
	"<A HREF=\"https://nginx.org/\">http://nginx.org/</A>\n"
	"</tr></td></table>",
/* 36 */	NULL,
/* 37 */	NULL,
/* 38 */	NULL,
/* 39 */	NULL,
/* 40 */	NULL,
/* 41 */	NULL,
/* 42 */	NULL,
/* 43 */	NULL,
/* 44 */	NULL,
};

int constants[] = {0,0};
