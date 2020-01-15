#!/usr/bin/env bash

# Installs Prairie Learn on RedHat 7.7
# https://github.com/PrairieLearn/PrairieLearn

printf "Starting installation...\n\n"

if [ $EUID -ne 0 ]; then
	printf "This script must be run as root. Aborting...\n\n"
	exit 1
fi

while [[ true ]] && [[ $quiet != 'true' ]];
    do
        read -p "This will install Prairie Learn on Redhat 7.7 (Maipo) for x86_64 architecture. 
    Are you sure you want to proceed? (y/n): " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer 'yes' or 'no': ";;
    esac
done

# Pre-Install Dependencies Check & Installation

IS_GIT_INSTALLED=`yum list installed | grep -c git.x86_64`
IS_SITE_USER=`cat /etc/passwd | grep -c site-run`

if [ ! IS_GIT_INSTALLED ];
then
	printf '\nGit not installed. Installing Git...\n'
	yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y 
else 
	printf '\nGit installed. Skipping Git installation.\n'
fi

if [ ! IS_SITE_USER ]; 
then
	printf '\nThe user "site-user" does not exist. Adding user...\n'
	adduser site-user
else 
	printf '\nThe user "site-user" exists. Skipping user creation...\n'
fi

git clone https://github.com/PrairieLearn/PrairieLearn /home/site-run/PrairieLearn
chown -R site-run ~/PrairieLearn
