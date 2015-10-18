#!/bin/bash
# GNS3 v1 installer (developer version)
# Usage: sudo installGNS3v1.sh
# Report problems to rednectar.chris@gmail.com


###############################################################################
#		History
###############################################################################
# v1.0 - First version based mainly on http://forum.gns3.net/post27906.html
# v1.1 - Developer version options, uses git instead of wget.
#		 wget options now get the latest RELEASE version
#        Fixed after alpha3 broke v1.0 by including --version option
# v1.2   Fixed dynamips install
#        Fixed python installer to ALWAYS include: build-essential; libelf-dev,   
#        uuid-dev, libpcap-dev, python3-dev, and python3-pyqt4 
#        installs vboxwrapper, virtualbox and qemu if not installed
# v1.3   2014-08-18
#        Added Daniel Lintott's gns3-converter to pip install
#	     See http://forum.gns3.net/post35824.html
# v1.4   2014-08-20
#        Now upgrades pip packages if already installed
#        Added --version and --Full options
# v1.5   2014-08-23
#        Avoid "Press <Enter> to continue if --full or --Full"  
#		 Enhanced --version output
# v1.6   2014-09-27
#        Typo in usage expression (from ./installGNS3v1.sh --help)
#        Fix bug where directories didn't get created on first run
#        Fix bug where vboxwrapper didn't install
#        Fix bug where VPCS didn't get upgraded of version 0.5b0 was detected
#        Create launch icons for desktop
#        Improved error handling (much more to do)
# v1.7   2014-10-14
#        Change directory for Qemu from "Qemu" to "QEMU" to match GUI's default
# v1.8   2014-10-22
#        Fix problem where not all python dependencies were being installed
# v2.0   2014-10-23
#        Modify to suit v1.0 (no beta)
#        Bump to version 2.0
# v2.1   2014-11-11
#        Add python-setuptools to bundle of python stuff to install
#        (Hopefully) fixes errors involving "No module named setuptools"
#		 -v option also check vboxwrappper version
# v3.0   2014-11-12
#        Adapted for 64 bit install (Still experimental)
#        Moved image directory for ASA and Junos under the QEMU directory
# v3.1   2014-12-09
#        Cope with version longer than 2 digits like v1.2.1
# v3.2   2014-12-30
#        Added cpulimit install (so Qemu devices can be have the cpu limited)
#        Added installs for tunctl and brctl so tap interfaces could be created
#        Fix bug in installApp function (a line had been deleted sometime (shift))
# v3.3   2015-02-01
#        * Added ppa:gns3 to the repository search
#        * Tidied up error checking around pip installs [Useless really - later
#           worked out that I don't really need pip any more]     
#        * If doing an archive install, now checks to see if latest gns3 is 
#          installed before pulling down source
#        * Updates based on https://community.gns3.com/docs/DOC-2165
#          - Removed anything to do with vboxwrapper 
#          - Get iouyap from https://github.com/GNS3/iouyap/releases/ now  
#            rather than sourceforge
#        * removed pip install components (apt-get install works now)
#        * added displaying of important messages at the end of the install
#  v3.4  After reading http://askubuntu.com/questions/284306/why-is-gksu-no-longer-installed-by-default
#        I decided NOT to add the sudo GNS3 icon to the desktop.  This was
#        precipitated by the fact that I found gksudo was not installed by
#        default in Ubuntu 14.04 anyway
# v3.5   2015-02-04
#        Fixed bug in gns3-gui install if direcory didn't exist
# v3.6   2015-02-08
#	     Added permissions to dynamips so GNS3 doesn't have to be run as sudo
# v3.7   2015-02-021
#	     Put an extra check in for iouyap install after
#		 https://community.gns3.com/people/valarmorghulis/blog/2015/02/17/gns3-linux-mint-installation-issues
# v3.8   2015-02-25
#        Add message about updating path to dynamips
# v3.9   2015-02-28
#        Seems the iouyap inside the .tgz file for iuoyap is not executable - 
#        added a chmod +x after extracting
# v4.0   2015-03-05
#        https://community.gns3.com/thread/7198 says tornado and ws4py is no longer needed so removed
#        2015-03-12
#        Now get latest code from github at github.com/GNS3/gns3-[gui|server]/tree/rest-api
#        Fixed kludgy version detector so alpha and beta versions are ignored
#        so that only release versions are downloaded
# v4.1   2015-03-15
#        Add  virtualbox-dkms to virtualbox install (to fix broken vb install)
# v4.2   2015-03-28
#        Seems the development branch has moved from "asyncio" and "rest-api" back to "master"
#        https://community.gns3.com/message/23640#23640
# v4.3   2015-05-03
#        Updated fall back vpcs install to v0.6 rather than 0.5b
# v4.4   2015-04-04 [May the fourth be with you]
#        Seems that (esp in 64 bit install) the ppa doesn't get updated properly so after 
#        reading http://askubuntu.com/questions/30072/how-do-i-fix-a-problem-with-mergelist-or-status-file-could-not-be-parsed-err 
#        I added a line:         rm /var/lib/apt/lists/* -vf
#        Also, I only did half the job in v4.3 when the development branch 
#        moved from "asyncio" and "rest-api" back to "master". Fixed it
###############################################################################
#		Initialise Variables
###############################################################################
installerVersion="4.4"
installerDate="2015-05-04"
installerFriendlyName="GNS3v1 Installer"
gns3Version="" #To be sure 

## File variables
importantGNS3InstallMessages=/var/log/GNS3v1installer.log


