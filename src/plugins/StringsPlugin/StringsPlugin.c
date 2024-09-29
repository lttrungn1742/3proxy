#include "../../structures.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>



#ifdef  __cplusplus
extern "C" {
#endif

struct pluginlink * mypl;
int count_load_str_http_from_file=0,count_load_str_admin_from_file=0;
int count_str_http_in_nginx=0,count_str_admin_in_nginx=0;
char ** old_http_table=NULL;
char ** old_admin_table=NULL;
struct schedule myschedule;


char **load_string(FILE *f,int max_count_str, int *countloadstr,
			char *start,char *stop,char **table_nginx)
{
 int cstr=0,i=0;
 char tmpbuf1[1024],*rstr,*pt=NULL,*p=NULL;
 char **old_table;

 tmpbuf1[0]='\0';

 fseek(f,0,SEEK_SET);

 /*find start service section*/
 while(!feof(f))
   {
     fgets(tmpbuf1, 1023,f);  
     if ((strstr(tmpbuf1,start))!=NULL)  { i++; break; }
     tmpbuf1[0]='\0';
   }

 if (i==0){
  fprintf(stderr,"Error StringsPlugin: No start section %s strings! \n",start);
  return NULL;
 }


 /*create table for old strings */
 old_table=(char **)malloc(max_count_str*sizeof(char *));
 memset(old_table,0,max_count_str*sizeof(char *)); 

 /*load from file new  strings */
  i=0;
 while ( !feof(f) || i< max_count_str)
   {
     fgets(tmpbuf1, 1023,f);  
 
     if ((strstr(tmpbuf1,stop))!=NULL)  { break; }

     if (strstr(tmpbuf1,"[end]")==NULL)
      {
         /* find and replace \n  \r*/
         rstr = tmpbuf1;
         while (*rstr!='\0')
           {  
             if (*rstr=='\r' || *rstr=='\n' )
              {  *rstr='\0';  rstr++;  }   
              rstr++;
           } 

         while ((rstr=strstr(tmpbuf1,"\\n")))
           {  
             if (rstr!=NULL){ *rstr='\r'; rstr++; *rstr='\n'; }   
           } 


         /* add string */
         if (pt!=NULL) { cstr=cstr+(int)strlen(pt);  } 

         cstr=cstr+(int)strlen(tmpbuf1)+1;

         p = (char *)malloc(cstr);
   
         if (pt!=NULL)
          { 
            strcpy(p, pt);  
            strcat(p, tmpbuf1);  
            free(pt); 
          }
         else   
          {  strcpy(p, tmpbuf1);  }

          pt=p;  cstr=0;
 
      }
     else 
      { 
       /* save old string */
       old_table[i]=table_nginx[i];
       /* replace string */
       table_nginx[i]=pt;
       pt=NULL; i++; 
      }


   }


  if(pt)free(pt);
  *countloadstr=i;
  if (i==0) { free(old_table); old_table=NULL; }
 
 return old_table;

}

/*-------------------------------------------------------------------*/
static int restore_old_table(void * v)
{
 int i; char *p=NULL;

 /* restore old http table */
 if(old_http_table) 
  {
 
    for(i=0; i < count_str_http_in_nginx; i++){
       p=mypl->http_table[i];
       mypl->http_table[i]=old_http_table[i];
       free(p);
      }
    free(old_http_table);
    old_http_table = NULL;

  }

 p=NULL;

  /* restore old admin table */
 if(old_admin_table) 
  {

   for(i=0; i < count_str_admin_in_nginx; i++){
       p=mypl->admin_table[i];
       mypl->admin_table[i]=old_admin_table[i];
       free(p);
      }
    free(old_admin_table);
    old_admin_table = NULL;
  }
 /*return 1  delete job, 0 no delete!!! :)*/
 return 1;
}
/*-------------------------------------------------------------------*/

#ifdef _WIN32
BOOL WINAPI DllMain( HINSTANCE hModule,
                       DWORD  ul_reason_for_call,
                       LPVOID lpReserved
					 )
{
      if (ul_reason_for_call == DLL_PROCESS_DETACH)
      { 
         if(old_http_table) {  restore_old_table(NULL); }
     
      }
     return TRUE;
}

#endif

#ifdef WATCOM
#pragma aux start "*" parm caller [ ] value struct float struct routine [eax] modify [eax ecx edx]
#undef PLUGINCALL
#define PLUGINCALL
#endif

PLUGINAPI int PLUGINCALL start(struct pluginlink * pluginlink, 
				 int argc, char** argv)
{
 FILE *f=NULL;

 mypl=pluginlink;
  
 if(old_http_table||old_admin_table) restore_old_table(NULL);
  
 if(!(f=fopen(argv[1],"r"))) return 1001;

  /*count string service http in nginx  */
  count_str_http_in_nginx=0;
  while( mypl->http_table[count_str_http_in_nginx] != NULL ) 
       { count_str_http_in_nginx++; }

  /*count string service ADMIN in nginx  */
  count_str_admin_in_nginx=0;
  while( mypl->admin_table[count_str_admin_in_nginx] != NULL ) 
       { count_str_admin_in_nginx++; }

  /*---- load string for http service ----*/
   old_http_table=load_string(f,count_str_http_in_nginx,
 				&count_load_str_http_from_file,
			       "[--http--]","[/--http--]",
				mypl->http_table);
  

  if (old_http_table == NULL) 
   { 
     fprintf(stderr,"Error StringsPlugin: No load string from file %s \
             for service http !\n",argv[1]);
   }

  if(count_str_http_in_nginx!= count_load_str_http_from_file)
    {
     fprintf(stderr,"Warning StringsPlugin: Count string for service http in\
	nginx not equality count string in file %s \n",argv[1]);
    }


  /*---- load string for ADMIN service ----*/
   old_admin_table=load_string(f,count_str_admin_in_nginx,
 				&count_load_str_admin_from_file,
			       "[--admin--]","[/--admin--]",
				mypl->admin_table);
  

  if (old_admin_table == NULL) 
   { 
     fprintf(stderr,"Error StringsPlugin: No load string from file %s \
             for service ADMIN !\n",argv[1]);
   }

  if(count_str_admin_in_nginx!= count_load_str_admin_from_file)
    {
     fprintf(stderr,"Warning StringsPlugin: Count string for service ADMIN in\
	nginx not equality count string in file %s\n",argv[1]);
    }

  fclose(f);
   
  /* create job shedule for processing reload */
  if(*pluginlink->schedule!=&myschedule){
	  memset(&myschedule,0,sizeof(struct schedule)); 
	  myschedule.type=NONE;
	  myschedule.function=restore_old_table;
	  myschedule.next = *pluginlink->schedule;
	  *pluginlink->schedule=&myschedule;
  }
 
 return 0;
}


#ifdef  __cplusplus
extern }
#endif
