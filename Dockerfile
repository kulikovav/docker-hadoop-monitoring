FROM     centos:7

# ---------------- #
#   Installation   #
# ---------------- #
#ENV http_proxy=http://cc.fun-box.ru:3128
#ENV https_proxy=http://cc.fun-box.ru:3128

# Install all prerequisites
#ADD     ./yum/yum.conf /etc/yum.conf
RUN     yum install -y epel-release
RUN     yum groupinstall -y "Development Tools"
RUN     yum install -y python-django-tagging python-simplejson python-memcache python-ldap pycairo \
        python-pip python-gunicorn supervisor nginx nodejs git wget curl java-1.8.0-openjdk-headless python-devel

RUN     pip install Twisted==11.1.0
RUN     pip install Django==1.5

# Install Elasticsearch
#RUN     yum localinstall -y https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.7.0.noarch.rpm

# Checkout the stable branches of Graphite, Carbon and Whisper and install from there
RUN     mkdir /src
RUN     git clone https://github.com/graphite-project/whisper.git /src/whisper            &&\
        cd /src/whisper                                                                   &&\
        git checkout 0.9.x                                                                &&\
        python setup.py install

RUN     git clone https://github.com/graphite-project/carbon.git /src/carbon              &&\
        cd /src/carbon                                                                    &&\
        git checkout 0.9.x                                                                &&\
        python setup.py install


RUN     git clone https://github.com/graphite-project/graphite-web.git /src/graphite-web  &&\
        cd /src/graphite-web                                                              &&\
        git checkout 0.9.x                                                                &&\
        python setup.py install

# Install Ganglia
RUN     yum install -y ganglia-gmetad ganglia-gmond 


# Install Grafana
#RUN     mkdir /src/grafana
#RUN     wget http://grafanarel.s3.amazonaws.com/grafana-1.9.1.tar.gz -O /src/grafana.tar.gz                   &&\
#        tar -xzf /src/grafana.tar.gz -C /src/grafana --strip-components=1 &&\
#        rm /src/grafana.tar.gz
RUN	 yum localinstall -y https://grafanarel.s3.amazonaws.com/builds/grafana-2.0.2-1.x86_64.rpm

RUN	yum install -y initscripts

# ----------------- #
#   Configuration   #
# ----------------- #

# Configure Elasticsearch
#ADD     ./elasticsearch/run /usr/local/bin/run_elasticsearch
#RUN     chown -R elasticsearch:elasticsearch /var/lib/elasticsearch
#RUN     mkdir -p /tmp/elasticsearch && chown elasticsearch:elasticsearch /tmp/elasticsearch

# Confiure Ganglia
ADD     ./ganglia/gmetad.conf /etc/ganglia/gmetad.conf
ADD     ./ganglia/gmond.conf /etc/ganglia/gmond.conf

# Configure Whisper, Carbon and Graphite-Web
ADD     ./graphite/initial_data.json /opt/graphite/webapp/graphite/initial_data.json
ADD     ./graphite/local_settings.py /opt/graphite/webapp/graphite/local_settings.py
ADD     ./graphite/carbon.conf /opt/graphite/conf/carbon.conf
ADD     ./graphite/storage-schemas.conf /opt/graphite/conf/storage-schemas.conf
ADD     ./graphite/storage-aggregation.conf /opt/graphite/conf/storage-aggregation.conf
RUN     mkdir -p /opt/graphite/storage/whisper
RUN     touch /opt/graphite/storage/graphite.db /opt/graphite/storage/index
RUN     chown -R nginx /opt/graphite/storage
RUN     chmod 0775 /opt/graphite/storage /opt/graphite/storage/whisper
RUN     chmod 0664 /opt/graphite/storage/graphite.db
RUN	cp /opt/graphite/conf/graphite.wsgi.example /opt/graphite/webapp/wsgi.py
RUN     cd /opt/graphite/webapp/graphite && python manage.py syncdb --noinput

# Configure Grafana
#ADD     ./grafana/config.js /src/grafana/config.js
ADD     ./grafana/grafana.ini /etc/grafana/grafana.ini

# Add the default dashboards
#RUN     mkdir /src/dashboards
#ADD     ./grafana/dashboards/* /src/dashboards/
ADD     ./grafana/grafana-server /usr/local/bin/run_grafana_server

# Configure nginx and supervisord
ADD     ./nginx/nginx.conf /etc/nginx/nginx.conf
ADD     ./supervisord.conf /etc/supervisord.d/supervisord.ini


# ---------------- #
#   Expose Ports   #
# ---------------- #

# Grafana
EXPOSE  80

# Gmond ports
EXPOSE  8650/udp
EXPOSE  8650



# -------- #
#   Run!   #
# -------- #

CMD     ["/bin/supervisord"]
