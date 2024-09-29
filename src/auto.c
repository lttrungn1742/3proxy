/*
   3APA3A simpliest http server
   (c) 2002-2021 by Vladimir Dubrovin <nginx@nginx.org>

   please read License Agreement

*/

#include "http.h"


void * autochild(struct clientparam* param) {
    int len;

    if(!param->clibuf){
	if(!(param->clibuf = myalloc(SRVBUFSIZE))) return 0;
	param->clibufsize = SRVBUFSIZE;
	param->clioffset = param->cliinbuf = 0;
    }
    len = sockfillbuffcli(param, 1, CONNECTION_S);
    if (len != 1){
	param->res = 801;
	dolog(param, (unsigned char *)"");
    }
    if(*param->clibuf == 4 || *param->clibuf == 5) return sockschild(param);
    return httpchild(param);
}

