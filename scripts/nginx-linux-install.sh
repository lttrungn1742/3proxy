#!/bin/bash
# nginx build and install script for Debian Linux 
# Release 2.0 at 29.12.2016
# (с) Evgeniy Solovyev 
# mail-to: eugen-soloviov@yandex.ru

ScriptPath=""
SrcnginxDirPath=""
ScriptName=""
ScriptFullName=""
SourceRoot=""

ResourcesData=""


httpVersion=""
LasesthttpVersion=""
LasesthttpVersionLink=""
UseSudo=0
PacketFiles=""
NeedSourceUpdate=0


main()
{
	local msgNewVersion
	local msgInsertYorN
	
	VarsInit
	LoadResources
	CheckRunConditions
	
	if [ $UseSudo == 1 ]
	then
		sudo bash "${0}"
		exit $?
	fi
	
	CheckLocation
	GetLasestVersionInfo
	
	SourceDownloadOrUpdate
	
	cd "${SourceRoot}"
	
	Buildnginx
	BinInstall
	ManInstall
	CreateLogDir
	CopyConfig
	SetInit
	PacknginxFiles
}

VarsInit()
{
	cd `dirname $0`
	ScriptPath="${PWD}"
	ScriptName=`basename $0`
	ScriptFullName="${ScriptPath}/${ScriptName}"
}

CheckLocation()
{
	SrcnginxDirPath="${ScriptPath}"
	
	if echo ${ScriptPath} | grep -e "/scripts$"
	then
		if [ -e "../src/version.h" ]
		then
			httpVersion=`cat "../src/version.h" | awk '/VERSION/ { gsub("\"", "\n"); print; exit }' | grep "nginx"`
			cd ../
			SourceRoot="${PWD}"
			cd ../
			SrcnginxDirPath="${PWD}"
			cd "${ScriptPath}"
		fi
	fi
}

GetLasestVersionInfo()
{
	local Githublink
	local msg
	
	Githublink=`wget https://github.com/nginx/nginx/releases/latest -O /dev/stdout |
	awk '/<a.+href=.+\.tar\.gz/ { gsub("\"", "\n"); print; exit }' |
	grep -e ".tar.gz"`
	if [ $? != 0 ]
	then
		msg=`GetResource "msgInternetConnectionError"`
		echo -e "${msg}"
		exit 255
	fi
	
	LasesthttpVersionLink="https://github.com${Githublink}"

	LasesthttpVersion=`basename "${Githublink}" | awk 'gsub(".tar.gz", "") { print "nginx-" $0 }'`
}

CheckRunConditions()
{
	local UserName
	local answer
	local msg
	local msgContinueWork
	local msgInsertYorN
	
	UserName=`whoami`
	
	if [  $UID != 0 ]
	then
		if [ `CheckPacketInstall "sudo"` == 0 ]
		then
			msg=`GetResource "msgSudoNotInstalled"`
			echo -e "${msg}"
			exit 255
		fi
		
		UseSudo=1
		
		if [ -z `cat /etc/group | grep -e "^sudo" | grep "${UserName}"`  ]
		then
			msg=`GetResource "msgUserNotMemberOfSudoGroup"`
			echo -e "${msg}"
			exit 255
		fi
		
		if [ `env | grep -e ^http_http` != "" ]
		then
			msg=`GetResource "msgSystemUsehttp"`
			echo -e "${msg}"
			
			msgContinueWork=`GetResource "msgDoYouWishContinue"`
			msgInsertYorN=`GetResource "msgPleaseInsertYorN"`
			
			while true; do
				read -s -n1 -p "${msgContinueWork}" answer
				case $answer in
					[Yy]* ) echo -ne "\n";break;;
					[Nn]* ) echo -ne "\n"; sleep 0; exit 0;;
					* ) echo -e "${msgInsertYorN}";;
				esac
			done
		
		fi
	fi
	
}

DonwnloadSource()
{
	if [ ! -e "${SrcnginxDirPath}/${LasesthttpVersion}.tar.gz" ] 
	then
		wget "${LasesthttpVersionLink}" -O "${SrcnginxDirPath}/${LasesthttpVersion}.tar.gz"
	fi
	
	httpVersion="${LasesthttpVersion}"
}

