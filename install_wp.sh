#!/bin/sh

#WordPress Installer Script

REVISION=88
LASTUPDATED=2012-07-09


################################################## Variables - BEGIN
# WordPress Download URL
#WPDOWNLOADURL="http://wordpress.org/wordpress-3.2.1.tar.gz"
WPDOWNLOADURL="http://wordpress.org/latest.tar.gz"
# WordPress downloaded source filename
WPFILENAME="latestWordPress.tar.gz"
# WordPress credential storage file
WPCREDS="/root/wordpress-creds"

# colors
BLACK='\e[1;30m'
RED='\e[1;31m'
GREEN='\e[1;32m'
YELLOW='\e[1;33m'
BLUE='\e[1;34m'
MAGENTA='\e[1;35m'
CYAN='\e[1;36m'
WHITE='\e[1;37m'
ENDCOLOR='\e[0m'
################################################## Variables - END


################################################## Functions - BEGIN
### trim function: removes whitespace on both sides of the variable value
trim() { 
	# trims the beginning whitespace, and the trailing whitespace, up to the first newline, in which it truncates the input. So, this isn't any good for multiline trimming being submitted in one shot.
	echo $1
}

lowercase() { 
	echo "`echo "$1"| awk '{print tolower($0)}'`"
}

distributionName="`lsb_release -i -s`"
distributionName="$(lowercase $distributionName)"
distributionName="$(trim $distributionName)"

distributionRelease="`lsb_release -r -s`"
distributionRelease="$(lowercase $distributionRelease)"
distributionRelease="$(trim $distributionRelease)"

isCpanelInstalled() {
	if [[ "`ps auxf|grep '/cpanel/\|cpanellogd'|grep -v grep|wc -l`" -gt "1" ]]; then
		echo "1"
	else
		echo "0"
	fi
}

isDirectAdminInstalled() {
	if [[ "`ps auxf|grep '/directadmin/'|grep -v grep|wc -l`" -gt "1" ]]; then
		echo "1"
	else
		echo "0"
	fi
}

checkPhpForEnableFtpSupport() {
        if [[ "$PHPVmajor" -eq "5" ]] && [[ "$PHPVminor" -eq "3" ]]; then
		tempValue="`php -i|grep configure|grep -- '--enable-ftp'|wc -l`"
		if [[ "${tempValue}" -eq "0" ]]; then
	                # PHP is not compiled with FTP support.
		        echo -e "${RED}PHP Compiled FTP Support: NOT DETECTED (Please recompile PHP '--enable-ftp'.)${ENDCOLOR}"
		        echo -e "${RED}WordPress will more than likely be unable to autoupdate itself without this!${ENDCOLOR}"
			echo
		elif [[ "${tempValue}" -eq "1" ]]; then
			# PHP is compiled with FTP support.
		        #echo -e "${GREEN}PHP Compiled FTP Support: Detected${ENDCOLOR}"
			#echo ''
			donothing=1
		else
			# an unexpected error has occurred.
			echo -e "${RED}An unexpected error has occurred while in function isPhpFtpCompiledIn()${ENDCOLOR}"
			exit 98
		fi
	fi
}

detectPhpVersions() {
	echo; echo 'function detectPhpVersions'; echo
	##### to be completed
}

randomString() {
	##### usage: $(randomString 12)
	##### where "12" is the number of random characters to return
        if [[ "$1" -ge "1" ]]; then
                echo "`</dev/urandom tr -dc A-Za-z0-9 | head -c${1}`"
        else
                echo 'fatal error: integer must be greater than zero for randomString function.' >&2
                exit 182
        fi
}

randomLowerString() {
	##### usage: $(randomLowerString 12)
	##### where "12" is the number of random characters to return
        if [[ "$1" -ge "1" ]]; then
                echo "`</dev/urandom tr -dc a-z0-9 | head -c${1}`"
        else
                echo 'fatal error: integer must be greater than zero for randomLowerString function.' >&2
                exit 122
        fi
}

phpUpgradeCheck() {
	#########################################
	### PHP Version checking - added by Laws  - 7/20/2011
	
	PHPV="`php -r 'echo phpversion();'`"
	PHPVmajor="`php -r 'echo phpversion();' | awk -F. '{print $1}'`"
	PHPVminor="`php -r 'echo phpversion();' | awk -F. '{print $2}'`"
	PHPVrevision="`php -r 'echo phpversion();' | awk -F. '{print $3}'`"
	
	if [[ "$PHPVmajor" -lt "5" ]]; then
	    	echo "You currently have PHP v${PHPV} installed.  WordPress requires at least PHP v5.2.4.  As you aren't even in the PHP 5 tree, you can't go further."
	       	exit 5
	elif [[ "$PHPVmajor" -eq "5" ]] && [[ "$PHPVminor" -ge "3" ]]; then
		#echo "You have PHP v${PHPV} and meet the requirements for WordPress v3.2."
		echo -n ''
	elif [[ "$PHPVmajor" -eq "5" ]] && [[ "$PHPVminor" -eq "2" ]] && [[ "$PHPVrevision" -ge "4" ]]; then
		#echo "You have PHP v${PHPV} and meet the requirements for WordPress v3.2."
		echo -n ''
	elif [[ "$PHPVmajor" -eq "5" ]] && [[ "$PHPVminor" -eq "2" ]] && [[ "$PHPVrevision" -lt "4" ]]; then
		while [ "1" -eq "1" ]; do
			echo -n -e " You have PHP v${PHPV}, but you need at least PHP v5.2.4 for WordPress."
			echo -n -e " Would you like to start the upgrade of PHP? (yes/no)${CYAN}:${ENDCOLOR} "
		        read PHPUP
	
		        PHPUP=$(trim $PHPUP)
		        PHPUP="$(lowercase $PHPUP)"
		
	                if [[ "$PHPUP" == "no" ]]; then
				echo -e "${RED}You have chosen not to upgrade PHP. Exiting WordPress install script.${ENDCOLOR}" 
	                      	exit 2
			elif [[ "$PHPUP" == "yes" ]]; then
				configureLine="`php -i | grep configure | sed 's/Configure Command =>//'|tr -d \"'\"`"
				# if php is not currently compiled with ftp support, add the support while it is being recompiled
				if [[ "`php -i|grep configure|grep -- '--enable-ftp'|wc -l`" -eq "0" ]]; then
		                	# PHP is not compiled with FTP support. So we're updating the configure line.
					configurLine="$configureLine '--enable-ftp'"
				fi
	             		echo "Upgrading PHP to v5.2.17."
	              		cd /usr/src
	                	if [[ -d "php-5.2.17" ]]; then
	                	      	echo "5.2.17 source already exists in /usr/src, we'll use this."
	                	      	cd php-5.2.17
					${configureLine} && make clean && make all && make install && service httpd configtest && service httpd restart
	                	else
	                	      	wget fs01/files/php-5.2.17.tar.gz
	                	      	tar xfz php-5.2.17.tar.gz
					cd php-5.2.17
					${configureLine} && make clean && make all && make install && service httpd configtest && service httpd restart
	                	fi
				break
			# else 
				# just keep looping
			fi
		done
	fi	
#	echo ""
}

displayHelp(){
	echo ""
	echo "  Usage: $0 [OPTIONS]"
	echo ""
	echo "  If any value is missing or invalid, it will be interactively prompted for."
	echo ""
	echo "  Options:"
        echo "    --help                          Show this help (Default Behavior)"
        echo "    --menu (IN DEVELOPMENT)         Run interactively (No support for themes or plugins)"
        echo "    --nophp                         (Optional/Deprecated) Skip PHP version checking"
        echo "    --dbhost=<dbhost>               Database server's hostname or FQDN"
        echo "    --suname=<string>               MySQL superuser username"
        echo "    --supass=<string>               MySQL superuser password"
        echo "    --adminuser=<string>            WP Admin username. 'random' gives random string."
        echo "    --adminpass=<string>            WP Admin password. 'random' gives random string."
        echo "    --email=<string>                WP Admin email address"
        echo "    --sec=<y/n>                     Install extra wp-admin security prompt?"
        echo "    --themes=<folder/file.zip>      (Optional, CLI Only) Client themes to install, but not activate."
        echo "                                         Contents will be decompressed in wp-content/themes/"
        echo "    --plugins=<folder/file.zip>     (Optional, CLI Only) Client plugins to install, but not activate."
        echo "                                         Contents will be decompressed in wp-content/plugins/"
        echo "    --domain=<string>               The domain name with optional subfolder to use"
        echo "                                         e.g. 'foo.com' or 'foo.com/blog'"
        echo "    --installfolder=<string>        Where on the filesystem should WordPress be installed?"
        echo "                                         e.g. '/home/httpd/html/foo.com/public_html/blog'"
        echo "    --domainmap=</root/domainmap>   * Can Not Be Used With --domain or --installfolder *"
        echo "      domainmap file format:                                                        "
        echo "        <domain/subfolder>            <documentRoot/installFolder>"
        echo "        sugartime.com                 /home/httpd/html/sugartime.com/public_html"
        echo "        www.megacycle.com             /home/httpd/html/blogs/megacycle.com/htdocs"
        echo ""
	echo "  Usage Example:"
	echo "    Temporarily store the MySQL superuser password using: "
	echo "      echo -n \"What is the MySQL superuser password? \"; read SUPASS"
	echo ""
	echo "    1. Single Install Method (with optional client themes & plugins):"
	echo "      $0 --dbhost=dbserver --suname=root --supass=\$SUPASS --adminuser=random --adminpass=random --email=duh@foo.com --sec=y --themes=/home/httpd/html/blogs/themes.zip --plugins=/home/httpd/html/blogs/plugins.zip --domain=foo.com/blog --installfolder=/home/httpd/html/foo.com/public_html/blog"
	echo ""
	echo "    2. DomainMap Method:"
	echo "      $0 --dbhost=dbserver --suname=root --supass=\$SUPASS --adminuser=random --adminpass=random --email=duh@foo.com --sec=y --domainmap=/root/wp_domainpath_map"
	echo ""
}

