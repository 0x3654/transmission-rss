FROM alpine:3.23 AS builder
RUN apk add --no-cache ruby build-base
WORKDIR /tmp
COPY . .
RUN gem build transmission-rss.gemspec
RUN gem install getoptlong --no-document --install-dir /build/gems
RUN gem install base64 --no-document --install-dir /build/gems
RUN gem install -N --install-dir /build/gems --bindir /build/bin transmission-rss-*.gem
RUN ruby -e 'puts RbConfig::CONFIG["ruby_version"]' > /gemver
FROM alpine:3.23
ARG UID=1000
ARG GID=1000
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL org.opencontainers.image.title="transmission-rss" \
      org.opencontainers.image.description="Adds torrents from RSS feeds to Transmission" \
      org.opencontainers.image.url="https://hub.docker.com/r/0x3654/transmission-rss" \
      org.opencontainers.image.source="https://github.com/0x3654/transmission-rss" \
      org.opencontainers.image.version="${VERSION}" \
      org.opencontainers.image.created="${BUILD_DATE}" \
      org.opencontainers.image.revision="${VCS_REF}" \
      org.opencontainers.image.licenses="MIT"
# Upgrade all packages to pick up security patches not yet in the base image
# (e.g. openssl 3.5.6 with CVE-2026-31790 fix is in alpine:3.23 repos but not baked into the base layer)
RUN apk upgrade --no-cache && \
    apk add --no-cache ruby && \
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