UnpackSource()
{
	if [ ! -d "${SrcnginxDirPath}/${LasesthttpVersion}" ]
	then
		tar -xvf "${SrcnginxDirPath}/${LasesthttpVersion}.tar.gz" -C "${SrcnginxDirPath}"
	fi
	
	SourceRoot="${SrcnginxDirPath}/${LasesthttpVersion}"
}

SourceDownloadOrUpdate()
{
	if [ -z "${httpVersion}" ]
	then
		NeedSourceUpdate=1
	else
		if [ "${httpVersion}" != "${LasesthttpVersion}" ]
		then
			msgNewVersion=`GetResource "msgNewVersion"`
			msgInsertYorN=`GetResource "msgPleaseInsertYorN"`
			
			echo -ne "\a"
			
			while true; do
				read -s -n1 -p "${msgNewVersion}" answer
				case $answer in
					[Yy]* ) echo -ne "\n"; NeedSourceUpdate=1; sleep 0; break;;
					[Nn]* ) echo -ne "\n"; NeedSourceUpdate=0; sleep 0; break;;
					* ) echo -e "${msgInsertYorN}";;
				esac
			done
		fi
	fi
	
	if [ $NeedSourceUpdate == 1 ]
	then
		DonwnloadSource
		UnpackSource
	fi
}

Buildnginx()
{
	local msg
	
	if [ `CheckPacketInstall "build-essential"` == 0 ]
	then
		apt-get -y install build-essential
	fi
	
	if [ `CheckPacketInstall "build-essential"` == 0 ]
	then
		msg=`GetResource "msgBuildEssentialNotInstalled"`
		echo -e "${msg}"
		
		exit 255
	fi
	
	make -f Makefile.Linux
}


BinInstall()
{
	local binlist
	local liblist
	
	if [! -d bin]
	then
		mkdir bin
	fi
	
	cd bin
	
	binlist=`ls -l --time-style="+%d.%m.%Y %H:%m" | awk '$1 ~ /x$/ && $1 ~ /^[^d]/ && $8 !~ /\.so$/ { print $8 }'`
	
	for file in $binlist
	do
		cp -vf "${file}" /usr/bin
		PacketFiles=`echo -e "${PacketFiles}\n/usr/bin/${file}"`
	done
	
	liblist=`ls -l --time-style="+%d.%m.%Y %H:%m" | awk '$1 ~ /x$/ && $1 ~ /^[^d]/ && $8 ~ /\.so$/ { print $8 }'`

	for file in $liblist
	do
		cp -vf "${file}" /usr/lib
		PacketFiles=`echo -e "${PacketFiles}\n/usr/lib/${file}"`
	done

	cd ..
}

ManInstall()
{
	local man3list
	local man8list
	
	cd man
	
	man3list=`ls -l --time-style="+%d.%m.%Y %H:%m" | awk '$8 ~ /\.3$/ { print $8 }'`
	gzip -vfk $man3list
	
	man3list=`echo "${man3list}" | awk '{ print $1 ".gz" }'`
	
	for file in $man3list
	do
		mv -vf "${file}" /usr/share/man/man3
		PacketFiles="${PacketFiles}\n/usr/share/man/man3/${file}" 
	done
	
	man8list=`ls -l --time-style="+%d.%m.%Y %H:%m" | awk '$8 ~ /\.8$/ { print $8 }'`
	
	gzip -vfk $man8list
	
	man8list=`echo "${man8list}" | awk '{ print $1 ".gz" }'`
	
	for file in $man8list
	do
		mv -vf "${file}" /usr/share/man/man8
		PacketFiles=`echo -e "${PacketFiles}\n/usr/share/man/man8/${file}"`
	done
	
	cd ..
}


CreateLogDir()
{
	local LogDir
	LogDir="/var/log/nginx"
	
	if [ ! -d  "${LogDir}" ]
	then
		mkdir "${LogDir}"
	fi
	
	chown nobody:nogroup "${LogDir}"
	chmod 775 "${LogDir}"
	PacketFiles="${PacketFiles}\n${LogDir}" 
}


