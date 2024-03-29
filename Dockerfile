FROM postgres:10.1
MAINTAINER Emanuel Calvo <emanuel.calvo@ayres.io>

RUN export DEBIAN_FRONTEND=noninteractive \
    && echo 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";' > /etc/apt/apt.conf.d/01norecommend \
    && apt-get update -y \
    && apt-get upgrade -y \
    && apt-get install -y curl jq haproxy python-psycopg2 git python-yaml python-requests python-six python-socks \
        python-dateutil python-pip python-setuptools python-prettytable python-wheel python-psutil python locales \
    ## Make sure we have a en_US.UTF-8 locale available
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
    && pip install python-consul click tzlocal cdiff \
    && mkdir -p /home/postgres \
    && chown postgres:postgres /home/postgres \
    # Clean up
    && apt-get remove -y python-pip python-setuptools \
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/* /root/.cache

#'python-etcd>=0.4.3,<0.5' 
# pysocks is given me error as a non-existent package, although available
# per https://packages.debian.org/stretch/python-socks 

ENV CONFDVERSION 0.11.0
RUN curl -L https://github.com/kelseyhightower/confd/releases/download/v${CONFDVERSION}/confd-${CONFDVERSION}-linux-amd64 > /usr/local/bin/confd \
    && chmod +x /usr/local/bin/confd

RUN git clone https://github.com/zalando/patroni.git /patroniSource
RUN cp patroniSource/patronictl.py /
RUN cp patroniSource/patroni.py /
ADD docker/entrypoint.sh /
RUN cp -r patroniSource/patroni /patroni/
RUN cp -r patroniSource/extras/confd /etc/confd 
#ADD patroni/patronictl.py patroni/patroni.py patroni/docker/entrypoint.sh /
#ADD patroni/patroni /patroni/
#ADD extras/confd /etc/confd
RUN ln -s patronictl.py /usr/local/bin/patronictl
RUN chmod +x patronictl.py && chmod +x patroni.py 

### Setting up a simple script that will serve as an entrypoint
RUN mkdir /data/ && touch /pgpass /patroni.yml \
    && chown postgres:postgres -R /patroni/ /data/ /pgpass /patroni.yml /etc/haproxy /var/run/ /var/lib/ /var/log/

EXPOSE 8500 5432 8008

ENV LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
USER postgres