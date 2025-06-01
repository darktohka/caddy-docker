FROM --platform=$BUILDPLATFORM chainguard/go:latest-dev AS builder

ARG TARGETPLATFORM

RUN \
  GOBIN=/ go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest && \
  if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
  export GOARCH="arm64"; \
  elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then \
  export GOARCH="arm"; \
  else \
  export GOARCH="amd64"; \
  fi && \
  /xcaddy build master \
  --output /caddy \
  --with github.com/caddy-dns/cloudflare \
  --with github.com/WeidiDeng/caddy-cloudflare-ip \
  --with github.com/mholt/caddy-dynamicdns \
  --with github.com/jonaharagon/caddy-umami \
  --with github.com/darktohka/caddy-webp-optimizer

FROM chainguard/wolfi-base

ENV \
  XDG_CONFIG_HOME=/config \
  XDG_DATA_HOME=/data

COPY --from=builder /caddy /caddy

WORKDIR /
CMD ["/caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