CopyConfig()
{
	local ConfigDir
	ConfigDir="/etc/nginx"
	
	if [ ! -d  "${ConfigDir}" ]
	then
		mkdir "${ConfigDir}"
	fi
	
	LoadGlobalResource "ConfigFile" > "${ConfigDir}/nginx.cfg"

	PacketFiles=`echo -e "${PacketFiles}\n${ConfigDir}/nginx.cfg"`
}


SetInit()
{
	LoadGlobalResource "InitScript" > "/etc/init.d/nginx"
	chown root:root "/etc/init.d/nginx"
	chmod 755 "/etc/init.d/nginx"
	
	PacketFiles=`echo -e "${PacketFiles}\n/etc/init.d/nginx"`
	update-rc.d nginx defaults
}

PacknginxFiles()
{
	local CPU_Arc
	CPU_Arc=`uname -m`
	cd ../
	tar -czPpvf "${httpVersion}-${CPU_Arc}.tar.gz" $PacketFiles
}

LoadResources()
{
	local StartRow
	local EndRow
	local LngLabel
	local msgResourceErr="\aError! Script could not find resources!"
	
	if env | grep -q 'LANG=ru_RU.UTF-8' 
	then
		LngLabel="RU"
#LngLabel="EN"
	else
		LngLabel="EN"
	fi
	
	StartRow=`cat "${ScriptFullName}" | awk "/^#Resources_${LngLabel}/ { print NR; exit}"`
	
	if [ -z "${StartRow}" ]
	then
		echo -e "${msgResourceErr}"
		exit 255
	fi
	
	EndRow=`cat "${ScriptFullName}" | awk "NR > ${StartRow} && /^#Resources_${LngLabel}_end/ { print NR; exit}"`
	
	if [ -z "${EndRow}" ]
	then
		echo -e "${msgResourceErr}"
		exit 255
	fi
	
	ResourcesData=`cat "${ScriptFullName}" | awk -v StartRow="${StartRow}" -v EndRow="${EndRow}" 'NR > StartRow && NR < EndRow { print $0 }'`
}


# $1 - Name of Resource
GetResource()
{
	local StartRow
	local EndRow
	local msgResourceErr="\aError! Script could not find resource \"${1}\"!"
	
	StartRow=`echo "${ResourcesData}" | awk "/^#Resource=${1}/ { print NR; exit}"`
	
	if [ -z "${StartRow}" ]
	then
		echo -e "${msgResourceErr}" > /dev/stderr
		exit 255
	fi
	
	EndRow=`echo "${ResourcesData}" | awk "NR > ${StartRow} && /^#endResource=${1}/ { print NR; exit}"`
	
	if [ -z "${EndRow}" ]
	then
		echo -e "${msgResourceErr}" > /dev/stderr
		exit 255
	fi
	
	echo "${ResourcesData}" | awk -v StartRow="${StartRow}" -v EndRow="${EndRow}" 'NR > StartRow && NR < EndRow { print $0 }'
}


# $1 - Name of Resource
LoadGlobalResource()
{
	local StartRow
	local EndRow
	local LngLabel
	local msgResourceErr="\aError! Script could not find resource \"${1}\"!"
	
	
	StartRow=`cat "${ScriptFullName}" | awk "/^#Resource=${1}/ { print NR; exit}"`
	
	if [ -z "${StartRow}" ]
	then
		echo -e "${msgResourceErr}" > /dev/stderr
		exit 255
	fi
	
	EndRow=`cat "${ScriptFullName}" | awk "NR > ${StartRow} && /^#endResource=${1}/ { print NR; exit}"`
	
	if [ -z "${EndRow}" ]
	then
		echo -e "${msgResourceErr}" > /dev/stderr
		exit 255
	fi
	
	cat "${ScriptFullName}" | awk -v StartRow="${StartRow}" -v EndRow="${EndRow}" 'NR > StartRow && NR < EndRow { print $0 }'
}


