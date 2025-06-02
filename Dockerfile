FROM --platform=$BUILDPLATFORM debian:sid AS builder

RUN \
  apt-get update && \
  apt-get install --no-install-recommends -y golang g++-aarch64-linux-gnu g++-x86-64-linux-gnu g++-arm-linux-gnueabihf curl autoconf automake libtool make ca-certificates && \
  GOBIN=/ go install github.com/caddyserver/xcaddy/cmd/xcaddy@latest

ARG TARGETPLATFORM

RUN \
  if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
  export HOST="aarch64-linux-gnu"; \
  export CC="aarch64-linux-gnu-gcc -O3"; \
  elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then \
  export HOST="arm-linux-gnueabihf"; \
  export CC="arm-linux-gnueabihf-gcc -O3"; \
  else \
  export HOST="x86_64-linux-gnu"; \
  export CC="x86_64-linux-gnu-gcc -O3"; \
  fi && \
  cd /tmp && \
  curl https://github.com/webmproject/libwebp/archive/refs/heads/main.tar.gz -SsL | tar xz && \
  cd libwebp-main && \
  ./autogen.sh && \
  ./configure --host="$HOST" --prefix=/usr/$HOST --enable-static --disable-shared && \
  make && \
  make install

RUN \
  if [ "$TARGETPLATFORM" = "linux/arm64" ]; then \
  export GOARCH="arm64"; \
  export CC="aarch64-linux-gnu-gcc -O3"; \
  elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then \
  export GOARCH="armeabi-"; \
  export CC="arm-linux-gnueabihf-gcc -O3"; \
  else \
  export GOARCH="amd64"; \
  export CC="x86_64-linux-gnu-gcc -O3"; \
  fi && \
  export CGO_LDFLAGS="-lm -lsharpyuv" && \
  export CGO_ENABLED=1 && \
  /xcaddy build master \
  --output /caddy \
  --with github.com/darktohka/caddy-webp-optimizer \
  --with github.com/caddy-dns/cloudflare \
  --with github.com/WeidiDeng/caddy-cloudflare-ip \
  --with github.com/mholt/caddy-dynamicdns \
  --with github.com/jonaharagon/caddy-umami

FROM chainguard/wolfi-base

ENV \
  XDG_CONFIG_HOME=/config \
  XDG_DATA_HOME=/data

COPY --from=builder /caddy /caddy

WORKDIR /
CMD ["/caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]
