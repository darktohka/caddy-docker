FROM --platform=$BUILDPLATFORM caddy:builder-alpine AS builder

ARG TARGETPLATFORM

RUN \
  if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
  export GOARCH="arm64"; \
  elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then \
  export GOARCH="arm"; \
  else \
  export GOARCH="amd64"; \
  fi && \
  xcaddy build \
  --with github.com/caddy-dns/cloudflare \
  --with github.com/WeidiDeng/caddy-cloudflare-ip \
  --with github.com/mholt/caddy-dynamicdns

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