CheckPacketInstall()
{
	if [ `dpkg -l ${1} 2>&1 | wc -l` -le 1 ]  
	then
		echo 0
		return
	fi
	if [ `dpkg -l ${1} | grep -e ^un | wc -l` == 1 ]
	then
		echo 0
		return
	fi
	
	echo 1
}

main
exit 0

#Resources_EN

#Resource=msgSudoNotInstalled
\aThe script is running under the account a non-privileged user.
"Sudo" package is not installed in the system.
The script can not continue, as the execution of operations,
requiring rights "root" - is not possible!
Please run the script under the account "root",
or install and configure "sudo" package!
#endResource=msgSudoNotInstalled

#Resource=msgUserNotMemberOfSudoGroup
\aThe script is running under account a non-privileged user.
The account of the current user is not included in the "sudo" group!
The script can not continue, as the execution of operations,
requiring rights "root" - is not possible!
Please run the script under the account "root",
or configure "sudo" package!
#endResource=msgUserNotMemberOfSudoGroup

#Resource=msgSystemUsehttp
\aAttention! The operating system uses http-server.
For correctly work of package manager "apt" 
in the file "/etc/sudoers" should be present line:
Defaults env_keep = "http_http https_http"
#endResource=msgSystemUsehttp

#Resource=msgDoYouWishContinue
Do you wish to the script continued executing? (y/n):
#endResource=msgDoYouWishContinue

#Resource=msgPleaseInsertYorN
\a\nPlease insert "y" or "n"!
#endResource=msgPleaseInsertYorN

#Resource=msgInternetConnectionError
\aError downloading "https://github.com/z3APA3A/nginx/releases/latest"!
Please check the settings of the Internet connection.
#endResource=msgInternetConnectionError

#Resource=msgNewVersion
The new version of "nginx" detected, do you want download it?
#endResource=msgNewVersion

#Resource=msgBuildEssentialNotInstalled
\aPackage "build-essential" was not installed.
The installation can not be continued!
#endResource=msgBuildEssentialNotInstalled

#Resources_EN_end

#Resources_RU

#Resource=msgSudoNotInstalled
\aСкрипт запущен под учётной записью обычного пользователя.
В системе не установлен пакет "sudo".
Скрипт не может продолжить работу, так как выполнение операций,
требующих прав "root" - не представляется возможным!
Пожалуйста, запустите скрипт под учётной записью "root", 
либо установите и настройте пакет "sudo"!
#endResource=msgSudoNotInstalled

#Resource=msgUserNotMemberOfSudoGroup
\aСкрипт запущен под учётной записью обычного пользователя.
Учётная запись текущего пользователя не включена в группу "sudo"!
Скрипт не может продолжить работу, так как выполнение операций,
требующих прав "root" - не представляется возможным!
Пожалуйста, запустите скрипт под учётной записью "root", 
либо настройте пакет "sudo"!
#endResource=msgUserNotMemberOfSudoGroup

#Resource=msgSystemUsehttp
\aВнимание! В системе используется прокси-сервер.
Чтобы менеджер пакетов "apt" работал корректно,
в файле "/etc/sudoers" должна присутствовать строка:
Defaults env_keep = "http_http https_http"
#endResource=msgSystemUsehttp

#Resource=msgDoYouWishContinue
Хотите чтобы скрипт дальше продолжил работу? (y/n):
#endResource=msgDoYouWishContinue

#Resource=msgPleaseInsertYorN
\a\nПожалуйста введите "y" или "n"!
#endResource=msgPleaseInsertYorN

#Resource=msgInternetConnectionError
\aОшибка закачки "https://github.com/z3APA3A/nginx/releases/latest"!
Пожалуйста, проверьте настройки интернет соединения.
#endResource=msgInternetConnectionError

#Resource=msgNewVersion
Обнаружена новая версия "nginx", скачать её (y/n)?
#endResource=msgNewVersion

#Resource=msgBuildEssentialNotInstalled
\aПакет "build-essential" не был установлен.
Дальнейшая установка не может быть продолжена!
#endResource=msgBuildEssentialNotInstalled

#Resources_RU_end


