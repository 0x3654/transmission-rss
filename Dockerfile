FROM alpine:3 AS builder
RUN apk add --no-cache ruby build-base
WORKDIR /tmp
COPY . .
RUN gem build transmission-rss.gemspec
RUN gem install getoptlong --no-document --install-dir /build/gems
RUN gem install base64 --no-document --install-dir /build/gems
RUN gem install -N --install-dir /build/gems --bindir /build/bin transmission-rss-*.gem
RUN ruby -e 'puts RbConfig::CONFIG["ruby_version"]' > /gemver
FROM alpine:3
ARG UID=1000
ARG GID=1000
RUN apk add --no-cache ruby && \
    addgroup -g $GID ruby && \
    adduser -u $UID -G ruby -D ruby
COPY --from=builder /build/bin/transmission-rss /usr/local/bin/
COPY --from=builder /gemver /gemver
COPY --from=builder /build/gems /build/gems
RUN gemver=$(cat /gemver) && \
    mkdir -p /usr/lib/ruby/gems/${gemver} && \
    cp -a /build/gems/* /usr/lib/ruby/gems/${gemver}/
USER ruby
CMD ["transmission-rss"]
