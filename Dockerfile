FROM debian:11.9

ARG freeswitch_version=1.10.11

ARG customer="btv"

# ci-variable
COPY ./confs/${customer}/switch.conf/ ./app/switch.conf/
COPY ./confs/${customer}/switch.scripts/ ./app/switch.scripts/

COPY fusionpbx-install.sh/debian /root/dev/fusionpbx

WORKDIR /root/dev/fusionpbx

#Update to latest packages
RUN apt-get update && apt-get upgrade -y

#Add dependencies
RUN apt-get install -y wget \
  lsb-release \
  systemd \
  systemd-sysv \
  ca-certificates \
  dialog \
  nano \
  net-tools \
  gpg \
  libpq-dev \
  libpq5 \
  snmpd \
  apt-utils
RUN echo "rocommunity public" > /etc/snmp/snmpd.conf
RUN service snmpd restart

#disable vi visual mode
RUN echo "set mouse-=a" >> ~/.vimrc

RUN ./resources/config.sh
RUN ./resources/colors.sh
RUN ./resources/environment.sh

RUN sed -i '/cdrom:/d' /etc/apt/sources.list


#IPTables
RUN resources/iptables.sh

#sngrep
RUN resources/sngrep.sh

#FusionPBX
RUN resources/fusionpbx.sh

#PHP
RUN resources/php.sh

#NGINX web server
RUN resources/nginx.sh

#FreeSWITCH

RUN apt-get update && apt-get install -y curl memcached haveged apt-transport-https
RUN apt-get update && apt-get install -y gnupg gnupg2
RUN apt-get update && apt-get install -y wget lsb-release sox
RUN apt-get update && apt-get install -y autoconf automake devscripts g++ git-core libncurses5-dev libtool make libjpeg-dev
RUN apt-get update && apt-get install -y pkg-config flac  libgdbm-dev libdb-dev gettext sudo equivs mlocate git dpkg-dev libpq-dev
RUN apt-get update && apt-get install -y liblua5.2-dev libtiff5-dev libperl-dev libcurl4-openssl-dev libsqlite3-dev libpcre3-dev
RUN apt-get update && apt-get install -y devscripts libspeexdsp-dev libspeex-dev libldns-dev libedit-dev libopus-dev libmemcached-dev
RUN apt-get update && apt-get install -y libshout3-dev libmpg123-dev libmp3lame-dev yasm nasm libsndfile1-dev libuv1-dev libvpx-dev
RUN apt-get update && apt-get install -y libavformat-dev libswscale-dev libvlc-dev python3-distutils sox libsox-fmt-all 
RUN apt-get update && apt-get install -y postgresql-client

RUN resources/switch/source-release.sh

RUN cd /usr/src/freeswitch-$freeswitch_version && make sounds-install moh-install
RUN cd /usr/src/freeswitch-$freeswitch_version && make hd-sounds-install hd-moh-install
RUN cd /usr/src/freeswitch-$freeswitch_version && make cd-sounds-install cd-moh-install


RUN mkdir -p /usr/share/freeswitch/sounds/music/default
RUN mv /usr/share/freeswitch/sounds/music/*000 /usr/share/freeswitch/sounds/music/default

# RUN	resources/switch/source-sounds.sh
RUN resources/switch/conf-copy.sh
RUN resources/switch/package-permissions.sh
RUN resources/switch/package-systemd.sh

# Preparing database
RUN resources/switch/dsn.sh

RUN resources/fail2ban.sh

# set startup script
COPY docker-start.sh /
RUN chmod +x /docker-start.sh

CMD ["/docker-start.sh"]