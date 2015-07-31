FROM     centos:7


RUN     yum install -y epel-release
RUN     yum groupinstall -y "Development Tools"
RUN     yum install -y python-django-tagging python-simplejson python-memcache python-ldap pycairo \
        python-pip python-gunicorn supervisor nginx git wget curl java-1.8.0-openjdk-headless python-devel

RUN     pip install Twisted==11.1.0
RUN     pip install Django==1.5

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

RUN     yum install -y ganglia-gmetad ganglia-gmond

RUN     yum localinstall -y https://grafanarel.s3.amazonaws.com/builds/grafana-2.0.2-1.x86_64.rpm

ADD     ./ganglia/gmetad.conf /etc/ganglia/gmetad.conf
ADD     ./ganglia/gmond.conf /etc/ganglia/gmond.conf

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
RUN     cp /opt/graphite/conf/graphite.wsgi.example /opt/graphite/webapp/wsgi.py
RUN     cd /opt/graphite/webapp/graphite && python manage.py syncdb --noinput

ADD     ./grafana/grafana.ini /etc/grafana/grafana.ini

ADD     ./grafana/grafana-server /usr/local/bin/run_grafana_server

ADD     ./nginx/nginx.conf /etc/nginx/nginx.conf
ADD     ./supervisord.conf /etc/supervisord.d/supervisord.ini


EXPOSE  80
EXPOSE  8650/udp
EXPOSE  8650



CMD     ["/bin/supervisord"]