installPlugin() {
	# install plugin
	echo -n "Installing ${pluginFilename} plugin .......... "
	pluginGetSourceBool="`wget $pluginURL -O /tmp/wordpress/${pluginFilename} 2>&1|grep \"Saving to\\|unspecified\"|wc -w`"
	pluginGetSourceBool="$(trim $pluginGetSourceBool)"
	EXTRANEOUSFOLDER="plugins"
	EXTRANEOUSSOURCE="/tmp/wordpress/${pluginFilename}"
	EXTRANEOUSFOLDERRESULT="`unzip -l ${EXTRANEOUSSOURCE} |awk '{print $4}'|grep -v "^Name$\|^\-\-\-\-$"|awk -F"/" '{print $1}'|grep "."|sort|uniq|grep -c "^${EXTRANEOUSFOLDER}$"`"
	if [ "${EXTRANEOUSFOLDERRESULT}" -eq "1" ]; then
		unzip -o -q ${EXTRANEOUSSOURCE} -d ${installDir}/wp-content/
	else
		unzip -o -q ${EXTRANEOUSSOURCE} -d ${installDir}/wp-content/${EXTRANEOUSFOLDER}/
	fi
	echo -e "${GREEN}Done${ENDCOLOR}"
}

runFromSlashRootOrFail() {
	if [ "$distributionName" == "centos" ] && [ "`echo "$distributionRelease"|awk -F'.' '{print $1}'`" -ge "4" ]; then
		guaranteedInstallerSourceFolder="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
		if [[ -L "${0}" ]] || [[ -h "${0}" ]] || [[ "`echo ${guaranteedInstallerSourceFolder} | grep "^/root$\|^/root/"|wc -l`" -ne "1" ]]; then
	                echo "For security & tidyness reasons, this script must be run from /root or /root/*."
			exit 99
		fi
	fi
}

incrementQuestion() {
        ##### usage: $(incrementQuestion)
        ##### 1 is added to the value of CURRENTQUESTION, and that new value is returned
	CURRENTQUESTION=`expr $CURRENTQUESTION + 1`
	echo ${CURRENTQUESTION}
}

displayTitleBanner() {
	# MojoHost Title Banner
	echo ''
	echo '============================================================='
	echo "  WordPress Installer Script (Revision $REVISION)"
	echo '============================================================='
	echo ''
}

applyPermissions() {
        #apply the proper WordPress permissions
        chmod 775 wp-content/uploads
        chmod 775 wp-content
        chmod 664 .htaccess
        chown -R $InstallUID:$InstallGID .
        chgrp -R nobody wp-content .htaccess
        chmod -R 0775 wp-content
}

testWebserverAndPhpVersion() {
	echo '
	phpretsetphpsserpdrow_tsohojom
	<?php
	if (!defined("PHP_VERSION_ID")) {
	    $version = explode(".", PHP_VERSION);
	
	    define("PHP_VERSION_ID", ($version[0] * 10000 + $version[1] * 100 + $version[2]));
	}
	
	if (PHP_VERSION_ID < 50207) {
	    define("PHP_MAJOR_VERSION",   $version[0]);
	    define("PHP_MINOR_VERSION",   $version[1]);
	    define("PHP_RELEASE_VERSION", $version[2]);
	}
	
	$t="p"."h"."p"."_"."v"."e"."r"."s"."i"."o"."n"."_"."r"."e"."s"."u"."l"."t";
	echo "<" . $t . ">" . PHP_VERSION_ID . "</" . $t . ">\r\n";
	?>
	' > wpinstaller_wordpressphptester.php
	
	wgetQuery="`wget http://${INSTDOM}/wpinstaller_wordpressphptester.php --quiet -O -`"

	echo -n "Testing file access via web browser ....... "
#	echo "wgetQuery: $wgetQuery"
	if [ "`echo $wgetQuery | grep -c 'phpretsetphpsserpdrow_tsohojom'`" -eq "1" ]; then
                echo -e "${GREEN}Done${ENDCOLOR}"
	else
		echo -e "${RED}Failed! (Unable to read http://${INSTDOM}/wpinstaller_wordpressphptester.php${ENDCOLOR}"
		echo -e "${RED}Please make sure the webserver is properly configured & listening.${ENDCOLOR}"
		exit 5
	fi
	rm -f wpinstaller_wordpressphptester.php

	echo -n "Testing PHP version via web browser ....... "
	phpFound="`echo $wgetQuery | awk -F'<php_version_result>' '{print \$2}'| awk -F'</php_version_result>' '{print \$1}'`"
#	echo "phpFound: $phpFound"
	if [ "$phpFound" -ge "50204" ]; then
                echo -e "${GREEN}Done (PHP v$phpFound)${ENDCOLOR}"
	else
                echo -e "${RED}Failed! (PHP v$phpFound) Exiting${ENDCOLOR}"
                exit 65
        fi
}