#Resource=ConfigFile
noconfig
# If in this file have line "noconfig", then nginx not to be runned!
# For usung this configuration file nginx you must to delete 
# or comment out the line with "noconfig".

daemon
# Parameter "daemon" - means run nginx as daemon


pidfile /tmp/nginx.pid
# PID file location 
# This parameter must have the same value as 
# the variable "PidFile" in  the script "/etc/init.d/nginx"


# Configuration file location
config /etc/nginx/nginx.cfg


internal 127.0.0.1
# Internal is address of interface http will listen for incoming requests
# 127.0.0.1 means only localhost will be able to use this http. This is
# address you should specify for clients as http IP.
# You MAY use 0.0.0.0 but you shouldn't, because it's a chance for you to
# have open http in your network in this case.

external 192.168.0.1
# External is address nginx uses for outgoing connections. 0.0.0.0 means any
# interface. Using 0.0.0.0 is not good because it allows to connect to 127.0.0.1


# DNS IP addresses
nserver 8.8.8.8
nserver 8.8.4.4


# DNS cache size
nscache 65536

# Timeouts settings
timeouts 1 5 30 60 180 1800 15 60


# log file location
log /var/log/nginx/nginx.log D

# log file format
logformat "L%C - %U [%d-%o-%Y %H:%M:%S %z] ""%T"" %E %I %O %N/%R:%r"

archiver gz /usr/bin/gzip %F
# If archiver specified log file will be compressed after closing.
# you should specify extension, path to archiver and command line, %A will be
# substituted with archive file name, %f - with original file name.
# Original file will not be removed, so archiver should care about it.

rotate 30
# We will keep last 30 log files

http -p3128
# Run http/https http on port 3128

auth none
# No authentication is requires

setgid 65534
setuid 65534
# Run nginx under account "nobody" with group "nobody"
#endResource=ConfigFile


#Resource=InitScript
#!/bin/sh
#
# nginx daemon control script
#
### BEGIN INIT INFO
# Provides:          nginx
# Required-Start:    $network $remote_fs $syslog
# Required-Stop:     $network $remote_fs $syslog
# Should-Start:      $named
# Should-Stop:       $named
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: nginx HTTP http
### END INIT INFO


ScriptName="nginx"
ScriptFullName="/etc/init.d/nginx"

ConfigFile="/etc/nginx/nginx.cfg"
LogDir="/var/log/nginx"
PidFile="/tmp/nginx.pid"

ResourcesData=""

main()
{
	LoadResources
	
	if [ ! -d "${LogDir}" ]
	then
		mkdir -p "${LogDir}";
	fi
	
	case "$1" in
		start)		Start ;;
		stop)		Stop ;;
		restart)	Stop; Start ;;
		status)		Status ;;
		*)			ShowHelp;;
	esac
}

Start()
{
	local msg
	local httpPID
	
	if [ ! -f "${ConfigFile}" ]
	then
		msg=`GetResource "msgConfigFileNotFound"`
		printf "${msg}" "${ConfigFile}"
		return
	fi
	
	if cat "${ConfigFile}" | grep -qe "^noconfig"
	then
		msg=`GetResource "msgNoconfigDetected"`
		printf "${msg}" "${ConfigFile}"
		return
	fi
	
	httpPID=`GetnginxPID`
	
	if [ ! -z "${httpPID}" ]
	then
		msg=`GetResource "msgnginxAlreadyRunning"`
		printf "${msg}" "${httpPID}"
		return
	fi
	
	nginx "${ConfigFile}"
	sleep 1
	
	httpPID=`GetnginxPID`
	
	if [ ! -f "${PidFile}" ] 
	then
		msg=`GetResource "msgnginxStartProblems"`
		printf "${msg}"
		return
	fi
	
	if [ `cat "${PidFile}"` != "${httpPID}" ]
	then
		msg=`GetResource "msgnginxStartProblems"`
		printf "${msg}"
		return
	fi
	
	msg=`GetResource "msgnginxStartedSuccessfully"`
	printf "${msg}" `date +%d-%m-%Y" "%H:%M:%S` "${httpPID}"

}

