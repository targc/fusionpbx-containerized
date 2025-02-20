#!/bin/bash

/usr/src/fusionpbx-install.sh/debian/resources/post-install.sh

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

cat > /etc/freeswitch/autoload_configs/event_socket.conf.xml <<EOF
<configuration name="event_socket.conf" description="Socket Client">
  <settings>
    <param name="nat-map" value="false"/>
    <param name="listen-ip" value="0.0.0.0"/>
    <param name="listen-port" value="8021"/>
    <param name="password" value="${X_FREESWITCH_ESL_PASSWORD}"/>
    <!--<param name="apply-inbound-acl" value="lan"/>-->
    <param name="apply-inbound-acl" value="0.0.0.0/0"/>
  </settings>
</configuration>
EOF

fs_cli -x "reloadxml"
systemctl restart freeswitch

# init db (one-time execute)
/usr/src/fusionpbx-install.sh/debian/resources/initialize-db.sh
