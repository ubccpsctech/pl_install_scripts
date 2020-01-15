#!/usr/bin/env bash

# Installs Postgresql 11.6 on RedHat 7.7

printf "Starting installation...\n\n"

if [ $EUID -ne 0 ]; then
	printf "This script must be run as root. Aborting...\n\n"
	exit 1
fi

while [[ true ]] && [[ $quiet != 'true' ]];
    do
        read -p "This will install Postgresql 11.6 on Redhat 7.7 (Maipo) for x86_64 architecture. 
    Are you sure you want to proceed? (y/n): " yn
    case $yn in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer 'yes' or 'no': ";;
    esac
done

## System compatibility checks

IS_INSTALLED=`yum list installed | grep -c postgres`
IS_OS_7=`cat /etc/os-release | grep -c 'VERSION="7.7 (Maipo)"'`
IS_X86_64=`uname -m | grep -c 'x86_64'`

if [ $IS_INSTALLED -gt 0 ]; then
	printf "\nPostgresql is already installed. Completely remove existing application packages before running install script. Aborting..."
	exit 1
fi

if [ $IS_OS_7 -eq 0 ]; then
	printf "\nThis installation requires Redhat 7.7 (Maipo). Incorrect version detected. Aborting..."
	exit 1
fi

if [ $IS_X86_64 -ne 1 ]; then
	printf "\nThis installation requires a x86_64 architecture. Incorrect architecture detected. Aborting..."
	exit 1
fi

## Install Yum Repos and Packages

yum install https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm -y 
yum install https://download.postgresql.org/pub/repos/yum/reporpms/EL-7-x86_64/pgdg-redhat-repo-latest.noarch.rpm -y 
yum install postgresql11.x86_64  postgresql11-libs.x86_64  postgresql11-server.x86_64  -y

## Custom Postgres Configuration

# default configuration paths: 
# /var/lib/pgsql/11/data/pg_hba.conf
# /var/lib/pgsql/11/data/pg_ident.conf

DEFAULT_LOG_PATH=/var/lib/pgsql/11/logs/
CONFIG_PATH=/var/lib/pgsql/11/data/postgresql.conf

printf "\n"
read -p "Enter filesystem path to store Postgresql logs or 'return' to use default path $DEFAULT_LOG_PATH: " log_path
log_path=${name:-$DEFAULT_LOG_PATH}

read -p "PrairieLearn requires a database is configured to store PrairieLearn data.
	Enter PrairieLearn database name or press 'return' to default to 'prairielearn_production': " db_name
db_name=${db_name:-prairielearn_production}

read -p "PrairieLearn requires that a username and password is set to access the '$db_name'
	Enter username now or 'return' to default to 'prairielearn': " db_username
db_username=${db_username:-prairielearn}
read -p "	Enter password now or 'return' to default to random password: " db_password
db_password=${db_password:-`openssl rand -base64 32`}

# Run Postgres initdb as 'postgres' user
# --auth-host=md5 flag allows users to login through TCP on localhost
su - postgres -c "/usr/pgsql-11/bin/initdb --auth-host=md5"

## Change logging location
if [ log_path -ne "$DEFAULT_LOG_PATH" ]; then
	printf "\nImplementing custom logging location...\n"
	mkdir -p "$log_path"
	chown postgres:postgres "$log_path"
	sed -i "s%log_directory = 'log'%log_directory = '$log_path'%g" $CONFIG_PATH
fi

## Enable as service, update swervice with custom $data_path and start service
printf "\nEnabling 'postgresql-11' systemctl service...\n"
systemctl enable postgresql-11

printf "\nStarting 'postgresql-11' server...\n"
systemctl start postgresql-11

## Now that Postgres is running, create Prairie Learn user and DB in Postgres
su - postgres -c "createuser $db_username --login"
su - postgres -c "createdb $db_name"
export psqlAlterQuery="psql -c \"ALTER USER $db_username PASSWORD '$db_password';\""
export psqlGrantQuery="psql -c \"GRANT ALL PRIVILEGES ON DATABASE prairielearn_production TO prairielearn;\""
su - postgres -c "$psqlAlterQuery"
su - postgres -c "$psqlGrantQuery"
unset psqlAlterQuery
unset psqlGrantQuery

printf "\nTesting Postgres: \n"
PGPASSWORD=$db_password psql -U prairielearn -h localhost -p 5432 prairielearn_production -c "\l\du"

printf "

Postgres configuration:

	Database: $db_name
	User: $db_username
	Password: $db_password

Redhat VM configuration: 

	Postgresql log path: $log_path
\n	
	"

printf "\nInstallation complete.\n\n"


