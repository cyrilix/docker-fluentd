FROM alpine:3.12
LABEL Description="Fluentd docker image" Version="1.11.4"

ARG FLUENTD_VERSION=1.11.4

# Do not split this into multiple RUN!
# Docker creates a layer for every RUN-Statement
# therefore an 'apk delete' has no effect
RUN apk update \
 && apk add --no-cache \
        ca-certificates \
        ruby ruby-irb ruby-etc ruby-webrick \
        tini libmaxminddb geoip \
 && buildDeps=" \
      make gcc g++ libc-dev \
      wget bzip2 zlib-dev git linux-headers \
      automake autoconf libtool build-base \
      ruby-dev libc6-compat geoip-dev \
    " \
 && apk add --no-cache --virtual .build-deps \
        build-base \
        ruby-dev gnupg \
 && apk add $buildDeps \
 && echo 'gem: --no-document' >> /etc/gemrc \
 && gem install oj -v 3.10.15 \
 && gem install http_parser.rb -v 0.5.3 \
 && gem install tzinfo -v 1.2.7 \
 && gem install json -v 2.3.1 \
 && gem install async-http -v 0.52.5 \
 && gem install ext_monitor -v 0.1.2 \
 && gem install fluentd -v ${FLUENTD_VERSION} \
 && gem install prometheus-client -v 0.9.0 \
 && gem install bigdecimal -v 1.4.4 \
 && gem install fluent-plugin-kubernetes_metadata_filter -v 2.5.2 \
 && gem install \
         specific_install \
         fluent-plugin-remote-syslog \
         fluent-plugin-webhdfs \
         fluent-plugin-elasticsearch \
         fluent-plugin-prometheus \
         fluent-plugin-s3 \
         fluent-plugin-rewrite-tag-filter \
         fluent-plugin-azurestorage \
         fluent-plugin-oss \
         fluent-plugin-dedot_filter \
         fluent-plugin-sumologic_output \
         fluent-plugin-kafka \
         fluent-plugin-geoip \
         fluent-plugin-label-router \
         fluent-plugin-tag-normaliser \
         fluent-plugin-grafana-loki \
         fluent-plugin-concat \
         fluent-plugin-kinesis \
         fluent-plugin-parser-logfmt \
         fluent-plugin-detect-exceptions \
         fluent-plugin-multi-format-parser \
         fluent-plugin-record-modifier \
         fluent-plugin-logzio \
         fluent-plugin-newrelic \
         fluent-plugin-splunk-hec \
         elasticsearch-xpack \
         fluent-plugin-cloudwatch-logs \
         fluent-plugin-throttle \
         fluent-plugin-logdna \
         fluent-plugin-datadog \
         fluent-plugin-aws-elasticsearch-service \
         fluent-plugin-redis \
 && gem specific_install -l https://github.com/banzaicloud/fluent-plugin-gcs.git \
 && apk del .build-deps $buildDeps \
 && rm -rf /tmp/* /var/tmp/* /usr/lib/ruby/gems/*/cache/*.gem /usr/lib/ruby/gems/2.*/gems/fluentd-*/test

RUN addgroup -S fluent && adduser -S -G fluent fluent \
    # for log storage (maybe shared with host)
    && mkdir -p /fluentd/log \
    # configuration/plugins path (default: copied from .)
    && mkdir -p /fluentd/etc /fluentd/plugins \
    && chown -R fluent /fluentd && chgrp -R fluent /fluentd \
    && mkdir -p /buffers && chown -R fluent /buffers


COPY fluent.conf /fluentd/etc/
COPY entrypoint.sh /bin/
COPY healthy.sh /bin/


ENV FLUENTD_CONF="fluent.conf"

ENV LD_PRELOAD=""
EXPOSE 24224 5140

USER fluent
ENTRYPOINT ["tini",  "--", "/bin/entrypoint.sh"]
CMD ["fluentd"]