## Directory variables
GNS3Path="${HOME}/GNS3"
GNS3ImagesPath="${GNS3Path}/images"
GNS3ProjectsPath="${GNS3Path}/projects"
GNS3SourcePath="${GNS3Path}/source"
GNS3IOSImagesPath="${GNS3ImagesPath}/IOS"
GNS3IOUImagesPath="${GNS3ImagesPath}/IOU"
GNS3QEMUImagesPath="${GNS3ImagesPath}/QEMU"
GNS3ASAImagesPath="${GNS3QEMUImagesPath}/ASA"
GNS3JunosImagesPath="${GNS3QEMUImagesPath}/Junos"
tempDir="/tmp"
gns3SharedResourcesPath="/usr/share/gns3"
installerPath=${0%/*} #Extract Path from $0 paramter
installerName=${0#${installerPath}} #Extract Name from $0 paramter
usage="sudo $0 [ [-f|--full] | [-F|--Full] | [-v|--version] ]"
fullUsage="$usage\n\n
--full | -f - full archive install\n
--Full | -F  - full developer install\n
--version | -v - print version of major components and exit"

fullInstall=false
developerInstall=false
## Counters and constants
stageCount=1
hostBits=$(getconf LONG_BIT)

## Colour constants
black=0
red=1
green=2
yellow=3
blue=4
purple=5
cyan=6
white=7
inverseOn=$(tput rev)
boldOn=$(tput bold)
normal=$(tput sgr0)
ulOn=$(tput smul)
ulOff=$(tput rmul)
whiteOnBlueOn=$(tput setab $blue;tput setaf $white)
whiteOnRedOn=$(tput setab $red;tput setaf $white)
whiteOnGreenOn=$(tput setab $green;tput setaf $white)
brightWhiteOnBlueOn=$(tput setab $blue;tput setaf $white;tput bold)
brightWhiteOnRedOn=$(tput setab $red;tput setaf $white;tput bold)
brightWhiteOnGreenOn=$(tput setab $green;tput setaf $white;tput bold)
redOn=$(tput setaf $red;tput bold)
yellowOn=$(tput setaf $yellow;tput bold)
greenOn=$(tput setaf $green;tput bold)
padding="                "

###############################################################################
#		Functions
###############################################################################
function createDir()
#$1 Full path to directory to be created. parent directory must exist
#   or the program will exit 1
{ 
if  [ ! -d "$1" ] ; then 
	mkdir "$1"
	#Let's check that that worked
	if (($?==1)) ; then
		echo "Unable to create $1"
		echo "Make sure this direcrtory exists and try again"
		exit 1
	else #It worked, so change the owner if running as sudo
		if [ ! "$SUDO_USER" == "" ] ; then
			chown $SUDO_USER "$1"
		fi
	fi 
fi
}
###############################################################################
function installApp ()
#$1 must be true or false to indicate "Interactive y/n"
#$2 Friendly app name eg SSH
#$3... list of apps that have to be got with apt-get install
{
local interactive=$1
local appName=$2
local count=$#
local returnValue=0
if $interactive ; then
	read -p "Install $appName? y/n[y]" installAppResponse
else
	installAppResponse="y"
fi
if [ "$installAppResponse" = "y" ] || [ "$installAppResponse" = "" ] ; then
	for (( i=3; i<=$count; i++ )) do
		doInstall=true
		while $doInstall ; do
			sudo apt-get install $3 -y
			if [ "$?" = "0" ] ; then
				doInstall=false
			else
				echo -e "\n\nThere was a problem installing $3"
				read -p "Try again y/n [y] " installResponse
				if [[ "$installResponse" =~ ^[n|N] ]] ; then
					doinstall=false
					return 1
				fi
			fi
		done
		shift
	done
else
	echo "$appName not installed"
fi
return $returnValue
}

##############################################################################
function checkPkgInstalled ()
#$1..n names of packages to be checked
#Returns 0 if ALL packages are installed
#        1 if ANY package ins NOT installed
{
local returnValue=1
local i=$#

while [ $i -gt 0 ] && [ $returnValue = 1 ] ; do
	pkgInstalled=$(dpkg-query -W --showformat='${Status}\n' $1|grep "install ok installed")
	if [ "$pkgInstalled" != "install ok installed" ] ; then 
		returnValue=0
	fi
	i=$[$i-1]
	shift
done

return $returnValue
}

##############################################################################
function displayVersions ()

{
date
echo -e "${brightWhiteOnGreenOn}Component\t\t\t${brightWhiteOnBlueOn} Version\t${normal}"
paddedVersion="${installerVersion}${padding}"
echo -e "${whiteOnGreenOn}$installerFriendlyName, $installerDate:\t${whiteOnBlueOn} ${paddedVersion::15}${normal}"
if (which dynamips > /dev/null 2>&1) ; then
	dynamipsVersion="$(dynamips 2>&1 | grep version | sed 's/^.*version //' | sed 's/-.*$//')"
	paddedVersion="${dynamipsVersion}${padding}"
	echo -e "${whiteOnGreenOn}Dynamips:\t\t\t${whiteOnBlueOn} ${paddedVersion::15}${normal}"
else
	echo -e "${whiteOnRedOn}Dynamips:\t\t\tNot installed\t${normal}"

fi
if (which gns3 > /dev/null 2>&1) ; then
	gns3Version="$(gns3 --version)"
	paddedVersion="${gns3Version}${padding}"
	echo -e "${whiteOnGreenOn}GNS3 GUI:\t\t\t${whiteOnBlueOn} ${paddedVersion::15}${normal}"
else
	echo -e "${whiteOnRedOn}GNS3 GUI:\t\t\tNot installed\t${normal}"

fi
if (which gns3server > /dev/null 2>&1) ; then
	gns3serverVersion="$(gns3server --version)                "
	paddedVersion="${gns3serverVersion}${padding}"
	echo -e "${whiteOnGreenOn}GNS3 Server:\t\t\t${whiteOnBlueOn} ${paddedVersion::15}${normal}"
else
	echo -e "${whiteOnRedOn}GNS3 Server:\t\t\tNot installed\t${normal}"

fi

if (which gns3-converter > /dev/null 2>&1) ; then
	gns3ConverterVersion="$(gns3-converter --version 2>&1 | grep converter | sed 's/^.*converter //' | sed 's/-.*$//')              "
	paddedVersion="${gns3ConverterVersion}${padding}"
	echo -e "${whiteOnGreenOn}GNS3 Topology Converter:\t${whiteOnBlueOn} ${paddedVersion::15}${normal}"
else
	echo -e "${whiteOnRedOn}GNS3 Topology Converter:\tNot installed\t${normal}"
fi

if (which iouyap > /dev/null 2>&1) ; then
	iouyapVersion="$(iouyap -V 2>&1 | grep version | sed 's/^.*version //' | sed 's/-.*$//')               "
	paddedVersion="${iouyapVersion}${padding}"
	echo -e "${whiteOnGreenOn}iouyap:\t\t\t\t${whiteOnBlueOn} ${paddedVersion::15}${normal}"
else
	echo -e "${whiteOnRedOn}iouyap:\t\t\t\tNot installed\t${normal}"
fi
if (which qemu-i386 > /dev/null 2>&1) ; then
	qemuVersion="$(qemu-i386 -version 2>&1 | egrep 'version ' | sed 's/^.*version //' | sed 's/ .*$//')              "
	paddedVersion="${qemuVersion}${padding}"
	echo -e "${whiteOnGreenOn}QEMU:\t\t\t\t${whiteOnBlueOn} ${paddedVersion::15}${normal}"
else
	echo -e "${whiteOnRedOn}QEMU:\t\t\t\tNot installed\t${normal}"
fi
<<NO_MORE_VBOXWRAPPER
if (which vboxwrapper > /dev/null 2>&1) ; then
	vboxwrapperVersion="$(vboxwrapper -v 2>&1 | grep version | sed 's/^.*version //' | sed 's/).*$//')              "
	echo -e "${whiteOnGreenOn}vboxwrapper:\t\t\t${whiteOnBlueOn} ${vboxwrapperVersion::15}${normal}"
else
	echo -e "${whiteOnRedOn}vboxwrapper:\t\t\tNot installed\t${normal}"
fi
NO_MORE_VBOXWRAPPER

if (which virtualbox > /dev/null 2>&1) ; then
	virtualboxVersion=$(virtualbox -help 2>&1 | egrep 'VirtualBox Manager' | sed 's/^.*Manager //' | sed 's/).*$//')"      "
	paddedVersion="${virtualboxVersion}${padding}"
	echo -e "${whiteOnGreenOn}virtualbox:\t\t\t${whiteOnBlueOn} ${paddedVersion::15}${normal}"
else
	echo -e "${whiteOnRedOn}virtualbox:\t\t\tNot installed\t${normal}"
fi


if (which vpcs > /dev/null 2>&1) ; then
	vpcsVersion="$(vpcs -v 2>&1 | grep version | sed 's/^.*version //' | sed 's/-.*$//' | tr -d '\r')              "
	paddedVersion="${vpcsVersion}${padding}"
	echo -e "${whiteOnGreenOn}Virtual PC Simulator:\t\t${whiteOnBlueOn} ${paddedVersion::15}${normal}"
else
	echo -e "${whiteOnRedOn}Virtual PC Simulator:\t\tNot installed\t${normal}"
fi
if (which wireshark > /dev/null 2>&1) ; then
	wiresharkVersion="$(wireshark -v 2>&1 | egrep 'wireshark ' | sed 's/^.*wireshark //' | sed 's/ .*$//')              "
	paddedVersion="${wiresharkVersion}${padding}"
	echo -e "${whiteOnGreenOn}wireshark:\t\t\t${whiteOnBlueOn} ${paddedVersion::15}${normal}"
else
	echo -e "${whiteOnRedOn}wireshark:\t\t\tNot installed\t${normal}"
fi
date
return	
}
###############################################################################
# 		Parse command line
###############################################################################

if [ "$1" = "-f" ] || [ "$1" = "--full" ] ; then
	fullInstall=true 
elif [ "$1" = "-F" ] || [ "$1" = "--Full" ] ; then
	fullInstall=true
	developerInstall=true
elif [ "$1" = "-v" ] || [ "$1" = "--version" ]; then
	displayVersions
	exit 0
elif ! [ "$1" = "" ] ; then
	#there are paramaters passed, need to be parsed
	echo -e "Parameter :$1: not recognised"
	echo -e "usage:"
	echo -e $fullUsage
	exit 1
fi	
###############################################################################
# 		Usage Checks
###############################################################################

if [ ! $(id -u) -eq 0 ]  ; then 
        echo "Must be run as sudo: eg:"
		echo -e $usage
        exit 1
fi
if [ "$SUDO_USER" == "" ] ; then
        echo "Can't be run as user 'root'."
		echo "Must be run as normal user running sudo: eg"
		echo -e $usage
        exit 1
fi

if [ -f ${importantGNS3InstallMessages} ] ; then
	rm ${importantGNS3InstallMessages}
fi



###############################################################################
#		Main()
###############################################################################


clear
echo -e $brightWhiteOnGreenOn"################# Chris' Crude GNS3v1 installer : version ${installerVersion} #################$normal
This script attempts to setup the GNS3v1 on your existing Linux system.
It is based on instructions at http://forum.gns3.net/post27906.html
http://forum.gns3.net/topic8988.html and https://github.com/GNS3/gns3-server
http://forum.gns3.net/post28922.html and http://forum.gns3.net/topic11444.html
If you have problems, please refer to the forum posts.  Good Luck\n
It will, depending on the type of install you choose:
* Create my recommended directory structure for you
* Install git (developer install)
* Install subversion (developer install)
* Install bison parser generator (developer install)
* Install flex lexical analyzer (developer install)
* Install all the python stuff you need
* Install dynamips
* Install VirtualBox
* Install Qemu
* Install iouyap -Ref: http://forum.gns3.net/topic8966.html
* Fix link to libssl1.0.0 -Ref: http://forum.gns3.net/topic8988.html
* Install SSH
* Install htop
* Install Wireshark 
* Install VPCS
* Install BBE
* Install ROXTerm
* Install cpulimit (to limit cpu use for qemu)
* Install tunctl and brctl so tap interfaces could be created
* Create a iourc file for you (you'll have to add your own licence)
* Add an entry to your hosts file for xml.cisco.com
* Install gns3-server
* Install gns3-gui
* Create desktop shortcuts for you
\n${redOn}Red${yellowOn}Nectar${normal}\n" | more
if  ! ${fullInstall}  ; then 
	read -p "Press <Enter> to continue" response
fi

echo "
$brightWhiteOnGreenOn###############################################################################"$normal
response=""
interactive=false
if ! $fullInstall ; then
	while [ "$response" = "" ] ; do
		echo -e "\nAn ${greenOn}archive install${normal} installs dynamips from the deb repository, and gns3 
components from the latest${brightWhiteOnGreenOn} release version ${normal}using wget (Safest option)\n
A ${redOn}developer install${normal} pulls latest development sourcecode for dynamips,
iouyap, vpcs, gns3-server and gns3-gui using git clone or git pull (or svn for
vpcs). This is the${brightWhiteOnRedOn} bleeding edge ${normal}code.\n
${redOn}F${normal}ull install options re-installs everything - no questions asked
Note: Will not overwrite iourc if it exists
Normally, supplemtary apps like pip and ssh are skipped if already installed.
The full archive install can also be invoked using the -full command line 
option.\n
Would you like:
a. an interactive ${greenOn}a${normal}rchive (${brightWhiteOnGreenOn}release version${normal}) install?
A. an ${greenOn}A${normal}rchive (${brightWhiteOnGreenOn}release version${normal}) install? - no questions asked.
f. a ${greenOn}f${normal}ull archive install? - re-installs everything. No questions asked.\n
d. an interactive ${redOn}d${normal}eveloper (${brightWhiteOnRedOn}bleeding edge${normal}) install?
D. a ${redOn}D${normal}eveloper (${brightWhiteOnRedOn}bleeding edge${normal}) install? - no questions asked.
F. a ${redOn}F${normal}ull developer install? - re-installs everything. No questions asked.\n
q. quit. Get me out of here!\n" | more

		read -p "a/A/d/D/f/F/q [a] " response 
		if [ "$response" = ""  ] ; 
			then response="a" ; 
		fi
		if [ "$response" = "q" ] ; then
			echo "OK - Come back when you are ready"
			exit 1
		elif [ "$response" = "a" ] ; then
			interactive=true
			fullInstall=false
		elif [ "$response" = "A" ] ; then
			interactive=false
			fullInstall=false
		elif [ "$response" = "d" ] ; then
			interactive=true
			developerInstall=true
			fullInstall=false
		elif [ "$response" = "D" ] ; then
			interactive=false
			developerInstall=true
			fullInstall=false
		elif [ "$response" = "f" ] ; then
			interactive=false
			fullInstall=true
		elif [ "$response" = "F" ] ; then
			interactive=false
			developerInstall=true
			fullInstall=true
		else
			echo "Invalid response. Try again"
			response=""
		fi
	done;
fi


if  $interactive ; then
	echo "OK - you get to choose - default is always YES"
else
	echo -e "HOLD ON - Here we go on auto-pilot: YES to everything.
		However, there may be places where you need to press ENTER or 
		follow other instructions.  Keep watching!"
	response="y"
fi

###############################################################################
###############################################################################
#		Installers()
###############################################################################
###############################################################################

if ! [ -d "${GNS3Path}" ] ||  \
   ! [ -d "${GNS3IOSImagesPath}" ] || \
   ! [ -d "${GNS3IOUImagesPath}" ] || \
   ! [ -d "${GNS3QEMUImagesPath}" ] || \
   ! [ -d "${GNS3ASAImagesPath}" ] || \
   ! [ -d "${GNS3JunosImagesPath}" ] || \
   ! [ -d "${GNS3ProjectsPath}" ] || \
   ! [ -d "${gns3SharedResourcesPath}" ] || \
   ! [ -d "${HOME}/VirtualBox VMs" ] || \
   (! [ -d "${GNS3SourcePath}" ] &&  $developerInstall ); then

	echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion} 
	     :- Building RedNectar's recommended directory structure will create
	        the following:
		 ${GNS3Path}
		 ${GNS3ImagesPath}
		 ${GNS3IOSImagesPath}
		 ${GNS3IOUImagesPath}
		 ${GNS3QEMUImagesPath}
		 ${GNS3ASAImagesPath}
		 ${GNS3JunosImagesPath}
		 ${GNS3ProjectsPath}
		 ${gns3SharedResourcesPath}
		 ${HOME}/VirtualBox VMs"$normal
	if $developerInstall ; then
		echo $brightWhiteOnGreenOn"		 ${GNS3SourcePath}"$normal
	fi
	if $interactive ; then
		read -p "Build recommended directory structure? y/n[y]" response
	fi

	if [  "$response" = "y" ] || [	 "$response" = ""  ] ; then
		createDir "${GNS3Path}"
		createDir "${GNS3ImagesPath}"
		createDir "${GNS3IOSImagesPath}"
		createDir "${GNS3IOUImagesPath}"
		createDir "${GNS3QEMUImagesPath}"
		createDir "${GNS3ASAImagesPath}"
		createDir "${GNS3JunosImagesPath}"
		createDir "${GNS3ProjectsPath}"
		createDir "${gns3SharedResourcesPath}"
		createDir "${HOME}/VirtualBox VMs"
		if $developerInstall ; then
			createDir "${GNS3SourcePath}"
		fi
	else
		echo -e "Skipping directory creation:"
	fi
fi

#Github
###############################################################################
if $developerInstall ; then

	echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
	     :-Github version control for developer install.
	     :[REQUIRED for developer install]"$normal
	which git 2>&1
	if [ $? != "0" ] || $fullInstall ; then
		installApp $interactive "Github version control" git 
		if [ $? = "1" ] ; then
			echo "Unable to install github version control."
			echo "github version control is required for developer install"
			exit 1
		fi
	else
		echo "git already installed: Skipping."
	fi
fi

#svn
###############################################################################
if $developerInstall ; then

	echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
	     :-svn version control for developer install. (required for vpcs)"$normal
	which svn 2>&1
	if [ $? != "0" ] || $fullInstall ; then
		installApp $interactive "subversion version control (svn)" subversion 
		if [ $? = "1" ] ; then
			echo "Unable to install svn version control."
			echo "svn version control is required for developer install"
			exit 1
		fi
	else
		echo "svn already installed: Skipping."
	fi
fi
#bison
###############################################################################
if $developerInstall ; then

	echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
	     :-bison for developer install. (required for iouyap)"$normal
	which bison 2>&1
	if [ $? != "0" ] || $fullInstall ; then
		installApp $interactive "Bison parser generator" bison 
		if [ $? = "1" ] ; then
			echo "Unable to install Bison parser generator."
			echo "Bison parser generator is required for developer install"
			exit 1
		fi
	else
		echo "bison already installed: Skipping."
	fi
fi
###############################################################################
if $developerInstall ; then

	echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
	     :-flex for developer install. (required for iouyap)"$normal
	which flex 2>&1
	if [ $? != "0" ] || $fullInstall ; then
		installApp $interactive "Flex lexical analyzer" flex 
		if [ $? = "1" ] ; then
			echo "Unable to install Flex lexical analyzer."
			echo "Flex lexical analyzer is required for developer install"
			exit 1
		fi
	else
		echo "flex already installed: Skipping."
	fi
fi
#update repository ppa:gns3/ppa
###############################################################################
echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
     :-Repositories Update [REQUIRED to be able to download latest dynamips and vpcs]"$normal
if $interactive ; then
	read -p "Update repositories? y/n[y]" response
fi
if [  "$response" = "y" ] || [	 "$response" = ""  ] ; then
	if [ -f /var/lib/apt/lists/lock ] ; then sudo rm /var/lib/apt/lists/lock ; echo "/var/lib/apt/lists/lock removed" ; fi
	if [ -f /var/cache/apt/archives/lock ] ; then sudo rm /var/cache/apt/archives/lock ; echo "/var/cache/apt/archives/lock removed" ;fi
	rm /var/lib/apt/lists/* -vf # Added after reading http://askubuntu.com/questions/30072/how-do-i-fix-a-problem-with-mergelist-or-status-file-could-not-be-parsed-err
	echo  "$brightWhiteOnRedOn Press <Enter> now (or when requested)$normal"
    sudo add-apt-repository ppa:gns3/ppa
	sudo apt-get update -y
else
	echo "Repositories not updated"
fi
###############################################################################
echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
     :-python3-pyqt4 package will also pull in python3-sip package as a dep, 
       which is also needed for the GUI.
      -[Required - allow about 20min]"$normal
# which python3 2>&1 ;#does not work - just becaue python3 is installed doesn't
# mean the development bits are installed too 
# Note https://community.gns3.com/thread/7198 says tornado and ws4py is no longer needed
#if $fullInstall || checkPkgInstalled build-essential libelf-dev uuid-dev libpcap-dev python3-dev python3-pyqt4 python3-setuptools python3-ws4py python3-netifaces python3-zmq python3-tornado python-setuptools; then
#	installApp $interactive "python3-pyqt4 packages" build-essential libelf-dev uuid-dev libpcap-dev python3-dev python3-pyqt4 python3-setuptools python3-ws4py python3-netifaces python3-zmq python3-tornado python-setuptools 
if $fullInstall || checkPkgInstalled build-essential libelf-dev uuid-dev libpcap-dev python3-dev python3-pyqt4 python3-setuptools python3-netifaces python3-zmq python-setuptools; then
	installApp $interactive "python3-pyqt4 packages" build-essential libelf-dev uuid-dev libpcap-dev python3-dev python3-pyqt4 python3-setuptools python3-netifaces python3-zmq python-setuptools 
	if [ $? = "1" ] ; then
		echo "Unable to install all required python packages."
		echo "Python packages are required for developer install"
		exit 1
	fi

else
	echo "python3 already installed: Skipping."
fi
 ###############################################################################
echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
     :-latest Dynamips code from github OR from repository
       (Note: developer install from github uses git - non developer uses wget)
      -[Required]"$normal
if $interactive && $developerInstall ; then
	read -p "Download dynamips from [g]ithub or [r]epository or [n]one? g/r/n[g] " dynamipsResponse
elif $interactive ; then # && therefore NOT $developer install
	read -p "Download dynamips from [g]ithub or [r]epository or [n]one? g/r/n[r] " dynamipsResponse
else
	dynamipsResponse=""
fi

if [ "$dynamipsResponse" = ""  ] ; then
	if $developerInstall ; then
		dynamipsResponse="g"
	else
		dynamipsResponse="r"
	fi
fi

if [  "$dynamipsResponse" = "r" ]  ; then
	installApp false "dynamips" dynamips
elif [  "$dynamipsResponse" = "g" ] ; then
	echo "Updating dynamips code from github"
	if $developerInstall ; then
		cd ${GNS3SourcePath}
		if [ -d dynamips ] ; then  # Assume it's been cloned if the directory exists 
			cd dynamips
			git pull origin master
			cd build
		else
			sudo apt-get install cmake -y
			git clone --branch=master git://github.com/GNS3/dynamips
			cd dynamips
			mkdir build
			cd build
			cmake ..
		fi
	else
		cd ~/Downloads
		wget -O dynamips-master.zip https://github.com/GNS3/dynamips/archive/master.zip
		#Unzip into the location of your choice
		unzip -o dynamips-master.zip
		cd dynamips-master
	fi
	make
	sudo make install
else #[  "$dynamipsResponse" = "n" ]
	echo "dynamips code not updated"
fi
#Test it out to make sure it works:
dynamipsVersion=$(dynamips 2>&1 | grep version | sed 's/^.*version //' | sed 's/-.*$//')

if [ "${dynamipsVersion}" == "" ] ;  then
	echo -e "dynamips failed to install - aborting"
	exit 1
else
	echo -e "Dynamips version ${dynamipsVersion} is installed. 
	Fixing permissions so GNS3 can be run without sudo"
	setcap cap_net_raw,cap_net_admin+eip $(which dynamips)
	echo "Make sure you set GNS3 Preferences < Dynamips > [General Settings] | Path to Dynamips: to $(which dynamips)" | tee -a ${importantGNS3InstallMessages} 

fi


#Then we'll need to make sure that we have pip and setuptools installed for Python 3.x -- easiest way to do this is the following:

<<FORGET_PIP
###############################################################################
echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
     :-pip and setuptools. 
       pip is used to get some pre-req python modules for GNS3...
      -[Required - allow 20 mins]"$normal
which pip 2>&1
if [ $? != "0" ] || $fullInstall ; then
	if $interactive ; then
		read -p "Download and install pip and setuptools y/n[y]" response
	fi
	if [  "$response" = "y" ] || [	 "$response" = ""  ] ; then
		echo "Downloading and installing pip and setuptools"
		cd ~/Downloads
		wget -O get-pip.py https://raw.github.com/pypa/pip/master/contrib/get-pip.py
		echo "Running get-pip.py"
		sudo -u ${SUDO_USER} python3 get-pip.py 2>&1

		#Now let's use pip to get some pre-req python modules for GNS3...

		echo "Installing pyzmq"
		sudo -u ${SUDO_USER} pip3 install pyzmq 2>&1
		if [ $? ] ; then 
			echo "Upgrading pyzmq"
			sudo -u ${SUDO_USER} pip3 install pyzmq --upgrade
		fi

		echo "Installing tornado"
		sudo -u ${SUDO_USER} pip3 install tornado 2>&1
		if [ $? ] ; then 
			echo "Upgrading tornado"
			sudo -u ${SUDO_USER} pip3 install tornado --upgrade 
		fi

		echo "Installing netifaces"
		sudo -u ${SUDO_USER} pip3 install netifaces 2>&1
		if [ $? ] ; then 
			echo "Upgrading netifaces"
			sudo -u ${SUDO_USER} pip3 install netifaces --upgrade 
		fi
		

		# These will all download and compile code, and then install the resulting modules. 
		# The pyzmq one in particular will compile a lot of things, and warn early on that 
		# it can't find an existing libzmq installation -- that's OK, it will build it's 
		# own one during the compilation. Just let it run after the warning.

	fi
else
	echo "pip already installed: Skipping."
fi
FORGET_PIP
###############################################################################
<<GNS3_CONVERTER_INCLUDED_IN_GNS3
echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
     :-gns3-converter 
      -[Optional - only required if needing to upgrade GNS3 v0.8.x topologies]"$normal

which gns3-converter 2>&1
if [ $? != "0" ] || $fullInstall ; then
	if $interactive ; then
		read -p "Download and install gns3-converter? y/n[y]" response
	fi
	if [  "$response" = "y" ] || [	 "$response" = ""  ] ; then
		echo "Downloading and installing gns3-converter"
		sudo -u ${SUDO_USER} pip3 install gns3-converter 2>&1
		if [ $? ] ; then 
			sudo -u ${SUDO_USER} pip3 install gns3-converter --upgrade 2>&1
		fi
	else
		echo "gns3-converter not installed"
	fi
else
	echo "gns3-converter already installed. Skipping."
fi
GNS3_CONVERTER_INCLUDED_IN_GNS3
###############################################################################
<<NO_MORE_VBOXWRAPPER 
echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
     :-vboxwrapper 
      -[Required to run VirtualBox images]"$normal

which vboxwrapper 2>&1
if [ $? != "0" ] || $fullInstall ; then
	if $interactive ; then
		read -p "Download and install vboxwrapper? y/n[y]" response
	fi
	if [  "$response" = "y" ] || [	 "$response" = ""  ] ; then
		echo "Downloading and installing python2.7 tools required for vboxwrapper"
		sudo apt-get install python2.7-dev
		wget https://bootstrap.pypa.io/ez_setup.py -O - | python2.7

		echo "Downloading vboxwrapper"
		if $developerInstall ; then
			cd ${GNS3SourcePath}
			if [ -d vboxwrapper ] ; then  # Assume it's been cloned if the directory exists 
				cd vboxwrapper
				echo "Pulling master"
				git pull origin master
				if [ $? != "0" ] ; then
					echo "Unable to download vboxwrapper source. Aborting"
					exit 1
				fi
			else
				echo "Cloning to ${GNS3SourcePath}"
				git clone --branch=master git://github.com/GNS3/vboxwrapper
				if [ $? != "0" ] ; then
					echo "Unable to download vboxwrapper source. Aborting"
					exit 1
				fi
				cd vboxwrapper
			fi
			python2.7 setup.py install
		else
			cd ~/Downloads
			wget -O vboxwrapper.zip https://github.com/GNS3/vboxwrapper/archive/master.zip
			unzip -o vboxwrapper.zip
			cd vboxwrapper-master
			python2.7 setup.py install
		fi
		
	else
		echo "vboxwrapper not installed"

<<DeleteMe
		cd ${gns3SharedResourcesPath}
		git clone --branch=master git://github.com/GNS3/vboxwrapper
		echo "Installing python setuptools"
		wget https://bootstrap.pypa.io/ez_setup.py -O - | python
		echo "Installing vboxwrapper"
		cd vboxwrapper
		python2.7 setup.py install
DeleteMe
	fi


else
	echo "vboxwrapper already installed. Skipping."
fi
NO_MORE_VBOXWRAPPER

#Also, don't forget iouyap. From the Debian Jessie guide:
#4 - Install iouyap
 ###############################################################################
echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
     :-iouyap - This binary is in charge of all the networking side of IOU 
       ref:  http://forum.gns3.net/topic8966.html
      -[Required to run IOU images]"$normal
which iouyap 2>&1
if [ $? != "0" ] || $fullInstall ; then
	if $interactive ; then
		read -p "Download and install iouyap? y/n[y]" response
	fi
	if [  "$response" = "y" ] || [	 "$response" = ""  ] ; then
		echo "Downloading iouyap"
		if $developerInstall ; then
			cd ${GNS3SourcePath}
			if [ -d iniparser ] ; then  # Assume it's been cloned if the directory exists 
				cd iniparser
				echo "Pulling iniparser master"
				git pull origin master
				if [ $? != "0" ] ; then
					echo "Unable to download iniparser source. Aborting"
					exit 1
				fi

			else
				echo "Cloning to ${GNS3SourcePath}"
				git clone --branch=master http://github.com/ndevilla/iniparser.git
				if [ $? != "0" ] ; then
					echo "Unable to download iniparser source. Aborting"
					exit 1
				fi
				cd iniparser
			fi

			make
			cp libiniparser.* /usr/lib/
			cp src/iniparser.h /usr/local/include
			cp src/dictionary.h /usr/local/include
			cd ${GNS3SourcePath}

			if [ -d iouyap ] ; then  # Assume it's been cloned if the directory exists 
				cd iouyap
				echo "Pulling iouyap master"
				git pull origin master
				if [ $? != "0" ] ; then
					echo "Unable to download iouyap source. Aborting"
					exit 1
				fi

			else
				echo "Cloning iouyap to ${GNS3SourcePath}"
				git clone --branch=master git://github.com/GNS3/iouyap
				if [ $? != "0" ] ; then
					echo "Unable to download iouyap source. Aborting"
					exit 1
				fi
				cd iouyap
			fi

			make
			make install
			cp iouyap /usr/local/bin/iouyap
		else
			cd ~/Downloads
			iouyapVersion=$(wget -O- http://github.com/GNS3/iouyap/releases 2<&1 | egrep -m 1 Version\  | sed 's#^.*Version\ ##' | sed 's#</a>##')

	        if  (which iouyap > /dev/null 2>&1)  && [ "$(iouyap -V)" == "${iouyapVersion}" ] ; then
				echo "Latest version of iouyap is already installed"
			else
				if [ "${iouyapVersion}" == "" ] ; then
					echo "Unable to reach iouyap repository on http://github.com/GNS3/iouyap/. " | tee -a ${importantGNS3InstallMessages} 
					echo "iouyap not installed. " | tee -a ${importantGNS3InstallMessages} 
					echo "You will need to try again if you wish to run IOU images" | tee -a ${importantGNS3InstallMessages} 

				else
					wget -O iouyap.tar.gz "https://github.com/GNS3/iouyap/releases/download/${iouyapVersion}/iouyap-${hostBits}-bit.tar.gz"
					tar zxvf iouyap.tar.gz
					chmod +x iouyap
					cp iouyap /usr/local/bin/iouyap
				fi
			fi
			setcap cap_net_raw,cap_net_admin+eip $(which iouyap)
			echo "Make sure you set GNS3 Preferences < IOS on Unix > [General Settings] | Path to iouyap: to $(which iouyap)" | tee -a ${importantGNS3InstallMessages} 

		fi
	else
		echo "iouyap not installed"
	fi
else
	echo "iouyap already installed. Skipping."
fi
###############################################################################
if ! [ -f /usr/lib/libcrypto.so.4 ] ; then
	echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
	     :-libssl1.0.0 -  Fix the missing library for IOU (libssl1.0.0)
	       ref:  http://forum.gns3.net/topic8988.html
	      -[Required to run IOU images]"$normal
	if $interactive ; then
		read -p "Fix link to libssl1.0.0? y/n[y]" response
	fi
	if [  "$response" = "y" ] || [	 "$response" = ""  ] ; then
		if  [ "${hostBits}" == "64" ] ; then
			apt-get install libssl1.0.0:i386 -y
			if ! [ -f /lib/i386-linux-gnu/libcrypto.so.1.0.0 ] ; then
				echo "libcrypto.so.1.0.0 is not installed. " | tee -a ${importantGNS3InstallMessages}
				echo "Try issuing the command" | tee -a ${importantGNS3InstallMessages}
				echo "sudo apt-get install --reinstall libssl1.0.0:i386" | tee -a ${importantGNS3InstallMessages}
				echo "and then running this install again if you wish to run IOU images" | tee -a ${importantGNS3InstallMessages}
			fi
		fi
		ln -s /lib/i386-linux-gnu/libcrypto.so.1.0.0 /usr/lib/libcrypto.so.4
	fi
fi
###############################################################################
echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
     :-SSH Server [Optional]
      - useful if you wish to access your VM securely"$normal
which sshd 2>&1
if [ $? != "0" ] || $fullInstall ; then
	installApp $interactive "SSH Server" openssh-server 
	if [ $? = "1" ] ; then
		echo "Unable to install SSH server."
		echo "You can run this script again later to try again"
		read -p "Press <Enter> to continue" pressEnter
	fi

else
	echo "SSH Server already installed. Skipping."
fi
###############################################################################
echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
    :-htop utility [Optional]
      - useful alternative to top when debugging idle-PC values"$normal
which htop 2>&1
if [ $? != "0" ] || $fullInstall ; then
	installApp $interactive "htop utility" htop 
	if [ $? = "1" ] ; then
		echo "Unable to install htop utility."
		echo "You can run this script again later to try again"
		read -p "Press <Enter> to continue" pressEnter
	fi

else
	echo "SSH Server already installed. Skipping."
fi

###############################################################################
echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
     :-VirtualBox [Highly Recommended]
      - essential for VirtualBox integration"$normal
which virtualbox 2>&1
if [ $? != "0" ] || $fullInstall ; then
	installApp $interactive "VirtualBox" virtualbox-qt xdotool virtualbox-dkms
	if [ $? = "1" ] ; then
		echo "Unable to install VirtualBox."
		echo "You can run this script again later to try again"
		read -p "Press <Enter> to continue" pressEnter
	fi
else
	echo "VirtualBox already installed. Skipping."
fi
###############################################################################
echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
     :-Qemu [Highly Recommended]
      - essential for Qemu integration"$normal
which qemu-i386 2>&1
if [ $? != "0" ] || $fullInstall ; then
	installApp $interactive "Qemu" qemu
	if [ $? = "1" ] ; then
		echo "Unable to install qemu." | tee -a ${importantGNS3InstallMessages}
		echo "You can run this script again later to try again"
		read -p "Press <Enter> to continue" pressEnter
	fi

else
	echo "Qemu already installed. Skipping."
fi
###############################################################################
echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
     :-Wireshark [HIGHLY RECOMMENDED - allow 5 mins]
      - Needed to be able to use the Packet Capture feature in GNS3"$normal
which wireshark 2>&1
if [ $? != "0" ] || $fullInstall ; then
	if $interactive ; then
		read -p "Install Wireshark? y/n[y]" response
	fi
	if [  "$response" = "y" ] || [	 "$response" = ""  ] ; then
		sudo apt-get install wireshark -y
		#and so I could run it as a normal user and see interfaces:
#		sudo chgrp adm /usr/bin/dumpcap
#		sudo chmod 750 /usr/bin/dumpcap
		sudo setcap cap_net_raw,cap_net_admin+eip $(which dumpcap)

		#[Thanks to http://securityblog.gr/1195/run-wireshark-as-a-user-rather-than-root-ubuntu/]
	else
		echo "Wireshark not installed"
	fi
else
	echo "Wireshark already installed. Skipping."
fi
 ###############################################################################
echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
      :-VPCS [REQUIRED]"$normal
if $interactive && $developerInstall ; then
	read -p "Download vpcs from [s]ourceforge or [r]epository or [n]one? s/r/n[s] " vpcsResponse
elif $interactive ; then # && therefore NOT $developer install
	read -p "Download vpcs from [s]ourceforge or [r]epository or [n]one? s/r/n[r] " vpcsResponse
else
	vpcsResponse=""
fi

if [ "$vpcsResponse" = ""  ] ; then
	if $developerInstall ; then
		vpcsResponse="s"
	else
		vpcsResponse="r"
	fi
fi

if [  "$vpcsResponse" = "r" ]  ; then
	installApp false "vpcs" vpcs
	if [ $? = "1" ] ; then
		echo "Unable to install VPCS." | tee -a ${importantGNS3InstallMessages}
		echo "VPCS is a required option" | tee -a ${importantGNS3InstallMessages}
	fi

	#Check that the repository version is not 0.5b0, if so pretend they said "s" not "r"
	vpcs -v | grep "0.5b0"
	if [ $? = "0" ] ; then
		echo "Ancient version (v0.5b0) of vpcs detected. This will not do!"
		echo "VPCS will be downloaded from sourceforge"
		vpcsResponse="s"
	fi
fi

if [  "$vpcsResponse" = "s" ] ; then
	echo "Updating vpcs code from sourceforge"

	if $developerInstall ; then
		cd ${GNS3SourcePath}
		svn checkout svn://svn.code.sf.net/p/vpcs/code/trunk vpcs-code 
		cd vpcs-code/src 
	 	./mk.sh
	else
		# IF they chose to get from sourceforge, but it's not a devloper install, then
		# can't compile it - just download v0.6 from sourceforge - don't know how 
		# to do a wget of the "latest" version, so this section is going to become
		# obsolete when a new version of vpcs is released. Too bad.
		cd ~/Downloads
		wget -O vpcs http://sourceforge.net/projects/vpcs/files/0.6/vpcs_0.6_Linux${hostBits}/download
		chmod +x vpcs
	fi
	#Need to move it to where it should be - if already installed overwrite
	#if not, assume /usr/bin
	vpcsTargetPath=$(which vpcs)

	if [ $? != "0" ] ; then 
		vpcsTargetPath="/usr/bin/vpcs" 
	fi

	mv -f vpcs ${vpcsTargetPath}
	#This should install vpcs into /usr/bin
elif [ "$vpcsResponse" = "n" ] ; then
	echo "vpcs code not updated"
fi
#Test it out to make sure it works:
vpcsVersion=$(vpcs -v 2>&1 | grep version | sed 's/^.*version //' | sed 's/-.*$//')

if [ "${vpcsVersion}" == "" ] ;  then
	echo -e "vpcs failed to install" | tee -a ${importantGNS3InstallMessages}
else
	echo -e "\nvpcs version:
	${vpcsVersion}
	is installed"
fi
###############################################################################
echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
     :-BBE - a hex editor utility you may find useful
      [Recommended]"$normal
which bbe 2>&1
if [ $? != "0" ] || $fullInstall ; then
	installApp $interactive "BBE Hex editor"  bbe
	if [ $? = "1" ] ; then
		echo "Unable to install BBE Hex Editor." | tee -a ${importantGNS3InstallMessages}
		echo "You can run this script again later to try again" | tee -a ${importantGNS3InstallMessages}
		read -p "Press <Enter> to continue" pressEnter
	fi

else
	echo "BBE already installed. Skipping."
fi
###############################################################################
echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
     :-ROXTerm - a lightlweight terminal application that supports tabs
      [Recommended]"$normal
which roxterm 2>&1
if [ $? != "0" ] || $fullInstall ; then
	installApp $interactive "ROXTerm"  roxterm
	if [ $? = "1" ] ; then
		echo "Unable to install ROXTerm." | tee -a ${importantGNS3InstallMessages}
		echo "You can run this script again later to try again" | tee -a ${importantGNS3InstallMessages}
		read -p "Press <Enter> to continue" pressEnter
	fi

else
	echo "ROXTERM already installed. Skipping."
fi

###############################################################################
echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
     :-CPUlimit - allows limiting of cpu in qemu devices
      [Recommended]"$normal
which cpulimit 2>&1
if [ $? != "0" ] || $fullInstall ; then
	installApp $interactive "CPUlimit"  cpulimit
	if [ $? = "1" ] ; then
		echo "Unable to install CPUlimit." | tee -a ${importantGNS3InstallMessages}
		echo "You can run this script again later to try again" | tee -a ${importantGNS3InstallMessages}
		read -p "Press <Enter> to continue" pressEnter
	fi

else
	echo "CPUlimit already installed. Skipping."
fi
###############################################################################
echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
     :-Tools to create tap interfaces - allows you to be able to create tap interfaces
      [Recommended]"$normal
which tunctl 2>&1
tunctlInstalled=$?
which brctl 2>&1
brctlInstalled=$?
if [ $tunctlInstalled != "0" ] || [ $brctlInstalled != "0" ] || $fullInstall ; then
	installApp $interactive "Tools to create tap interfaces"  uml-utilities bridge-utils
	if [ $? = "1" ] ; then
		echo "Unable to install tools to create tap interfaces." | tee -a ${importantGNS3InstallMessages}
		echo "You can run this script again later to try again" | tee -a ${importantGNS3InstallMessages}
		read -p "Press <Enter> to continue" pressEnter
	fi

else
	echo "Tools to create tap interfaces already installed. Skipping."
fi

###############################################################################
echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
     :- IOURC file creation (you'll have to add your own licence)
        hosts file check"$normal
if [ -f "${GNS3IOUImagesPath}/iourc" ] && [ $(cat /etc/hosts | grep -c xml.cisco.com) != "0" ] ; then 
		echo "IOURC file exists, hosts file OK - skipping"
	else

	if $interactive ; then
		read -p "Create IOURC file & check hosts file y/n[y]" response
	fi
	if [  "$response" = "y" ] || [	 "$response" = ""  ] ; then
		cd "${GNS3IOUImagesPath}"
		echo "Creating IOURC file"
		## Create blank iourc licence file
		echo -e "[license]" > ${GNS3IOUImagesPath}/iourc
		echo -e "$(hostname) = 00000000000000000;" >> ${GNS3IOUImagesPath}/iourc

		echo -e "Creating file iourc in ${GNS3IOUImagesPath}" | tee -a ${importantGNS3InstallMessages}
		echo -e "After this install is finished you will need to edit" | tee -a ${importantGNS3InstallMessages}
		echo -e "${GNS3IOUImagesPath}/iourc and change the 16 hex characters" | tee -a ${importantGNS3InstallMessages}
		echo -e "00000000000000000 to your legitimate licence number.  Reading GNS3 forum posts" | tee -a ${importantGNS3InstallMessages}
		echo -e "http://forum.gns3.net/post28850.html#p28850 may assist you" | tee -a ${importantGNS3InstallMessages}
		echo -e "\nIn your GNS3 configuration specify " | tee -a ${importantGNS3InstallMessages}
		echo -e "${GNS3IOUImagesPath}/iourc in your GNS3 settings" | tee -a ${importantGNS3InstallMessages}
		chown ${SUDO_USER}:${SUDO_USER} ${GNS3IOUImagesPath}/iourc
	
		## Check hosts file
		if [ $(cat /etc/hosts | grep -c xml.cisco.com) == "0" ] ; then 
			sudo echo "127.0.0.1 xml.cisco.com" >> /etc/hosts
			echo "hosts file updated with 127.0.0.1 xml.cisco.com"
		fi


	else
		echo "IOURC file not created; hosts file not updated"
	fi

<<ALTERNATIVE_SOLUTION
    # An alternative solution to using a valid licence key is to modify your 
    # iou binary images so they don't look for a key - but that may be breaking
    # the licence agreement (the one that says you are only going to use iou while
    # you are a Cisco employee/partner)
	# See more at: http://ahsantasneem.blogspot.com.au/2012/10/cisco-l3-l2-iou-on-fedora-linux-hacked.html

	cd "${GNS3IOUImagesPath}" 
	for F in i86bi-linux-l3* ; do 
		echo "Inspecting $F"
		bbe -b "/\xfc\xff\x83\xc4\x0c\x85\xc0\x75\x14\x8b/:10" -e "r 7 \x90\x90" -o $F.x $F
		mv $F.x $F
	done
		for F in i86bi-linux-l2* ; do 
		echo "Inspecting $F"
		bbe -b "/\xa1\xff\x83\xc4\x0c\x85\xc0\x75\x17\x8b/:10" -e "r 7 \x74" -o $F.x $F
		mv $F.x $F
	done
	chmod +x ./i86bi-linux*
	chown $SUDO_USER:$SUDO_USER i86bi-linux*	
ALTERNATIVE_SOLUTION

fi

# OK, now onto the new GNS3 server... Grab the server code from Github, 
# https://github.com/GNS3/gns3-server/archive/master.zip
###############################################################################
echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
     :-latest GNS3 server code from github 
      -[Required]"$normal
if $interactive ; then
	read -p "Download and complile latest GNS3 server code from github? y/n[y]" response
fi
if [  "$response" = "y" ] || [	 "$response" = ""  ] ; then
	echo "Downloading latest GNS3 server code from github"
	if $developerInstall ; then
		cd ${GNS3SourcePath}
		if [ -d gns3-server ] ; then  # Assume it's been cloned if the directory exists 
			cd gns3-server
			git pull origin master
			#git pull origin asyncio
			if [ $? != "0" ] ; then
				echo "Unable to download gns3-server source. Aborting" | tee -a ${importantGNS3InstallMessages}
				exit 1
			fi

		else
			git clone --branch=qemu_packet_capture git://github.com/laerreal/gns3-server
#			git clone --branch=asyncio git://github.com/GNS3/gns3-server
			if [ $? != "0" ] ; then
				echo "Unable to download gns3-server source. Aborting" | tee -a ${importantGNS3InstallMessages}
				exit 1
			fi
			cd gns3-server
		fi
		sudo python3 setup.py install
	else
		## Huge kludge to "guess" the latest alpha/beta version - assume that the first time the 
		## word "beta" or alpha" is used on http://github.com/GNS3/gns3-gui/release it will
		## be followed by the latest release number!!
		## Updated 2014-10-23 - now looks for "v1.x" and extracts the "x" to get the version number
		## Still a huge kludge!!!! :)
        ## 2014-12-09  Cope with version longer than 2 digits like v1.2.1
		#		gns3Version=$(wget -O- http://github.com/GNS3/gns3-server/releases 2<&1 | egrep -m 1 v[1-9]\. | sed 's/\(^.*\)\(v[1-9]\.\)/\2/' | sed 's#\(v[1-9]\.[0-9\.]*\).*#\1#' | cut -b 2-)
		#		gns3Version=$(wget -O- http://github.com/GNS3/gns3-server/releases 2<&1 | egrep -m 1 Version | sed 's#^.*Version\ ##' | sed 's#</a>##')
		# 2015-03-12 Ignore alpha and beta versions
		gns3Version=$(wget -O- http://github.com/GNS3/gns3-server/releases 2<&1 | egrep -m 1 "Version 1\.[0-9]\.[0-9][^ab]" | sed 's#^.*Version\ ##' | sed 's#</a>##')


        if  (which gns3 > /dev/null 2>&1)  && [ "$(gns3server --version)" == "${gns3Version}" ] ; then
			echo "Latest version of GNS3 server is already installed"
		else
			gns3ServerSource="https://github.com/GNS3/gns3-server/archive/qemu_packet_capture.tar.gz"
			cd ~/Downloads
			wget -O gns3-server-${gns3Version}.tar.gz $gns3ServerSource
			if [ $? = "0" ] ; then
				tar xvf gns3-server-${gns3Version}.tar.gz
				cd gns3-server-${gns3Version}
			else
				echo "Unable to download gns3-server source. Aborting" | tee -a ${importantGNS3InstallMessages}
				exit 1
			fi
		
#			wget -O gns3-server-master.zip https://github.com/GNS3/gns3-server/archive/master.zip
#			unzip -o gns3-server-master.zip
#			cd gns3-server-master
			sudo python3 setup.py install
		fi

	fi
	# Test it out to make sure it works:
	echo "Testing gns3server"
	gns3serverVersion=$(gns3server --version)
	if [ "${gns3serverVersion}" = "" ] ; then
		echo -e "gns3server failed to install - aborting"  | tee -a ${importantGNS3InstallMessages}
		exit 1
	else
		echo -e "gns3server version ${gns3serverVersion} is installed"
	fi
fi
#download and install the GUI --
###############################################################################
echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
     :-latest GNS3 GUI code from github 
      -[Required]"$normal
if $interactive ; then
	read -p "Download and complile latest GNS3 GUI code from github? y/n[y]" response
fi
if [  "$response" = "y" ] || [	 "$response" = ""  ] ; then
	echo "Downloading latest GNS3 GUI code from github"
	if $developerInstall ; then
		cd ${GNS3SourcePath}
		if [ -d gns3-gui ] ; then  # Assume it's been cloned if the directory exists 
			cd gns3-gui
			git pull origin master
			#git pull origin rest-api
			if [ $? != "0" ] ; then
				echo "Unable to download gns3-gui source. Aborting" | tee -a ${importantGNS3InstallMessages}
				exit 1
			fi
		else
			git clone --branch=master git://github.com/GNS3/gns3-gui
			#git clone --branch=rest-api http://github.com/GNS3/gns3-gui
			if [ $? != "0" ] ; then
				echo "Unable to download gns3-gui source. Aborting" | tee -a ${importantGNS3InstallMessages}
				exit 1
			fi
			cd gns3-gui
		fi
		sudo python3 setup.py install
		#	copy icons so we can do desktop shortcuts
		cp -r "resources/images/" "${gns3SharedResourcesPath}/"
	else
		if [ "${gns3Version}" = "" ] ; then ## then they didn't download the server - unlikely, but possible, so have to do the kldge again (see above)
			gns3Version=$(wget -O- http://github.com/GNS3/gns3-gui/releases 2<&1 | egrep -m 1 "Version 1\.[0-9]\.[0-9][^ab]" | sed 's#^.*Version\ ##' | sed 's#</a>##')
		fi
        if  (which gns3 > /dev/null 2>&1)  && [ "$(gns3 --version)" == "${gns3Version}" ] ; then
			echo "Latest version of GNS3 GUI is already installed"
		else
			gns3GuiSource="https://github.com/GNS3/gns3-gui/archive/v${gns3Version}.tar.gz"
			cd ~/Downloads
			wget -O gns3-gui-${gns3Version}.tar.gz ${gns3GuiSource}
			if [ $? = "0" ] ; then
				tar xvf gns3-gui-${gns3Version}.tar.gz
				cd gns3-gui-${gns3Version}
			else
				echo "Unable to download gns3-gui source. Aborting" | tee -a ${importantGNS3InstallMessages}
				exit 1
			fi
			sudo python3 setup.py install
			#	copy icons so we can do desktop shortcuts
			cp -r "resources/images/" "${gns3SharedResourcesPath}/"
		fi
	fi
	# Test it out to make sure it works:
	# Unfortunately, the following line will launch gns3 - no way to get any
	# options to the gui 
	gns3guiVersion=$(gns3 --version)
	if [ "${gns3guiVersion}" = "" ] ; then
		echo -e "gns3 GUI failed to install - aborting"
		exit 1
	else
		echo -e "gns3 GUI version ${gns3guiVersion} is installed"
	fi
fi

#Create desktop icons
###############################################################################
echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
     :-Create launchers for desktop 
      -[Optional]"$normal

if  ! [ -f "~/Desktop/gns3.desktop" ] || \
#	! [ -f "~/Desktop/gksudo gns3.desktop" ] || \
	$fullInstall ; then

	if $interactive ; then
		read -p "Create desktop launcher for GNS3v1? y/n[y]" response
	fi
	if [  "$response" = "y" ] || [	 "$response" = ""  ] ; then
		echo "Creating desktop launcher"
		echo -e "[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=gns3 %f
Name=GNS3
Comment=GNS3 Graphical Network Simulator
Icon=${gns3SharedResourcesPath}/images/gns3.ico
Categories=Education;
MimeType=application/x-gns3;
Keywords=simulator;network;netsim;" > ~/Desktop/gns3.desktop
<<NOT_DOING_GKSUDO_ANYMORE
		echo -e "[Desktop Entry]
Version=1.0
Type=Application
Terminal=false
Exec=gksudo gns3 %f
Name=gksudo GNS3
Comment=GNS3 Graphical Network Simulator
Icon=${gns3SharedResourcesPath}/images/gns3.ico
Categories=Education;
MimeType=application/x-gns3;
Keywords=simulator;network;netsim;" > ~/Desktop/gksudo\ gns3.desktop
NOT_DOING_GKSUDO_ANYMORE
	chmod +x ~/Desktop/gns3.desktop
#	chmod +x ~/Desktop/gksudo\ gns3.desktop
	
	else
		echo "Skipping desktop launcher creation."
	fi
	echo "You may need to press F5 at the Desktop to refresh the icons for your launchers."
else
	echo "Desktop launchers exist. Skipping"
fi



#Wrap up
###############################################################################
echo -e $brightWhiteOnGreenOn"Stage $((stageCount++)) on $(date) --${installerName} ${installerVersion}
     :-Installation complete "$normal
#Make sure permissions are good
cd ~
chown -R  ${SUDO_USER}:${SUDO_USER} *
displayVersions
if [ -f ${importantGNS3InstallMessages} ] ; then
	echo "${brightWhiteOnRedOn}NOTE: there are important messages below about this installation${normal}"
	cat ${importantGNS3InstallMessages}
	echo "${brightWhiteOnGreenOn}These messages have been stored in ${importantGNS3InstallMessages}${normal}"
fi


#End of File