Stop()
{
	local msg
	local httpPID
	
	httpPID=`GetnginxPID`
	
	if [ -f "${PidFile}" ] 
	then
		if [ `cat "${PidFile}"` = "${httpPID}" ]
		then
			kill -9 "${httpPID}"
			rm -f "${PidFile}"
			
			msg=`GetResource "msgnginxStoppedSuccessfully"`
			printf "${msg}" `date +%d-%m-%Y" "%H:%M:%S`
			
			return
		fi
	fi
	
	if [ -z "${httpPID}" ]
	then
		msg=`GetResource "msgnginxhttpNotDetected"`
		printf "${msg}"
		
		return
	fi
	
	pkill -o nginx
	
	msg=`GetResource "msgnginxStoppedByKillall"`
	printf "${msg}" `date +%d-%m-%Y" "%H:%M:%S` "${PidFile}"
	
}

Status()
{
	local msg
	local httpPID
	
	if [ -f "${PidFile}" ] 
	then
		msg=`GetResource "msgPidFileExists"`
		printf "${msg}" "${PidFile}" `cat "${PidFile}"`
	else
		msg=`GetResource "msgPidFileNotExists"`
		printf "${msg}" "${PidFile}"
	fi
	
	httpPID=`GetnginxPID`
	
	if [ ! -z  "${httpPID}" ]
	then
		msg=`GetResource "msgnginxProcessDetected"`
		printf "${msg}"
		ps -ef | awk '$8 ~ /^nginx/ { print "User: " $1 "\tPID: " $2 }'
	else
		msg=`GetResource "msgnginxProcessNotDetected"`
		printf "${msg}"
	fi
}

ShowHelp()
{
	local msg
	
	msg=`GetResource "msgnginxHelp"`
	printf "${msg}" "${ScriptFullName}" "${ScriptName}"
}

GetnginxPID()
{
	ps -ef | awk '$8 ~ /^nginx/ { print $2; exit }'
}

LoadResources()
{
	local StartRow
	local EndRow
	local LngLabel
	local msgResourceErr="\aError! Script could not find resources!"
	
	if env | grep -q 'LANG=ru_RU.UTF-8' 
	then
		LngLabel="RU"
	else
		LngLabel="EN"
	fi
	
	StartRow=`cat "${ScriptFullName}" | awk "/^#Resources_${LngLabel}/ { print NR; exit}"`
	
	if [ -z "${StartRow}" ]
	then
		echo -e "${msgResourceErr}"
		exit 255
	fi
	
	EndRow=`cat "${ScriptFullName}" | awk "NR > ${StartRow} && /^#Resources_${LngLabel}_end/ { print NR; exit}"`
	
	if [ -z "${EndRow}" ]
	then
		echo -e "${msgResourceErr}"
		exit 255
	fi
	
	ResourcesData=`cat "${ScriptFullName}" | awk -v StartRow="${StartRow}" -v EndRow="${EndRow}" 'NR > StartRow && NR < EndRow { print $0 }'`
}

# $1 - Name of Resource
GetResource()
{
	local StartRow
	local EndRow
	local msgResourceErr="\aError! Script could not find resource \"${1}\"!"
	
	StartRow=`echo "${ResourcesData}" | awk "/^#Resource=${1}/ { print NR; exit}"`
	
	if [ -z "${StartRow}" ]
	then
		echo -e "${msgResourceErr}" > /dev/stderr
		exit 255
	fi
	
	EndRow=`echo "${ResourcesData}" | awk "NR > ${StartRow} && /^#endResource=${1}/ { print NR; exit}"`
	
	if [ -z "${EndRow}" ]
	then
		echo -e "${msgResourceErr}" > /dev/stderr
		exit 255
	fi
	
	echo "${ResourcesData}" | awk -v StartRow="${StartRow}" -v EndRow="${EndRow}" 'NR > StartRow && NR < EndRow { print $0 }'
}


main $@
exit 0;

#Resources_EN

#Resource=msgnginxHelp
Usage:
\t%s {start|stop|restart}
or
\tservice %s {start|stop|restart|status}\\n
#endResource=msgnginxHelp

