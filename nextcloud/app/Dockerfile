# Dockerfile for creating nextcloud container with cron. Also installs our
# custom php settings.
# From examples at https://github.com/nextcloud/docker/tree/master/.examples

FROM nextcloud:apache

RUN apt-get update && apt-get install -y \
    supervisor \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir /var/log/supervisord /var/run/supervisord

COPY supervisord.conf /etc/supervisor/
COPY php.ini /usr/local/etc/php/

ENV NEXTCLOUD_UPDATE=1

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
