FROM debian:11

WORKDIR /usr/src

RUN apt-get update && apt-get install -y gnupg2 wget lsb-release

#### PRE-INSTALL
RUN apt-get update && apt-get upgrade -y
RUN wget https://packages.sury.org/php/apt.gpg && apt-key add apt.gpg
RUN echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/php.list
RUN apt-get update && apt-get upgrade -y
RUN apt-get install -y postgresql-client
# RUN wget -O - https://raw.githubusercontent.com/fusionpbx/fusionpbx-install.sh/master/debian/pre-install.sh | sh;
COPY ./fusionpbx-install.sh ./fusionpbx-install.sh

#### INSTALL
WORKDIR /usr/src/fusionpbx-install.sh/debian
RUN ./install.sh

#### PREPARE FOR POST-INSTALL
COPY ./scripts/fusionpbx/post-install.sh ./resources/post-install.sh
COPY ./scripts/fusionpbx/initialize-db.sh ./resources/initialize-db.sh

ENTRYPOINT ["/lib/systemd/systemd"]
