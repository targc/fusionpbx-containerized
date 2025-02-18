#!/bin/sh

#move to script directory so all relative paths work
cd "$(dirname "$0")"

#includes
. ./config.sh
. ./colors.sh

#database details
database_username=$X_PG_USER
database_password=$X_PG_PASSWORD
database_host=$X_PG_HOST
database_port=$X_PG_PORT

user_password=$system_password

#allow the script to use the new password
export PGPASSWORD=$database_password

#add the database schema
cd /var/www/fusionpbx && php /var/www/fusionpbx/core/upgrade/upgrade_schema.php > /dev/null 2>&1

#get the server hostname
if [ .$domain_name = .'hostname' ]; then
	domain_name=$(hostname -f)
fi

#get the ip address
if [ .$domain_name = .'ip_address' ]; then
	domain_name=$(hostname -I | cut -d ' ' -f1)
fi

#get the domain_uuid
domain_uuid=$(/usr/bin/php /var/www/fusionpbx/resources/uuid.php);

#add the domain name
psql --host=$database_host --port=$database_port --username=$database_username -c "insert into v_domains (domain_uuid, domain_name, domain_enabled) values('$domain_uuid', '$domain_name', 'true');"

#app defaults
cd /var/www/fusionpbx && /usr/bin/php /var/www/fusionpbx/core/upgrade/upgrade_domains.php

#add the user
user_uuid=$(/usr/bin/php /var/www/fusionpbx/resources/uuid.php);
user_salt=$(/usr/bin/php /var/www/fusionpbx/resources/uuid.php);
user_name=$system_username
password_hash=$(/usr/bin/php -r "echo md5('$user_salt$user_password');");
psql --host=$database_host --port=$database_port --username=$database_username -t -c "insert into v_users (user_uuid, domain_uuid, username, password, salt, user_enabled) values('$user_uuid', '$domain_uuid', '$user_name', '$password_hash', '$user_salt', 'true');"

#get the superadmin group_uuid
#echo "psql --host=$database_host --port=$database_port --username=$database_username -qtAX -c \"select group_uuid from v_groups where group_name = 'superadmin';\""
group_uuid=$(psql --host=$database_host --port=$database_port --username=$database_username -qtAX -c "select group_uuid from v_groups where group_name = 'superadmin';");

#add the user to the group
user_group_uuid=$(/usr/bin/php /var/www/fusionpbx/resources/uuid.php);
group_name=superadmin
#echo "insert into v_user_groups (user_group_uuid, domain_uuid, group_name, group_uuid, user_uuid) values('$user_group_uuid', '$domain_uuid', '$group_name', '$group_uuid', '$user_uuid');"
psql --host=$database_host --port=$database_port --username=$database_username -c "insert into v_user_groups (user_group_uuid, domain_uuid, group_name, group_uuid, user_uuid) values('$user_group_uuid', '$domain_uuid', '$group_name', '$group_uuid', '$user_uuid');"

#app defaults
cd /var/www/fusionpbx && /usr/bin/php /var/www/fusionpbx/core/upgrade/upgrade.php