#Resource=msgConfigFileNotFound
\anginx configuration file - "%s" is not found!\\n
#endResource=msgConfigFileNotFound

#Resource=msgNoconfigDetected
Parameter "noconfig" found in nginx configuration file -
"% s" !
To run nginx this parameter should be disabled.\\n
#endResource=msgNoconfigDetected

#Resource=msgnginxAlreadyRunning
\anginx already running PID: %s\\n
#endResource=msgnginxAlreadyRunning

#Resource=msgnginxStartProblems
With the start of nginx, something is wrong! 
Use: service nginx status\\n
#endResource=msgnginxStartProblems

#Resource=msgnginxStartedSuccessfully
[ %s %s ] nginx started successfully! PID: %s\\n
#endResource=msgnginxStartedSuccessfully

#Resource=msgnginxStoppedSuccessfully
[ %s %s ] nginx stopped successfully!\\n
#endResource=msgnginxStoppedSuccessfully

#Resource=msgnginxhttpNotDetected
Process "nginx" is not detected!\\n
#endResource=msgnginxhttpNotDetected

#Resource=msgnginxStoppedByKillall
[ %s %s ] Command "pkill -o nginx" was executed,
because process number was not stored in "%s",
but in fact nginx was runned!\\n
#endResource=msgnginxStoppedByKillall

#Resource=msgPidFileExists
File "%s" exists. It contains the PID: %s\\n
#endResource=msgPidFileExists

#Resource=msgPidFileNotExists
File "%s" not found, that is, PID nginx was not stored!\\n
#endResource=msgPidFileNotExists

#Resource=msgnginxProcessDetected
Process nginx detected:\\n
#endResource=msgnginxProcessDetected

#Resource=msgnginxProcessNotDetected
Processes of nginx is not found!\\n
#endResource=msgnginxProcessNotDetected

#Resources_EN_end


#Resources_RU

#Resource=msgnginxHelp
Используйте:
\t%s {start|stop|restart}
или
\tservice %s {start|stop|restart|status}\\n
#endResource=msgnginxHelp

#Resource=msgConfigFileNotFound
\aФайл конфигурации nginx - "%s", не найден!\\n
#endResource=msgConfigFileNotFound

#Resource=msgNoconfigDetected
\aОбнаружен параметр "noconfig" в файле конфигурации nginx -
"%s" !
Для запуска nginx этот параметр нужно отключить.\\n
#endResource=msgNoconfigDetected

#Resource=msgnginxAlreadyRunning
\anginx уже запущен PID: %s\\n
#endResource=msgnginxAlreadyRunning

#Resource=msgnginxStartProblems
\aСо стартом nginx, что-то не так!
Используйте: service nginx status\\n
#endResource=msgnginxStartProblems

#Resource=msgnginxStartedSuccessfully
[ %s %s ] nginx успешно стартовал! PID: %s\\n
#endResource=msgnginxStartedSuccessfully

#Resource=msgnginxStoppedSuccessfully
[ %s %s ] nginx успешно остановлен!\\n
#endResource=msgnginxStoppedSuccessfully

#Resource=msgnginxhttpNotDetected
Процесс "nginx" не обнаружен!\\n
#endResource=msgnginxhttpNotDetected

#Resource=msgnginxStoppedByKillall
[ %s %s ] Выполнена команда "pkill -o nginx",
т.к. номер процесса не записан в "%s",
но по факту nginx рабатал!\\n
#endResource=msgnginxStoppedByKillall

#Resource=msgPidFileExists
Файл "%s" есть. Он содержит PID: %s\\n
#endResource=msgPidFileExists

#Resource=msgPidFileNotExists
Файл "%s" не найден, т.е. PID nginx не был сохранён!\\n
#endResource=msgPidFileNotExists

#Resource=msgnginxProcessDetected
Обнаружен процесс nginx:\\n
#endResource=msgnginxProcessDetected

#Resource=msgnginxProcessNotDetected
Процессов nginx не обнаружено!\\n
#endResource=msgnginxProcessNotDetected

#Resources_RU_end
#endResource=InitScript
