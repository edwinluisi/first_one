#!/bin/bash

############################################
# Script to deploy Apache at Bluink env
# Script name: apache_dplymnt_bluink.sh 
# Author: Edwin Luisi
# Date: Mar 19, 2022
#
############################################

# Redirect stdout/stderr to a file
echo -e "The output information regarding this execution can be found in the apache_dplymnt_bluink-`date +"%Y-%m-%d_%H%M%S"`.log file.\n"
exec > apache_dplymnt_bluink-`date +"%Y-%m-%d_%H%M%S"`.log 2>&1

LIGHT_MAGENTA='\033[0;95m'
MAGENTA='\033[1;35m'
GREEN='\033[1;32m'
RED='\033[1;31m'
NC='\033[0m' # No Color

APACHE_DROOT_FILE='/etc/apache2/sites-available/000-default.conf'
APACHE_SVC_STATUS='systemctl status apache2.service'

if [ "$EUID" -eq 0 ]
then        
        echo -e "Performing prerequisite verification...\n"
        if grep -q 'DocumentRoot /var/www/html/public' ${APACHE_DROOT_FILE} ;
        then
                echo -e "${GREEN}SUCCESS${NC} - The 'DocumentRoot /var/www/html/public' string was found in the ${APACHE_DROOT_FILE} configuration file.\n"
        else
                echo -e "${RED}FAIL${NC} - The 'DocumentRoot /var/www/html/public' string was not found in the configuration file.\n"
                exit
        fi        

        if [[ $(apache2 -v) ]]
        then
                echo -e "${GREEN}SUCCESS${NC} - The following Apache version is installed:\n`apache2 -v`\n"
        else
                echo -e "${RED}FAIL${NC} - Apache installation not found!\n"
                exit
        fi

        if [[ `${APACHE_SVC_STATUS}` == *"active (running)"* ]]
        then
                echo -e "${GREEN}SUCCESS${NC} - Apache is up and running!\n"
        else
                echo -e "${RED}FAIL${NC} - Apache is not running!\n"
                exit
        fi     
else
   echo "This script can only be executed by root!"
   exit
fi


echo -e "\nDeploying..."
### BEGIN - Check and create the symlink ###
#
echo -e "${MAGENTA}Cheking symlink: /var/www/html/public -> /var/www/html/new-folder${NC}"
chk_symlink? () {
  test "$(readlink "${1}")";
}

SYMLINK_FILE=/var/www/html/public

if chk_symlink? "${SYMLINK_FILE}"; then
        echo -e "The $SYMLINK_FILE exists already and it is a valid symlink: \n`ls -ld ${SYMLINK_FILE}`"
else
        echo -e "There is no $SYMLINK_FILE symlink pointing to /var/www/html/new-folder."

        echo -e "${LIGHT_MAGENTA}Creating symlink: /var/www/html/public -> /var/www/html/new-folder${NC}"
        ln -s /var/www/html/new-folder /var/www/html/public
        echo -e "The $SYMLINK_FILE symlink is now created: \n`ls -ld ${SYMLINK_FILE}`"
fi
#
### END - Check and create the symlink ###


### BEGIN - Untar the new-folder ###
#
NFOLDER_FILE='/var/www/html/new-folder/index.html'

echo -e "${MAGENTA}\n\nChecking if the ${NFOLDER_FILE} file exists already...${NC}"
if [ -f "$NFOLDER_FILE" ]; then
        echo "The $NFOLDER_FILE exists already."
else
        echo -e "The $NFOLDER_FILE does not exist and will be created..."
        echo -e "${LIGHT_MAGENTA}Untarring new-folder.tar.gz file with webserver files in it to /var/www/html...${NC}"
        tar -xzvf new-folder.tar.gz -C /var/www/html/
        ls -ltr /var/www/html/new-folder/
fi
#
### END - Untar the new-folder ###


### BEGIN - new-folder owner ###
#
echo -e "${MAGENTA}\n\nMaking sure root is the /var/www/html/new-folder owner...${NC}"
chown root:root /var/www/html/new-folder
ls -ld /var/www/html/new-folder
#
### END - new-folder owner ###


### BEGIN - Basic request to the deployed page ###
#
echo -e "${MAGENTA}\n\nCalling for the new webserver content...${NC}"
curl localhost
echo -e "\n\n"
#
### END - Basic request to the deployed page ###