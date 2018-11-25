FROM phusion/baseimage:0.9.19

#ARG SMOKED_BLOCKCHAIN=https://example.com/smoked-blockchain.tbz2

ARG SMOKE_STATIC_BUILD=ON
ENV SMOKE_STATIC_BUILD ${SMOKE_STATIC_BUILD}

ENV LANG=en_US.UTF-8
RUN apt-get update && apt-get install git curl wget -y
RUN mkdir /etc/smoked
RUN cd /etc/smoked && wget https://github.com/smokenetwork/smoked/releases/download/v0.0.5/cli_wallet-0.0.5-x86_64-linux.tar.gz && wget https://github.com/smokenetwork/smoked/releases/download/v0.0.5/smoked-0.0.5-x86_64-linux.tar.gz
RUN tar xfv smoked-0.0.5-x86_64-linux.tar.gz && tar xfv cli_wallet-0.0.5-x86_64-linux.tar.gz 

RUN useradd -s /bin/bash -m -d /var/lib/smoked smoked

RUN mkdir /var/cache/smoked && \
    chown smoked:smoked -R /var/cache/smoked

# add blockchain cache to image
#ADD $SMOKED_BLOCKCHAIN /var/cache/smoked/blocks.tbz2

ENV HOME /var/lib/smoked
RUN chown smoked:smoked -R /var/lib/smoked

VOLUME ["/var/lib/smoked"]

# rpc service:
EXPOSE 8090
# p2p service:
EXPOSE 2001

# add seednodes from documentation to image
ADD doc/seednodes.txt /etc/smoked/seednodes.txt

# the following adds lots of logging info to stdout
ADD contrib/config-for-docker.ini /etc/smoked/config.ini
ADD contrib/fullnode.config.ini /etc/smoked/fullnode.config.ini

# add normal startup script that starts via sv
ADD contrib/smoked.run /usr/local/bin/smoked-sv-run.sh
RUN chmod +x /usr/local/bin/smoked-sv-run.sh

# add nginx templates
ADD contrib/smoked.nginx.conf /etc/nginx/smoked.nginx.conf
ADD contrib/healthcheck.conf.template /etc/nginx/healthcheck.conf.template

# add PaaS startup script and service script
ADD contrib/startpaassmoked.sh /usr/local/bin/startpaassmoked.sh
ADD contrib/paas-sv-run.sh /usr/local/bin/paas-sv-run.sh
ADD contrib/sync-sv-run.sh /usr/local/bin/sync-sv-run.sh
ADD contrib/healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/startpaassmoked.sh
RUN chmod +x /usr/local/bin/paas-sv-run.sh
RUN chmod +x /usr/local/bin/sync-sv-run.sh
RUN chmod +x /usr/local/bin/healthcheck.sh

# new entrypoint for all instances
# this enables exitting of the container when the writer node dies
# for PaaS mode (elasticbeanstalk, etc)
# AWS EB Docker requires a non-daemonized entrypoint
ADD contrib/smokedentrypoint.sh /usr/local/bin/smokedentrypoint.sh
RUN chmod +x /usr/local/bin/smokedentrypoint.sh
CMD /usr/local/bin/smokedentrypoint.sh
