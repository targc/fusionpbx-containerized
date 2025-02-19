#!/bin/sh

fusionpbx_dir=/etc/fusionpbx
mkdir -p $fusionpbx_dir
lock_file=$fusionpbx_dir/post-install.lock
test -f $lock_file || exit 0
touch $lock_file

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

#add the config.conf
mkdir -p /etc/fusionpbx
cp fusionpbx/config.conf /etc/fusionpbx
sed -i /etc/fusionpbx/config.conf -e s:"{database_host}:$database_host:"
sed -i /etc/fusionpbx/config.conf -e s:"{database_name}:$database_name:"
sed -i /etc/fusionpbx/config.conf -e s:"{database_username}:$database_username:"
sed -i /etc/fusionpbx/config.conf -e s:"{database_password}:$database_password:"

#update xml_cdr url, user and password
xml_cdr_username=$(dd if=/dev/urandom bs=1 count=20 2>/dev/null | base64 | sed 's/[=\+//]//g')
xml_cdr_password=$(dd if=/dev/urandom bs=1 count=20 2>/dev/null | base64 | sed 's/[=\+//]//g')
sed -i /etc/freeswitch/autoload_configs/xml_cdr.conf.xml -e s:"{v_http_protocol}:http:"
sed -i /etc/freeswitch/autoload_configs/xml_cdr.conf.xml -e s:"{domain_name}:$database_host:"
sed -i /etc/freeswitch/autoload_configs/xml_cdr.conf.xml -e s:"{v_project_path}::"
sed -i /etc/freeswitch/autoload_configs/xml_cdr.conf.xml -e s:"{v_user}:$xml_cdr_username:"
sed -i /etc/freeswitch/autoload_configs/xml_cdr.conf.xml -e s:"{v_pass}:$xml_cdr_password:"

#restart freeswitch
/bin/systemctl daemon-reload
/bin/systemctl restart freeswitch

#install the email_queue service
cp /var/www/fusionpbx/app/email_queue/resources/service/debian.service /etc/systemd/system/email_queue.service
systemctl enable email_queue
systemctl start email_queue
systemctl daemon-reload

# systemctl disable fail2ban.service
# systemctl stop fail2ban.service
# rm -f /lib/systemd/system/fail2ban.service
# rm -f /etc/init.d/fail2ban
# /bin/systemctl daemon-reload
#
# #install the event_guard service
# # cp /var/www/fusionpbx/app/event_guard/resources/service/debian.service /etc/systemd/system/event_guard.service
# # /bin/systemctl disable event_guard
# # /bin/systemctl stop event_guard
# rm -f /var/www/fusionpbx/app/event_guard/resources/service/debian.service
# rm -f /etc/systemd/system/event_guard.service
# /bin/systemctl daemon-reload

#add xml cdr import to crontab
apt install cron
(crontab -l; echo "* * * * * $(which php) /var/www/fusionpbx/app/xml_cdr/xml_cdr_import.php 300") | crontab

#welcome message
echo ""
echo ""
verbose "Installation Notes. "
echo ""
echo "   Please save this information and reboot this system to complete the install. "
echo ""
echo "   Use a web browser to login."
echo "      domain name: https://$domain_name"
echo "      username: $user_name"
echo "      password: $user_password"
echo ""
echo "   The domain name in the browser is used by default as part of the authentication."
echo "   If you need to login to a different domain then use username@domain."
echo "      username: $user_name@$domain_name";
echo ""
echo "   Official FusionPBX Training"
echo "      Fastest way to learn FusionPBX. For more information https://www.fusionpbx.com."
echo "      Available online and in person. Includes documentation and recording."
echo ""
echo "      Location:               Online"
echo "      Admin Training:          TBA"
echo "      Advanced Training:       TBA"
echo "      Continuing Education:   https://www.fusionpbx.com/training"
echo "      Timezone:               https://www.timeanddate.com/weather/usa/idaho"
echo ""
echo "   Additional information."
echo "      https://fusionpbx.com/members.php"
echo "      https://fusionpbx.com/training.php"
echo "      https://fusionpbx.com/support.php"
echo "      https://www.fusionpbx.com"
echo "      http://docs.fusionpbx.com"
echo ""
