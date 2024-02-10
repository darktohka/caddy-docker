FROM caddy:builder-alpine AS builder
RUN xcaddy build \
  --with github.com/caddy-dns/cloudflare \
  --with github.com/WeidiDeng/caddy-cloudflare-ip

FROM alpine:edge

ENV \
  XDG_CONFIG_HOME=/config \
  XDG_DATA_HOME=/data

RUN \
  apk add --no-cache ca-certificates libcap mailcap && \
  mkdir -p /config/caddy /data/caddy

COPY --from=builder /usr/bin/caddy /usr/bin/caddy

WORKDIR /srv
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
