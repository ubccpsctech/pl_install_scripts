#!/usr/bin/env bash

# Installs Node JS 12 on RedHat 7.7

printf "\nStarting installation...\n\n"

IS_NODE_INSTALLED=`yum list installed | grep -c nodejs.x86_64`

if [ $EUID -ne 0 ]; then
	printf "This script must be run as root. Aborting...\n\n"
	exit 1
fi

while [[ true ]] && [[ $quiet != 'true' ]];
    do
        read -p "This will install Node JS on Redhat 7.7 (Maipo) for x86_64 architecture. 
    Are you sure you want to proceed? (y/n): " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer 'yes' or 'no': ";;
    esac
done

if [ $IS_NODE_INSTALLED ]; then
	printf "\nNode JS is already installed. Fully remove the application before installing. Aborting... \n\n"
	exit 1
fi

curl -sL https://rpm.nodesource.com/setup_13.x | bash -
yum install nodejs gcc-c++ make -y

