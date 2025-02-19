#!/bin/bash

/lib/systemd/systemd &

sleep 10

/usr/src/fusionpbx-install.sh/debian/post-install.sh

# disable fail2ban
systemctl disable fail2ban.service
systemctl stop fail2ban.service
rm -f /lib/systemd/system/fail2ban.service
rm -f /etc/init.d/fail2ban
/bin/systemctl daemon-reload

# disable event_guard
rm -f /var/www/fusionpbx/app/event_guard/resources/service/debian.service
rm -f /etc/systemd/system/event_guard.service
/bin/systemctl daemon-reload
