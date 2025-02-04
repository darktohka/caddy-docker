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
  xcaddy build d7872c3bfa673ce9584d00f01a725b93fa7bedf1 \
  --with github.com/caddy-dns/cloudflare \
  --with github.com/WeidiDeng/caddy-cloudflare-ip \
  --with github.com/mholt/caddy-dynamicdns \
  --with github.com/jonaharagon/caddy-umami

FROM scratch

ENV \
  XDG_CONFIG_HOME=/config \
  XDG_DATA_HOME=/data

COPY --from=builder /usr/bin/caddy /caddy

WORKDIR /
CMD ["/caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