wpAdminLogin() {
	WP_INSTDOM="$INSTDOM"
	WP_ADMINUSER="$ADMINUSER"
	WP_ADMINPASS="$ADMINPASS"

	tempphp="\$username='${WP_ADMINUSER}';
	\$password='${WP_ADMINPASS}';
	\$url='http://${WP_INSTDOM}/';
	\$cookies='wpinstallercookies.txt';
	
	##### Login and save the cookie
	\$postdata='log=' . \$username . '&pwd=' . \$password . '&wp-submit=Log%20In&redirect_to=' . \$url . 'wp-admin/&testcookie=1';
	\$ch=curl_init();
	curl_setopt(\$ch, CURLOPT_URL, \$url . 'wp-login.php');
	curl_setopt(\$ch, CURLOPT_SSL_VERIFYPEER, FALSE);
	curl_setopt(\$ch, CURLOPT_USERAGENT, 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6');
	curl_setopt(\$ch, CURLOPT_FOLLOWLOCATION, 1);
	curl_setopt(\$ch, CURLOPT_RETURNTRANSFER, 1);
	curl_setopt(\$ch, CURLOPT_COOKIEJAR, \$cookies);
	curl_setopt(\$ch, CURLOPT_REFERER, \$url . 'wp-admin/');
	curl_setopt(\$ch, CURLOPT_POSTFIELDS, \$postdata);
	curl_setopt(\$ch, CURLOPT_POST, 1);
	\$result = curl_exec(\$ch);
	curl_close(\$ch);"

#	echo "$tempphp"
	php -r "$tempphp"
}

wpAdminPluginActivator() {
        WP_INSTDOM="$INSTDOM"
	WP_SEARCHSTRING="$WP_ADMIN_SEARCHSTRING"

	tempphp="
	\$url='http://${WP_INSTDOM}/';
	\$cookies='wpinstallercookies.txt';

	##### Submit the request to have the update notifier plugin activated using the previously saved cookie
	\$parameters='';
	\$ch=curl_init();
	curl_setopt(\$ch, CURLOPT_URL, \$url . 'wp-admin/plugins.php');
	curl_setopt(\$ch, CURLOPT_SSL_VERIFYPEER, FALSE);
	curl_setopt(\$ch, CURLOPT_USERAGENT, 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6');
	curl_setopt(\$ch, CURLOPT_FOLLOWLOCATION, 1);
	curl_setopt(\$ch, CURLOPT_RETURNTRANSFER, 1);
	curl_setopt(\$ch, CURLOPT_COOKIEJAR, \$cookies);
	curl_setopt(\$ch, CURLOPT_REFERER, \$url . 'wp-admin/plugins.php');
	curl_setopt(\$ch, CURLOPT_COOKIEFILE, \$cookies);
	\$result=curl_exec(\$ch);
	\$result=str_replace('<a ', \"\r\n<a \", \$result);
	\$result=str_replace('</a>', \"</a>\r\n\", \$result);
	
	# plugins.php?action=activate&amp;plugin=update-notifier%2Fupdate-notifier.php&amp;plugin_status=all&amp;paged=1&amp;s&amp;_wpnonce=234eb08836
	#\$searchString='/\?action\=activate\&amp\;plugin\=update-notifier.+_wpnonce=[0-9A-Za-z]+/';
	\$searchString='/\?action\=activate\&amp\;plugin\=${WP_SEARCHSTRING}.+_wpnonce=[0-9A-Za-z]+/';
	preg_match(\$searchString, \$result, \$matches);
	curl_close(\$ch);

	##### Submit the request to have the plugin activated using the previously saved cookie
	#\$parameters='?action=activate&plugin=update-notifier%2Fupdate-notifier.php&plugin_status=all&paged=1&s&_wpnonce=f342b845c7';
	\$queryString=\$matches[0];
	#echo \$queryString;
	\$queryString=html_entity_decode(\$queryString);
	#echo \$queryString;
	\$parameters=\$queryString;
	\$ch=curl_init();
	curl_setopt(\$ch, CURLOPT_URL, \$url . 'wp-admin/plugins.php' . \$parameters);
	curl_setopt(\$ch, CURLOPT_SSL_VERIFYPEER, FALSE);
	curl_setopt(\$ch, CURLOPT_USERAGENT, 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6');
	curl_setopt(\$ch, CURLOPT_FOLLOWLOCATION, 1);
	curl_setopt(\$ch, CURLOPT_RETURNTRANSFER, 1);
	curl_setopt(\$ch, CURLOPT_COOKIEJAR, \$cookies);
	curl_setopt(\$ch, CURLOPT_REFERER, \$url . 'wp-admin/plugins.php');
	curl_setopt(\$ch, CURLOPT_COOKIEFILE, \$cookies);
	\$result=curl_exec(\$ch);
	#echo \$result;
	curl_close(\$ch);
	"

#	echo "$tempphp"
	php -r "$tempphp"
}

wpAdminPluginW3tcBasicDiskCacheEnabler() {

        WP_INSTDOM="$INSTDOM"
        WP_SEARCHSTRING="w3tc_preview_deploy"

        tempphp="
        \$url='http://${WP_INSTDOM}/';
        \$cookies='wpinstallercookies.txt';

        ##### Submit the request to have the update notifier plugin activated using the previously saved cookie
        \$parameters='';
        \$ch=curl_init();
        curl_setopt(\$ch, CURLOPT_URL, \$url . 'wp-admin/admin.php?page=w3tc_general');
        curl_setopt(\$ch, CURLOPT_SSL_VERIFYPEER, FALSE);
        curl_setopt(\$ch, CURLOPT_USERAGENT, 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6');
        curl_setopt(\$ch, CURLOPT_FOLLOWLOCATION, 1);
        curl_setopt(\$ch, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt(\$ch, CURLOPT_COOKIEJAR, \$cookies);
        curl_setopt(\$ch, CURLOPT_REFERER, \$url . 'wp-admin/plugins.php');
        curl_setopt(\$ch, CURLOPT_COOKIEFILE, \$cookies);
        \$result=curl_exec(\$ch);
        \$result=str_replace('<a ', \"\r\n<a \", \$result);
        \$result=str_replace('</a>', \"</a>\r\n\", \$result);

        # admin.php?page=w3tc_general&amp;w3tc_preview_deploy&amp;_wpnonce=9b79d0e3aa
	# plugins.php?action=activate&amp;plugin=update-notifier%2Fupdate-notifier.php&amp;plugin_status=all&amp;paged=1&amp;s&amp;_wpnonce=234eb08836
        #\$searchString='/\?action\=activate\&amp\;plugin\=update-notifier.+_wpnonce=[0-9A-Za-z]+/';

        #\$searchString='/\?action\=activate\&amp\;plugin\=${WP_SEARCHSTRING}.+_wpnonce=[0-9A-Za-z]+/';
        \$searchString='/\?page\=w3tc_general\&amp\;${WP_SEARCHSTRING}\&amp\;_wpnonce=[0-9A-Za-z]+/';
        preg_match(\$searchString, \$result, \$matches);
        curl_close(\$ch);

        ##### Submit the request to have the plugin activated using the previously saved cookie
        #\$parameters='?page=w3tc_general&w3tc_preview_deploy&_wpnonce=9b79d0e3aa';
        \$queryString=\$matches[0];
#        echo \$queryString . \"\r\n\";
        \$queryString=html_entity_decode(\$queryString);
#        echo \$queryString . \"\r\n\";
        \$queryString=html_entity_decode(\$queryString);
        \$parameters=\$queryString;
        \$ch=curl_init();

#        echo 'activation url: ' . \$url . 'wp-admin/admin.php' . \$parameters . \"\r\n\";

        curl_setopt(\$ch, CURLOPT_URL, \$url . 'wp-admin/admin.php' . \$parameters);
        curl_setopt(\$ch, CURLOPT_SSL_VERIFYPEER, FALSE);
        curl_setopt(\$ch, CURLOPT_USERAGENT, 'Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.8.1.6) Gecko/20070725 Firefox/2.0.0.6');
        curl_setopt(\$ch, CURLOPT_FOLLOWLOCATION, 1);
        curl_setopt(\$ch, CURLOPT_RETURNTRANSFER, 1);
        curl_setopt(\$ch, CURLOPT_COOKIEJAR, \$cookies);
        curl_setopt(\$ch, CURLOPT_REFERER, \$url . 'wp-admin/admin.php?page=w3tc_general');
        curl_setopt(\$ch, CURLOPT_COOKIEFILE, \$cookies);
#        curl_setopt(\$ch, CURLOPT_POSTFIELDS, \$postdata);
#        curl_setopt(\$ch, CURLOPT_POST, 1);
        \$result=curl_exec(\$ch);
        #echo \$result;
        curl_close(\$ch);
        "

#        echo "$tempphp"
        php -r "$tempphp"
}
################################################## Functions - END


runFromSlashRootOrFail


################################################## Command Line Arguments - BEGIN
# Show Help???
argName="--help"
for param in "$@"; do
        if [ "`echo "${param}"|grep -c "^${argName}$"`" -eq "1" ]; then
		displayHelp
		exit 3
        fi
done
################################################## Command Line Arguments - END





trap 'echo -e "${ENDCOLOR}"; exit -1' INT


################################################## Interrogation Phase - BEGIN
displayTitleBanner


############################## Post-Banner Messages - END
# --nophp check???
argName="--nophp"
paramNophp="0"
for param in "$@"; do
        if [ "`echo "${param}"|grep -c "^${argName}$"`" -eq "1" ] && [ "${paramNophp}" -ne "1" ]; then
		paramNophp="1"
		break
        fi
done
if [ "${paramNophp}" -eq "1" ]; then
	# --nophp was found on the command line, skip the php version check
	echo "... CLI Option: Skipping PHP version check"
else
	# -nophp was NOT found on the command line, perform the PHP Upgrade Check
	phpUpgradeCheck
fi



# --themes=/folder/path check???
argName="--themes"
paramAlreadyMatched="0"
paramTemp=""
for param in "$@"; do
        if [ "`echo "${param}"|grep -c "^${argName}="`" -eq "1" ] && [ "`echo "${param}"|grep -c "="`" -eq "1" ]; then
		if [ "${paramAlreadyMatched}" -eq "0" ]; then
			paramTemp="`echo ${param}| awk -F"=" '{print $2}'`"
			if [ -f "${paramTemp}" ]; then
		        	echo "... CLI Option: Themes from '${paramTemp}' will be installed."
				paramThemes="${paramTemp}"
				paramAlreadyMatched="1"
			else
				echo -e "${RED}Themes file '${paramTemp}' does not exist. Aborting install.${ENDCOLOR}"
				exit
			fi
		else
                        echo -e "${RED}${argName}= specified twice. Aborting install.${ENDCOLOR}"
			exit
		fi
	fi
done

# --plugins=/folder/path check???
argName="--plugins"
paramAlreadyMatched="0"
paramTemp=""
for param in "$@"; do
        if [ "`echo "${param}"|grep -c "^${argName}="`" -eq "1" ] && [ "`echo "${param}"|grep -c "="`" -eq "1" ]; then
		if [ "${paramAlreadyMatched}" -eq "0" ]; then
			paramTemp="`echo ${param}| awk -F"=" '{print $2}'`"
			if [ -f "${paramTemp}" ]; then
		        	echo "... CLI Option: Plugins from '${paramTemp}' will be installed."
				paramPlugins="${paramTemp}"
				paramAlreadyMatched="1"
			else
				echo -e "${RED}Plugins file '${paramTemp}' does not exist. Aborting install.${ENDCOLOR}"
				exit
			fi
		else
                        echo -e "${RED}${argName}= specified twice. Aborting install.${ENDCOLOR}"
			exit
		fi
	fi
done

# --email= check???
argName="--email"
paramAlreadyMatched="0"
paramTemp=""
for param in "$@"; do
        if [ "`echo "${param}"|grep -c "^${argName}="`" -eq "1" ] && [ "`echo "${param}"|grep -c "="`" -eq "1" ]; then
		if [ "${paramAlreadyMatched}" -eq "0" ]; then
			paramTemp="`echo ${param}| awk -F"=" '{print $2}'`"
        		paramTemp="$(lowercase $paramTemp)"
	        	echo "... CLI Option: WordPress Admin email address of '${paramTemp}' will be used."
			paramEmail="${paramTemp}"
			paramAlreadyMatched="1"
		else
                        echo -e "${RED}${argName}= specified twice. Aborting install.${ENDCOLOR}"
			exit
		fi
	fi
done

# --adminuser= check???
argName="--adminuser"
paramAlreadyMatched="0"
paramTemp=""
for param in "$@"; do
        if [ "`echo "${param}"|grep -c "^${argName}="`" -eq "1" ] && [ "`echo "${param}"|grep -c "="`" -eq "1" ]; then
		if [ "${paramAlreadyMatched}" -eq "0" ]; then
			paramTemp="`echo ${param}| awk -F"=" '{print $2}'`"
	        	echo "... CLI Option: WordPress Admin username set to '${paramTemp}'."
			paramAdminuser="${paramTemp}"
			paramAlreadyMatched="1"
		else
                        echo -e "${RED}${argName}= specified twice. Aborting install.${ENDCOLOR}"
			exit
		fi
	fi
done

# --adminpass= check???
argName="--adminpass"
paramAlreadyMatched="0"
paramTemp=""
for param in "$@"; do
        if [ "`echo "${param}"|grep -c "^${argName}="`" -eq "1" ] && [ "`echo "${param}"|grep -c "="`" -eq "1" ]; then
		if [ "${paramAlreadyMatched}" -eq "0" ]; then
			paramTemp="`echo ${param}| awk -F"=" '{print $2}'`"
	        	echo "... CLI Option: WordPress Admin password set to '${paramTemp}'."
			paramAdminpass="${paramTemp}"
			paramAlreadyMatched="1"
		else
                        echo -e "${RED}${argName}= specified twice. Aborting install.${ENDCOLOR}"
			exit
		fi
	fi
done

# --dbhost= check???
argName="--dbhost"
paramAlreadyMatched="0"
paramTemp=""
for param in "$@"; do
        if [ "`echo "${param}"|grep -c "^${argName}="`" -eq "1" ] && [ "`echo "${param}"|grep -c "="`" -eq "1" ]; then
		if [ "${paramAlreadyMatched}" -eq "0" ]; then
			paramTemp="`echo ${param}| awk -F"=" '{print $2}'`"
        		paramTemp="$(lowercase $paramTemp)"
	        	echo "... CLI Option: Database Server host of '${paramTemp}' will be used."
			paramDbhost="${paramTemp}"
			paramAlreadyMatched="1"
		else
                        echo -e "${RED}${argName}= specified twice. Aborting install.${ENDCOLOR}"
			exit
		fi
	fi
done

# --suname= check???
argName="--suname"
paramAlreadyMatched="0"
paramTemp=""
for param in "$@"; do
        if [ "`echo "${param}"|grep -c "^${argName}="`" -eq "1" ] && [ "`echo "${param}"|grep -c "="`" -eq "1" ]; then
		if [ "${paramAlreadyMatched}" -eq "0" ]; then
			paramTemp="`echo ${param}| awk -F"=" '{print $2}'`"
        		paramTemp="$(lowercase $paramTemp)"
	        	echo "... CLI Option: Database Server superuser username of '${paramTemp}' will be used."
			paramSuname="${paramTemp}"
			paramAlreadyMatched="1"
		else
                        echo -e "${RED}${argName}= specified twice. Aborting install.${ENDCOLOR}"
			exit
		fi
	fi
done

# --supass= check???
argName="--supass"
paramAlreadyMatched="0"
paramTemp=""
for param in "$@"; do
        if [ "`echo "${param}"|grep -c "^${argName}="`" -eq "1" ] && [ "`echo "${param}"|grep -c "="`" -eq "1" ]; then
		if [ "${paramAlreadyMatched}" -eq "0" ]; then
			paramTemp="`echo ${param}| awk -F"=" '{print $2}'`"
	        	echo "... CLI Option: Database Server superuser password of '${paramTemp}' will be used."
			paramSupass="${paramTemp}"
			paramAlreadyMatched="1"
		else
                        echo -e "${RED}${argName}= specified twice. Aborting install.${ENDCOLOR}"
			exit
		fi
	fi
done

# --sec= check???
argName="--sec"
paramAlreadyMatched="0"
paramTemp=""
for param in "$@"; do
        if [ "`echo "${param}"|grep -c "^${argName}="`" -eq "1" ] && [ "`echo "${param}"|grep -c "="`" -eq "1" ]; then
		if [ "${paramAlreadyMatched}" -eq "0" ]; then
			paramTemp="`echo ${param}| awk -F"=" '{print $2}'`"
        		paramTemp="$(lowercase $paramTemp)"
			echo "... CLI Option: Basic Auth prompt setting of '${paramTemp}' will be used."
			paramSec="${paramTemp}"
			paramAlreadyMatched="1"
		else
                        echo -e "${RED}${argName}= specified twice. Aborting install.${ENDCOLOR}"
			exit
		fi
	fi
done

# --domain= check???
argName="--domain"
paramAlreadyMatched="0"
paramTemp=""
paramDomainOption="0"
for param in "$@"; do
        if [ "`echo "${param}"|grep -c "^${argName}="`" -eq "1" ] && [ "`echo "${param}"|grep -c "="`" -eq "1" ]; then
		if [ "${paramAlreadyMatched}" -eq "0" ]; then
			paramTemp="`echo ${param}| awk -F"=" '{print $2}'`"
			echo "... CLI Option: WordPress will be accessible using 'http://${paramTemp}'."
			paramDomain="${paramTemp}"
			paramAlreadyMatched="1"
			paramDomainOption="1"
		else
                        echo -e "${RED}${argName}= specified twice. Aborting install.${ENDCOLOR}"
			exit
		fi
	fi
done

# --installfolder= check???
argName="--installfolder"
paramAlreadyMatched="0"
paramTemp=""
paramInstallFolderOption="0"
for param in "$@"; do
        if [ "`echo "${param}"|grep -c "^${argName}="`" -eq "1" ] && [ "`echo "${param}"|grep -c "="`" -eq "1" ]; then
		if [ "${paramAlreadyMatched}" -eq "0" ]; then
			paramTemp="`echo ${param}| awk -F"=" '{print $2}'`"
			echo "... CLI Option: WordPress will be installed into folder '${paramTemp}'."
			paramInstallfolder="${paramTemp}"
			paramAlreadyMatched="1"
                        paramInstallFolderOption="1"
		else
                        echo -e "${RED}${argName}= specified twice. Aborting install.${ENDCOLOR}"
			exit
		fi
	fi
done



############
# --installfolder= check???
argName="--domainmap"
paramAlreadyMatched="0"
paramTemp=""
for param in "$@"; do
        if [ "`echo "${param}"|grep -c "^${argName}="`" -eq "1" ] && [ "`echo "${param}"|grep -c "="`" -eq "1" ]; then
                if [ "${paramAlreadyMatched}" -eq "0" ]; then
			if [ "${paramDomainOption}" -ne "0" ] || [ "${paramInstallFolderOption}" -ne "0" ]; then
				# Those Parameters Conflict
	                        echo -e "${RED}Error: --domainmap must be used without --domain and --installfolder. Exiting WordPress Installer.${ENDCOLOR}"
	                        exit
			fi

			#        echo "    --domain=<string>               The domain name with optional subfolder to use"
			#        echo "    --installfolder=<string>        Where on the filesystem should WordPress be installed?"
			#        echo "    --domainmap=</root/domainmap>                                             "
			paramTemp="`echo ${param}| awk -F"=" '{print $2}'`"
			paramTemp="`cat ${paramTemp} |grep .`"
	
			i=0
			echo "${paramTemp}" | while read -r LINE; do
			        ((i++))
			        #echo "Line #${i} Contents '$LINE'"
			        tempLinePart1="`echo "$LINE"|awk '{print $1}'`"
			        tempLinePart2="`echo "$LINE"|awk '{print $2}'`"
			        tempLinePart3="`echo "$LINE"|awk '{print $3}'`"
			        if [ "${tempLinePart1}" != "" ] && [ "${tempLinePart2}" != "" ] && [ "${tempLinePart3}" == "" ]; then

					tempReconstructedParameters=""
					for param2 in "$@"; do
						if [ "`echo "${param2}"|grep -c "^${argName}="`" -ne "1" ]; then
							tempReconstructedParameters=" ${tempReconstructedParameters} ${param2}"
						fi
					done
			                individualInstanceString="`echo "$0 ${tempReconstructedParameters} --domain=${tempLinePart1} --installfolder=${tempLinePart2}" |sed 's/ \+/ /g'`"
					echo "${individualInstanceString}"
					${individualInstanceString}
			        else
			                echo "CRITICAL ERROR... part1: '${tempLinePart1}', part2: '${tempLinePart2}', part3: '${tempLinePart3}'"
			        fi
			done < /dev/stdin
			exit
                else
                        echo -e "${RED}${argName}= specified twice. Aborting install.${ENDCOLOR}"
                        exit
                fi
        fi
done

############

############################## Post-Banner Messages - END



# Get the install directory (else, our current working directory)

if [ "${paramInstallfolder}" != "" ]; then
        installDir="${paramInstallfolder}"
else
	installDir="`pwd`"
fi

# change back to our root directory in the event we had to install PHP
cd "${installDir}"


echo ''
#echo 'Always download the latest version of this script from http://fs01/repos/scripts/wordpress/install.sh'
echo "Credentials will be appended to: ${WPCREDS}"

# If wordpress is already installed, let's not do anything.
if [ -d wp-admin ]; then
        echo WordPress is already installed!
	echo ""
        exit 1
else
	echo "WordPress will be installed in: ${installDir}"
	echo '(Type CTRL-C by the last question to safely abort.)'
	echo ''
fi


##### Operating Variables
checkPhpForEnableFtpSupport
CURRENTQUESTION="0"
TOTALQUESTIONS="11"


#echo "Please provide the following..."

# What server name can WordPress use for connecting to the database.
DBHOSTIP="`ping -c1 -w0 dbserver 2>&1|head -n1|sed 's/[()]//g'|awk '{print $3}'`"
DBHOST="localhost"
if [ "${DBHOSTIP}" == "host" ]; then
        echo -e "       ${YELLOW}'DBSERVER' is not defined. Using 'localhost' instead."
elif [ "${DBHOSTIP}" == "127.0.0.1" ]; then
	echo -e "       ${GREEN}Please Note: 'dbserver' points to '${DBHOSTIP}'."
	DBHOST="dbserver"
else
	DBHOST="dbserver"
	echo -e "       ${RED}Please Note: 'dbserver' points to '${DBHOSTIP}'. Using '${DBHOST}'."
	echo -e "       ${RED}This script does not install correctly to non-localhost based database servers. It never has!'."
	echo -e "       ${RED}You will need to set setup the firewall, and grants for this server's eth1 IP.'."
fi


FALLBACKDBHOST="${DBHOST}"
paramINVALID="0"
while [ "1" -eq "1" ]; do
        if [ "${paramDbhost}" != "" ] && [ "${paramINVALID}" == "0" ]; then
                DBHOST="${paramDbhost}"
        else
		DBHOST="${FALLBACKDBHOST}"
		echo -n -e " ${YELLOW}$(incrementQuestion)/${TOTALQUESTIONS}.${ENDCOLOR} Enter the MySQL server that WordPress should use (ENTER for '${DBHOST}')${CYAN}:${ENDCOLOR} "
		read NEWDBHOST
	fi
	NEWDBHOST="$(lowercase $NEWDBHOST)"
	NEWDBHOST="$(trim $NEWDBHOST)"

	if [ "$NEWDBHOST" == "" ]; then
		DBHOST="$(trim ${DBHOST})"
	else
		DBHOST="$NEWDBHOST"
	fi

	DBHOSTRESOLVETESTFAIL="`ping -c 1 -w 1 ${DBHOST} 2>&1 |grep "unknown host"|wc -l`"

        if [ "$DBHOSTRESOLVETESTFAIL" -eq "1" ]; then
                echo -e "         ${RED}'${DBHOST}' does not resolve to an IP address. Please try again.${ENDCOLOR}"
		paramINVALID="1"
        else
                break
	fi
done


# Ask for the MySQL superuser name



# Ask the system administrator for MySQL's root password.
paramINVALID="0"
while [ "1" -eq "1" ]; do
	if [ "${paramSuname}" != "" ]; then
		MYSQLSUPERUSER="${paramSuname}"
	else
		echo -n -e " ${YELLOW}$(incrementQuestion)/${TOTALQUESTIONS}.${ENDCOLOR} Enter the MySQL superuser name for '$DBHOST' (ENTER for 'root')${CYAN}:${ENDCOLOR} "
                read MYSQLSUPERUSER
	fi

        if [ "${paramSupass}" != "" ] && [ "${paramINVALID}" == "0" ]; then
                MYSQLSUPERPASS="${paramSupass}"
        else
		echo -n -e " ${YELLOW}$(incrementQuestion)/${TOTALQUESTIONS}.${ENDCOLOR} Enter the MySQL superuser password for '$DBHOST'${CYAN}:${ENDCOLOR} "
		#read -s MYSQLSUPERPASS
		read MYSQLSUPERPASS
	fi

        MYSQLSUPERUSER="$(trim $MYSQLSUPERUSER)"
	MYSQLSUPERPASS="$(trim $MYSQLSUPERPASS)"
	
	if [ "${MYSQLSUPERUSER}" == "" ]; then
		MYSQLSUPERUSER="root"
	fi

	# get mysql connect test response
        if [ "${DBHOSTIP}" == "127.0.0.1" ]; then
	        MYSQLTESTBOOL="`mysql -hlocalhost mysql --password=$MYSQLSUPERPASS -u$MYSQLSUPERUSER <<EOF 2>&1|grep \"Access denied\"|wc -w`"
        else
	        MYSQLTESTBOOL="`mysql -h$DBHOST mysql --password=$MYSQLSUPERPASS -u$MYSQLSUPERUSER <<EOF 2>&1|grep \"Access denied\"|wc -w`"
        fi

        if [[ "$(trim $MYSQLTESTBOOL)" -eq "0" ]]; then
		MYSQLLOGINGOOD="true"
	        break
	else
		echo -e "         ${RED}That MySQL root password is incorrect.${ENDCOLOR}"
                paramINVALID="1"
	fi
done




# What is the domain name with sub-directory path of the WordPress install?
paramINVALID="0"
while [ "1" -eq "1" ]; do
        if [ "${paramDomain}" != "" ] && [ "${paramINVALID}" == "0" ]; then
                INSTDOM="${paramDomain}"
        else
		echo -e " ${YELLOW}$(incrementQuestion)/${TOTALQUESTIONS}.${ENDCOLOR} Enter the domain without http (if blog is installed in sub dir include that in domain path),"
		echo -e -n "       (MultiSites should not include 'www.' e.g. 'foo.com' or 'foo.com/blog')${CYAN}:${ENDCOLOR} "
		read INSTDOM
	fi
	INSTDOM="$(trim $INSTDOM)"

	DOMAIN="`echo ${INSTDOM}|awk -F'/' '{print $1}'`"
	DOMAINRESOLVETESTFAIL="`ping -c 1 -w 1 ${DOMAIN} 2>&1 |grep "unknown host"|wc -l`"
	ONTHISSERVER="`ifconfig|grep ":\`resolveip -s ${DOMAIN} 2>&1\` " 2>&1|grep -v '\[OPTION\]\|--help'|sed 's/:/ /g'|awk '{print $3}'| wc -l`"

	if [ "$INSTDOM" == "" ]; then
                echo -e "         ${RED}You cannot use a blank domain.${ENDCOLOR}"
		paramINVALID="1"
	elif [ "$DOMAINRESOLVETESTFAIL" -eq "1" ]; then
                echo -e "         ${RED}'${DOMAIN}' does not resolve to an IP address. Please try again.${ENDCOLOR}"
		paramINVALID="1"
	elif [ "$ONTHISSERVER" -ne "1" ]; then
                echo -e "         ${RED}'${DOMAIN}' is not a configured host/domainname on this server.${ENDCOLOR}"
		paramINVALID="1"
	else
		break        
	fi
done




# reduce and generate domainname
# Get the database name that WordPress will be install into.
# If it doesn't already exist, WordPress will create it.
##DBNAME=
##dbExistsBool=2

# clean the domain to leave just the basic alphanumerics, minus the vowels. 
##### BAD!!!!! In cases where a domain is just vowels, this would be catastrophic
#DOMAINCLEAN="`echo ${DOMAIN}|tr -dc A-Za-z0-9|tr -d AaEeIiOoUuYy`"

# clean the domain to include just the basic alphanumerics
#DOMAINCLEAN="`echo ${DOMAIN}|tr -dc A-Za-z0-9`|"
DOMAINCLEAN="`echo ${DOMAIN}|tr -dc A-Za-z0-9`"

DBNAME="${DOMAINCLEAN}"
DBNAMEATTEMPT="0"

while [ "1" -eq "1" ]; do
#	echo -n -e " ${YELLOW}$(incrementQuestion)/${TOTALQUESTIONS}.${ENDCOLOR} Enter a new database name to create on '$DBHOST'${CYAN}:${ENDCOLOR} "
#	read DBNAME
#	DBNAME="$(trim $DBNAME)"

	DBNAMEATTEMPT="`expr ${DBNAMEATTEMPT} + 1`"
	DBNAMELENGTH="`echo "${DBNAME}"|wc -c`"

	# truncate DBNAME if necessary, and append "_wp" to the end of it
	if [ "${DBNAMEATTEMPT}" -eq "1" ]; then
		DBNAME="`echo "${DBNAME:0:13}"`"
	else 
		DBNAME="`echo "${DBNAME:0:11}"`$(randomLowerString 2)"
	fi

	# get list of databases
        if [ "${DBHOSTIP}" == "127.0.0.1" ]; then
RESULT="`mysql -hlocalhost mysql --password=$MYSQLSUPERPASS -u$MYSQLSUPERUSER <<EOF
show databases;
EOF`"
        else
RESULT="`mysql -h$DBHOST mysql --password=$MYSQLSUPERPASS -u$MYSQLSUPERUSER <<EOF
show databases;
EOF`"
        fi

	# output databases + database names
	#echo $RESULT
	
	# equals 1 if database already exists, equals 0 if database does not exist
	dbExistsBool="`echo "$RESULT"|grep -w \"${DBNAME}_wp\"|wc -w`"
	dbExistsBool="$(trim $dbExistsBool)"
	#echo $dbExistsBool

	if [ -f /etc/proftpd.db ]; then
		ftpAccountExistsBool="`grep -c \"${DBNAME}_wp_autoftp:\" /etc/proftpd.db`"
		ftpAccountExistsBool="$(trim $ftpAccountExistsBool)"
	else
		ftpAccountExistsBool="0"
	fi

	#echo "$RESULT"|wc -w
	
#	if [ "$dbExistsBool" -eq "1" ]; then
#	        echo -e "         ${WHITE}The database '${DBNAME}_wp' already exists. Trying Again.${ENDCOLOR}"
#	fi

#	if [ "$DBNAME" == "" ]; then
#	        echo -e "         ${RED}You cannot use a blank database name.${ENDCOLOR}"
#	fi

	if [ "$dbExistsBool" -eq "0" ] && [ "$ftpAccountExistsBool" -eq "0" ] && [ "${DBNAME}" != "" ]; then
                echo -e "       ${GREEN}Creating database '${DBNAME}_wp'.${ENDCOLOR}"
		DBNAME="${DBNAME}_wp"
		break
	fi

#	echo "DBNAME: ${DBNAME}"
#	exit
done




# Get the username that WordPress will login to MySQL with.
DBUSER="${DBNAME}"

#while [ "1" -eq "1" ]; do
#	echo -n -e " ${YELLOW}$(incrementQuestion)/${TOTALQUESTIONS}.${ENDCOLOR} Enter a new database username to create on '$DBHOST' (ENTER for '$DBNAME')${CYAN}:${ENDCOLOR} "
#	read DBUSER
#	DBUSER="$(trim $DBUSER)"
#
#	if [ "$DBUSER" == "" ]; then
#	        DBUSER=$DBNAME
#	fi
#
#	# get the number of characters in DBUSER
#	DBUSERLENGTH="`echo \"$DBUSER\"|wc -c`"
#	DBUSERLENGTH="$(trim $DBUSERLENGTH)"
#
#	# fix the reported length of DBUSERfrom having one too many characters.
#        DBUSERLENGTH=`expr ${DBUSERLENGTH} - 1`
#
#        if [[ "$DBUSERLENGTH" -gt "0" ]] && [[ "$DBUSERLENGTH" -le "16" ]]; then
#		break
#	else
#                echo -e "         ${RED}That database username is $DBUSERLENGTH characters long. Max Characters = 16. Please shorten it.${ENDCOLOR}"
#        fi
#done


# Get the password that WordPress will use to login to MySQL with.
DBPASS="$(randomString 12)"

#echo -n -e " ${YELLOW}$(incrementQuestion)/${TOTALQUESTIONS}.${ENDCOLOR} Enter a new database password for user '$DBUSER' (ENTER to generate random)${CYAN}:${ENDCOLOR} 
#" read DBPASS DBPASS="$(trim $DBPASS)" if [ "$DBPASS" == "" ]; then
#	DBPASS="$(randomString 12)"
#fi



# Get the WordPress Admin Username.
if [ "${paramAdminuser}" != "" ]; then
        ADMINUSER="${paramAdminuser}"
else
	echo -e " ${YELLOW}$(incrementQuestion)/${TOTALQUESTIONS}.${ENDCOLOR} Enter a new WordPress Admin Username (ENTER for 'Admin',"
	echo -e -n "       type \"random\" to generate random, or type a custom username)${CYAN}:${ENDCOLOR} "
	read ADMINUSER
fi
ADMINUSER="$(trim $ADMINUSER)"
if [ "$ADMINUSER" == "" ]; then                                                         
        ADMINUSER="Admin"                                    
elif [ "$(lowercase $ADMINUSER)" == "random" ]; then
        ADMINUSER="$(randomString 12)"
fi






# Get the WordPress Admin Password.
if [ "${paramAdminpass}" != "" ]; then
        ADMINPASS="${paramAdminpass}"
else
	echo -n -e " ${YELLOW}$(incrementQuestion)/${TOTALQUESTIONS}.${ENDCOLOR} Enter a new WordPress Admin Password (ENTER to generate random)${CYAN}:${ENDCOLOR} "
	read ADMINPASS
fi
ADMINPASS="$(trim $ADMINPASS)"
if [ "$ADMINPASS" == "" ] || [ "$(lowercase $ADMINPASS)" == "random" ]; then
	ADMINPASS="$(randomString 12)"
fi
# verify we got an actual password
if [ "$ADMINPASS" == "" ]; then
	echo -e "${RED}Was unable to generate a new random password... ABORTING INSTALL!${ENDCOLOR}"
	exit 2
fi




################################################
## Security credentials section open
## Added by laws - 7/20/2011
## Create random username and password for wp-admin .htaccess lockdown

SECUSER="$(randomString 12)"
SECPASS="$(randomString 16)"

#Verify secuser is valid
if [ "$SECUSER" == "" ]; then
	echo -e "${RED}Unable to generate a random security username... ABORTING INSTALL!${ENDCOLOR}"
	exit 4
fi

#Verify secpass is valid
if [ "$SECPASS" == "" ]; then
	echo -e "${RED}Unable to generate a random security password... ABORTING INSTALL!${ENDCOLOR}"
        exit 3
fi

##
## Security credentials section close
##################################################



ClientName="`grep :\`stat . --format=%u\`: /etc/passwd|cut -f1 -d:|head -n1`"
## What is the Unix Login Name being actively used for the client target installation folder? Do a "ls -l" to see.
#while [ "1" -eq "1" ]; do
#	echo -n -e " ${YELLOW}$(incrementQuestion)/${TOTALQUESTIONS}.${ENDCOLOR} Enter the Unix login name (ENTER for '${ClientName}')${CYAN}:${ENDCOLOR} "
#	read UIDName
#	UIDName="$(trim $UIDName)"
	
#	if [ "$UIDName" == "" ]; then
	        UIDName=$ClientName
#	fi
	
	# If user exists in /etc/passwd, use their UID and GID as the chown and chgrp IDs.
        if [ "`grep "^${UIDName}:" /etc/passwd|awk -F: '{print $1}'|wc -l`" -eq "1" ]; then
                InstallUID=`grep "^${UIDName}:" /etc/passwd|awk -F: '{print $3}'`
                InstallGID=`grep "^${UIDName}:" /etc/passwd|awk -F: '{print $4}'`
#		break
	else
		echo -e "         ${RED}I'm sorry but that is not a valid user.${ENDCOLOR}"
		exit
	fi
#done


# What is the email address to use for the WordPress Admin account?
paramINVALID="0"
while [ "1" -eq "1" ]; do
	if [ "${paramEmail}" != "" ] && [ "${paramINVALID}" == "0" ]; then
		ADMINEMAIL="${paramEmail}"
	else
		echo -n -e " ${YELLOW}$(incrementQuestion)/${TOTALQUESTIONS}.${ENDCOLOR} Enter the client email to use for the WordPress Admin account${CYAN}:${ENDCOLOR} "
		read ADMINEMAIL
	fi
	ADMINEMAIL="$(lowercase $ADMINEMAIL)"
	ADMINEMAIL="$(trim $ADMINEMAIL)"
	EMAILDOMAIN="`echo $ADMINEMAIL | awk -F"@" '{print $2}'`"

	if [ "$ADMINEMAIL" == "" ]; then
                echo -e "         ${RED}You cannot use a blank email address.${ENDCOLOR}"
        else
		ATCOUNT="`echo \"$ADMINEMAIL\"|grep -E -c '([[:alnum:]+\.\_\-])+@([[:alnum:]+\.\_\-])+\.([[:alnum:]+\_\-]){2,}'`"
		if [[ "$ATCOUNT" -eq "0" ]]; then
			echo -e "         ${RED}That is not a valid email address.${ENDCOLOR}"
		else
			if [ "`dig @8.8.8.8 ${EMAILDOMAIN} a +short|wc -l`" -ge "1" ]; then
				# is a publicly resolving email address domain, that's good enough for us
				break
			else
				# is not a publicly resolving email address domain
		                echo -e "         ${RED}'${EMAILDOMAIN}' does not publicly resolve. Please try again.${ENDCOLOR}"
				paramINVALID="1"
			fi
		fi
        fi
done


# Install the basic authentication security layer for the wp-admin area?
if [ "${paramSec}" == "n" ]; then 
        #echo -e "Not installing wp-admin security prompt ... ${GREEN}Done${ENDCOLOR}"
	echo -n ''
elif [[ "$(isCpanelInstalled)" -eq "1" ]]; then
        echo -e "Basic Auth prompt will not be installed (not currently compatible)"
else
	paramINVALID="0"
	while [ "1" -eq "1" ]; do
	        if [ "${paramSec}" != "" ] && [ "${paramINVALID}" == "0" ]; then
	                BASICAUTH="${paramSec}"
		else
		        echo -n -e " ${YELLOW}$(incrementQuestion)/${TOTALQUESTIONS}.${ENDCOLOR} Install a Basic Auth prompt for the admin area? (Y/N, ENTER for Y)${CYAN}:${ENDCOLOR} "
		        read BASICAUTH
		fi
	        BASICAUTH="$(lowercase $BASICAUTH)"
	        BASICAUTH="$(trim $BASICAUTH)"
	
	        if [ "$BASICAUTH" == "y" ] || [ "$BASICAUTH" == "" ]; then
			secureWPAdminFolder="yes"
			break
		elif [ "$BASICAUTH" == "n" ]; then
			secureWPAdminFolder="no"
			break
		else
	                echo -e "         ${RED}Invalid input. Please try again.${ENDCOLOR}"
		        paramINVALID="1"
	        fi
	done
fi



#################################################### Interrogation Phase - END

echo -e "${ENDCOLOR}"

##################################################### Processing Phase - BEGIN

# Install the needed CentOS components.
echo -n "Checking/Installing required packages ..... "
#yum -yt install expect.`uname -i`
yum -yt -e 0 install expect.`uname -i`|grep -v "Nothing to do\|Setting up Install Process\|Excluding Packages in global exclude list\|already installed and latest version\|^Finished$"
echo -e "${GREEN}Done${ENDCOLOR}"

# Purge the old source file.
if [ -f /tmp/$WPFILENAME ]; then
        echo -n "Removing old WordPress source file ........ "
        rm -rf /tmp/$WPFILENAME
        echo -e "${GREEN}Done${ENDCOLOR}"
fi

# Purge the old source folder.
if [ -d /tmp/wordpress ]; then
        echo -n "Removing old WordPress source folder ...... "
        rm -rf /tmp/wordpress
        echo -e "${GREEN}Done${ENDCOLOR}"
fi

# make sure that PHP is reachable
if [ -f wpinstaller_wordpressphptester.php ]; then
	rm -f wpinstaller_wordpressphptester.php
fi
testWebserverAndPhpVersion
	



# Download latest WordPress version.
if [ ! -f /tmp/$WPFILENAME ]; then
        echo -n "Downloading latest WordPress .............. "

        wgetSourceBool=0
        DOWNLOADATTEMPTS=1
        MAXDOWNLOADATTEMPTS=5
        while [[ "$wgetSourceBool" -eq "0" ]] && [[ "$DOWNLOADATTEMPTS" -lt "$MAXDOWNLOADATTEMPTS" ]]; do
                wgetSourceBool="`wget $WPDOWNLOADURL -O /tmp/$WPFILENAME 2>&1|grep \"Saving to\\|unspecified\"|wc -w`"
		wgetSourceBool="$(trim $wgetSourceBool)"
#                echo "wgetSourceBool: '$wgetSourceBool'"
#                echo "wgetSourceBool: '$(trim $wgetSourceBool )'"
                DOWNLOADATTEMPTS="`expr ${DOWNLOADATTEMPTS} + 1`"
                if [[ "$wgetSourceBool" -eq "0" ]]; then
                        sleep 1
                        echo -n "Attempt $DOWNLOADATTEMPTS/$MAXDOWNLOADATTEMPTS... "
                        wgetSourceBool="`wget $WPDOWNLOADURL -O /tmp/$WPFILENAME 2>&1|grep \"Saving to\\|unspecified\"|wc -w`"
			wgetSourceBool="$(trim $wgetSourceBool)"
                fi
        done
        if [[ "$wgetSourceBool" -gt "0" ]]; then
                echo -e "${GREEN}Done${ENDCOLOR}"
                echo -n "Installing WordPress base ................. "
                tar -C /tmp -xzf /tmp/$WPFILENAME
                rm -rf /tmp/$WPFILENAME
        else
                echo -e "${RED}Failed!${ENDCOLOR}"
                echo ""
                echo="`wget $WPDOWNLOADURL -O /tmp/$WPFILENAME` 2>&1"
                echo "Unable to download the WordPress source code from: $WPDOWNLOADURL"
                echo ""
                exit 1
        fi
fi


	if [ "${DBHOSTIP}" == "127.0.0.1" ]; then
		HOSTTOGRANT="localhost"
	else
		HOSTTOGRANT="`ifconfig eth1|grep "inet addr"|awk '{print $2}'|awk -F":" '{print $2}'`"
	fi

        if [ "${DBHOSTIP}" == "127.0.0.1" ]; then
#echo; echo "DEBUG: localhost db creation"; echo
mysql -hlocalhost mysql --password=$MYSQLSUPERPASS -u$MYSQLSUPERUSER <<EOF
create database $DBNAME;
GRANT ALL PRIVILEGES ON $DBNAME.* TO '$DBUSER'@'$HOSTTOGRANT' IDENTIFIED BY '$DBPASS';
GRANT ALL PRIVILEGES ON $DBNAME.* TO '$DBUSER'@'127.0.0.1' IDENTIFIED BY '$DBPASS';
flush privileges;
EOF
        else
#echo; echo "DEBUG: non-localhost db creation"; echo
mysql -h$DBHOST mysql --password=$MYSQLSUPERPASS -u$MYSQLSUPERUSER <<EOF
create database $DBNAME;
GRANT ALL PRIVILEGES ON $DBNAME.* TO '$DBUSER'@'$HOSTTOGRANT' IDENTIFIED BY '$DBPASS';
GRANT ALL PRIVILEGES ON $DBNAME.* TO '$DBUSER'@'127.0.0.1' IDENTIFIED BY '$DBPASS';
flush privileges;
EOF
        fi

/bin/cp -r /tmp/wordpress/* .
if [ ! -f wp-config.php ]; then
	cp wp-config-sample.php wp-config.php
	sed -i -e "s/database_name_here/$DBNAME/g" wp-config.php
	sed -i -e "s/username_here/$DBUSER/g" wp-config.php
	sed -i -e "s/password_here/$DBPASS/g" wp-config.php
	sed -i -e "s/localhost/$DBHOST/g" wp-config.php
	while [ "`grep -c 'put your unique phrase here' wp-config.php`" -gt "0" ]; do
		# echo "phrases still needing to be replaced: `grep -c 'put your unique phrase here' wp-config.php`"
                tempRandomString=$(randomString 100)
# sed inline replace fails on centos 3.9 for first occurrence replacements. it simply doesn't write to file
#                sed -i -e "0,/put your unique phrase here/s/put your unique phrase here/${tempRandomString}/" wp-config.php
                sed -e "0,/put your unique phrase here/s/put your unique phrase here/${tempRandomString}/" wp-config.php > wp-config.php.tmp
		cat wp-config.php.tmp > wp-config.php
	done
	rm -f wp-config.php.tmp
fi

mkdir wp-content/uploads
touch .htaccess

applyPermissions

# give DONE message for the end of base WordPress install
echo -e "${GREEN}Done${ENDCOLOR}"

# install cli added themes
if [ "${paramThemes}" != "" ]; then
	echo -n "Installing client themes (CLI Option) ..... "
	if [ "`echo "${paramThemes}"|grep -c "\.zip$"`" -eq "1" ]; then

		EXTRANEOUSFOLDER="themes"
		EXTRANEOUSSOURCE="${paramThemes}"
		EXTRANEOUSFOLDERRESULT="`unzip -l ${EXTRANEOUSSOURCE} |awk '{print $4}'|grep -v "^Name$\|^\-\-\-\-$"|awk -F"/" '{print $1}'|grep "."|sort|uniq|grep -c "^${EXTRANEOUSFOLDER}$"`"
		if [ "${EXTRANEOUSFOLDERRESULT}" -eq "1" ]; then
			unzip -o -q ${EXTRANEOUSSOURCE} -d ${installDir}/wp-content/
		else
			unzip -o -q ${EXTRANEOUSSOURCE} -d ${installDir}/wp-content/${EXTRANEOUSFOLDER}/
		fi

		applyPermissions

		echo -e "${GREEN}Done${ENDCOLOR}"
	else
                echo -e "${RED}Failed (Only .zip is supported at this time.)${ENDCOLOR}"
	fi
fi

# install cli added plugins
if [ "${paramPlugins}" != "" ]; then
	echo -n "Installing client plugins (CLI Option) .... "
	if [ "`echo "${paramPlugins}"|grep -c "\.zip$"`" -eq "1" ]; then

		EXTRANEOUSFOLDER="plugins"
		EXTRANEOUSSOURCE="${paramPlugins}"
		EXTRANEOUSFOLDERRESULT="`unzip -l ${EXTRANEOUSSOURCE} |awk '{print $4}'|grep -v "^Name$\|^\-\-\-\-$"|awk -F"/" '{print $1}'|grep "."|sort|uniq|grep -c "^${EXTRANEOUSFOLDER}$"`"
		if [ "${EXTRANEOUSFOLDERRESULT}" -eq "1" ]; then
			unzip -o -q ${EXTRANEOUSSOURCE} -d ${installDir}/wp-content/
		else
			unzip -o -q ${EXTRANEOUSSOURCE} -d ${installDir}/wp-content/${EXTRANEOUSFOLDER}/
		fi

		applyPermissions

		echo -e "${GREEN}Done${ENDCOLOR}"
	else
                echo -e "${RED}Failed (Only .zip is supported at this time.)${ENDCOLOR}"
	fi
fi




if [[ "$(isCpanelInstalled)" -eq "1" ]] && [[ "`echo \"\`pwd\`\" | grep '/home/.*/www\|/home/.*/public_html'|wc -l`" -eq "1" ]]; then
	chgrp nobody ../public_html
fi

if [ "$secureWPAdminFolder" == "yes" ]; then
	###########################################
	## wp-admin folder security open
	## Added by Laws - 7/20/2011
	##
	## Adding secuser/secpass to /home/httpd/.htpasswd file
	
	echo -n "Installing Basic Auth for wp-admin page ... "

	# if /home/httpd exists
	if [ -d "/home/httpd" ]; then
		# if /home/httpd/.htpasswd does not exist, create it
		if [ ! -f "/home/httpd/.htpasswd" ]; then
			touch /home/httpd/.htpasswd
		fi
	fi

        if [[ "`htpasswd 2>&1|grep 'command not found'|wc -l`" -eq "0" ]]; then
                # MojoHost & DirectAdmin have htpasswd in the environment path
                htpasswd -bs /home/httpd/.htpasswd ${SECUSER} ${SECPASS} 2>&1 |grep -v " password for"
        elif [ -f /usr/local/apache/bin/htpasswd ]; then
                # this is cPanel specific
                /usr/local/apache/bin/htpasswd -bs /home/httpd/.htpasswd ${SECUSER} ${SECPASS} 2>&1 |grep -v " password for"
        else
                echo -e "${RED}Unable to locate htpasswd!${ENDCOLOR}"
                exit
        fi

	## Touching .htaccess
	if [ -f "wp-admin/.htaccess" ]; then
			echo -e "${RED}Failed! (wp-admin/.htaccess already exists, MUST ADD WP-ADMIN SECURITY BY HAND)"
		else
			#echo ".htaccess does not exist in wp-admin, creating"
			touch wp-admin/.htaccess
echo "AuthType Basic
AuthName 'Authenticate'
AuthUserFile /home/httpd/.htpasswd
Require user ${SECUSER}" >> wp-admin/.htaccess
			echo -e "${GREEN}Done${ENDCOLOR}"
	fi
	
	##
	## wp-admin folder security close
	############################################
fi
	


## wp-content/uploads .htaccess for non php/html close
###########################################################



registeredBool=0
REGISTERATTEMPTS=1
MAXREGISTERATTEMPTS=5


ftpasswdPath="`which ftpasswd 2>/dev/null`"
ftpasswdPath="$(trim $ftpasswdPath)"

if [ "$ftpasswdPath" == "" ]; then
        echo -e "Installing autoupdate FTP account ......... ${RED}Failed! The 'ftpasswd' command could not be found!${ENDCOLOR}"
else
	# only setup auto ftp for non cpanel and non direct admin installs. Which "implies" it's a MojoHost install.
	if [[ "$(isCpanelInstalled)" -eq "0" ]] || [[ "$(isDirectAdminInstalled)" -eq "0" ]]; then
		#define('FS_METHOD', 'ftpext');
	        #define('FTP_HOST', 'localhost');
		#define('FTP_USER', 'username');
		#define('FTP_PASS', 'password');
		
		echo -n "Installing autoupdate FTP account ......... "
		if [[ "`grep "'FTP_HOST'\|'FTP_USER'\|'FTP_HOST'" wp-config.php | grep -v -P '^[ \t]*#'|wc -l`" -eq "0" ]]; then
			ftpPassword="$(randomString 40)"
	#		echo "${ftpPassword}" | ftpasswd --name ${DBNAME}_autoftp --home ${installDir} --uid ${InstallUID} --gid ${InstallGID} --stdin
	
			FTPSETUPRESULT="`echo "${ftpPassword}" | ftpasswd --name ${DBNAME}_autoftp --home ${installDir} --uid ${InstallUID} --gid ${InstallGID} --stdin 2>&1`"
	
			FTPSETUP="`echo "${FTPSETUPRESULT}"| grep -c "ftpasswd: entry created"`"
			if [ "${FTPSETUP}" -eq "1" ]; then
				# auto ftp account was setup
				echo "define('FTP_HOST', 'localhost');" >> wp-config.php
				echo "define('FTP_USER', '${DBNAME}_autoftp');" >> wp-config.php
				echo "define('FTP_PASS', '${ftpPassword}');" >> wp-config.php
		                echo -e "${GREEN}Done${ENDCOLOR}"
			else
				# auto ftp account setup failed
		                echo -e "${RED}Failed!${ENDCOLOR}"
	
				echo
				echo "FTPSETUPRESULT - BEGIN"
				echo "${FTPSETUPRESULT}"
				echo "FTPSETUPRESULT - END"
				echo
			fi
		fi
	fi
fi

echo -n "Registering WP-Admin page ................. "
if [[ -f wp-admin/.htaccess ]]; then
	mv wp-admin/.htaccess wp-admin/.htaccess.installwptemp
fi
while [[ "$registeredBool" -eq "0" ]] && [[ "$REGISTERATTEMPTS" -lt "$MAXREGISTERATTEMPTS" ]]; do
	#wget -O - --post-data="weblog_title=$INSTDOM&user_name=$ADMINUSER&admin_password="$ADMINPASS"&admin_password2="$ADMINPASS"&admin_email="$ADMINEMAIL"&blog_public=1&Submit=Install+WordPress" "http://"$INSTDOM"/wp-admin/install.php?step=2" 2>&1|grep -i "has been installed"|wc -w
	if [ "$secureWPAdminFolder" == "yes" ]; then
		registeredBool="`wget -O - --post-data=\"weblog_title=$INSTDOM&user_name=$ADMINUSER&admin_password=$ADMINPASS&admin_password2=$ADMINPASS&admin_email=$ADMINEMAIL&blog_public=1&Submit=Install+WordPress\" \"http://${SECUSER}:${SECPASS}@$INSTDOM/wp-admin/install.php?step=2\" 2>&1|grep -i \"has been installed\"|wc -w`"
	else
		registeredBool="`wget -O - --post-data=\"weblog_title=$INSTDOM&user_name=$ADMINUSER&admin_password=$ADMINPASS&admin_password2=$ADMINPASS&admin_email=$ADMINEMAIL&blog_public=1&Submit=Install+WordPress\" \"http://$INSTDOM/wp-admin/install.php?step=2\" 2>&1|grep -i \"has been installed\"|wc -w`"
	fi
	registeredBool="$(trim $registeredBool)"
	#echo "registeredBool: $registeredBool"
        REGISTERATTEMPTS=`expr ${REGISTERATTEMPTS} + 1`
        if [[ "$registeredBool" -eq "0" ]]; then
                sleep 1
                echo -n "$REGISTERATTEMPTS/$MAXREGISTERATTEMPTS ... "
	else
		break
        fi
done

if [[ -f wp-admin/.htaccess.installwptemp ]]; then
	mv wp-admin/.htaccess.installwptemp wp-admin/.htaccess
fi

if [[ "$registeredBool" > "0" ]]; then
	echo -e "${GREEN}Done${ENDCOLOR}"


	if [[ -f wp-admin/.htaccess ]]; then
	        mv wp-admin/.htaccess wp-admin/.htaccess.installwptemp
	fi
	pluginURL="downloads.wordpress.org/plugin/w3-total-cache.latest-stable.zip" && pluginFilename="w3-total-cache.zip" && installPlugin
	pluginURL="downloads.wordpress.org/plugin/update-notifier.latest-stable.zip" && pluginFilename="update-notifier.zip" && installPlugin
	applyPermissions

	echo -n "Activating plugins ......... "

	# WordPress Plugin Activation - BEGIN
	chown nobody wp-config.php
	wpAdminLogin $INSTDOM $ADMINUSER $ADMINPASS
	WP_ADMIN_SEARCHSTRING='update-notifier' && wpAdminPluginActivator
	WP_ADMIN_SEARCHSTRING='w3-total-cache' && wpAdminPluginActivator && wpAdminPluginW3tcBasicDiskCacheEnabler
	chown $InstallUID wp-config.php
	rm -f wpinstallercookies.txt
	# WordPress Plugin Activation - END

	if [[ -f wp-admin/.htaccess.installwptemp ]]; then
	        mv wp-admin/.htaccess.installwptemp wp-admin/.htaccess
	fi

        echo -e "${GREEN}Done${ENDCOLOR}"

	# Purge the old source folder.
	if [ -d /tmp/wordpress ]; then
	        echo -n "Cleaning up ............................... "
	        (
	        rm -rf /tmp/wordpress
	        )
	fi
	
        if [[ ! -d /tmp/wordpress ]] && [[ ! -f /tmp/$WPFILENAME ]]; then
		echo -e "${GREEN}Done${ENDCOLOR}"
	else
		echo -e "${RED}Failed!${ENDCOLOR}"
	fi

	echo ""
	echo -e "Please use the following text block when responding to your ticket."

CREDBLOCK="

WordPress Information (Created: `date +'%x @ %R'`):
============================================================
Blog URL: http://$INSTDOM
Blog Admin URL: http://$INSTDOM/wp-admin

"

	if [ "$secureWPAdminFolder" == "yes" ]; then
CREDBLOCK="${CREDBLOCK}1st Login Prompt (Secures wp-admin folder - helps prevent XSS attacks!)
Username: $SECUSER
Password: $SECPASS

2nd Login Prompt (Actual wp-admin login)
"
	fi

CREDBLOCK="${CREDBLOCK}Admin Username: $ADMINUSER
Admin Password: $ADMINPASS
Admin Email Address: $ADMINEMAIL
============================================================
"

	echo "${CREDBLOCK}" >> ${WPCREDS}

	echo -e "${GREEN}${CREDBLOCK}${ENDCOLOR}"
else
	#wget -O - --post-data="weblog_title=$INSTDOM&user_name=$ADMINUSER&admin_password=$ADMINPASS&admin_password2=$ADMINPASS&admin_email=$ADMINEMAIL&blog_public=1&Submit=Install+WordPress" "http://$INSTDOM/wp-admin/install.php?step=2"
	#echo "`wget -O - --post-data=\"weblog_title=$INSTDOM&user_name=$ADMINUSER&admin_password=$ADMINPASS&admin_password2=$ADMINPASS&admin_email=$ADMINEMAIL&blog_public=1&Submit=Install+WordPress\" \"http://$INSTDOM/wp-admin/install.php?step=2\" 2>&1`"
	echo ""
	echo -e "${RED}WordPress Installation Failed!${ENDCOLOR}"
	#echo "Please examine the output above, then visit the URL below to complete the WordPress install."
	echo ""
        if [ "$secureWPAdminFolder" == "yes" ]; then
		echo "Please visit http://${SECUSER}:${SECPASS}@$INSTDOM/wp-admin to diagnose and/or complete the WordPress install."
	else
		echo "Please visit http://$INSTDOM/wp-admin to diagnose and/or complete the WordPress install."
	fi
	#echo "Please visit the URL below to diagnose and complete this WordPress install:"
	echo ""
	#echo "http://${SECUSER}:${SECPASS}@${INSTDOM}/wp-admin/install.php?step=2&weblog_title=${INSTDOM}&user_name=${ADMINUSER}&admin_password=${ADMINPASS}&admin_password2=${ADMINPASS}&admin_email=${ADMINEMAIL}&blog_public=1&Submit=Install+WordPress"
	#echo ""
	echo "wget -O - --post-data=\"weblog_title=$INSTDOM&user_name=$ADMINUSER&admin_password=$ADMINPASS&admin_password2=$ADMINPASS&admin_email=$ADMINEMAIL&blog_public=1&Submit=Install+WordPress\" \"http://$INSTDOM/wp-admin/install.php?step=2\""
fi

####################################################### Processing Phase - END

trap - INT
