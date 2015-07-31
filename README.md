# docker-hadoop-monitoring

```bash
docker pull avkanavt/hadoop-monitoring:latest
docker run -d --net=host -v /etc/localtime:/etc/localtime:ro -v /var/lib/monitoring/grafana:/var/lib/grafana -v /var/lib/monitoring/graphite/storage/whisper:/opt/graphite/storage/whisper -v /var/log/dockers/hadoop-monitoring:/var/log/supervisor -p 80:80 -p 8650:8650 --name hadoop-monitoring docker.io/avkanavt/hadoop-monitoring:latest
```
