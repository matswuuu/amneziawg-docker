# Build amneziawg-go
FROM golang:1.26.1-alpine3.23 AS builder-go

RUN apk add --no-cache git make

WORKDIR /build
RUN git clone --depth=1 https://github.com/amnezia-vpn/amneziawg-go.git . \
    && make

# Build amneziawg-tools
FROM alpine:3.21 AS builder-tools

RUN apk add --no-cache git make gcc musl-dev linux-headers bash

WORKDIR /build
RUN git clone --depth=1 \
        --branch v1.0.20260223 \
        https://github.com/amnezia-vpn/amneziawg-tools.git . \
    && make -C src \
    && make -C src install DESTDIR=/out \
        WITH_WGQUICK=yes \
        WITH_BASHCOMPLETION=no \
        WITH_SYSTEMDUNITS=no

# Runtime image
FROM alpine:3.21

RUN apk add --no-cache \
        iproute2 \
        iptables \
        ip6tables \
        bash \
        openresolv \
    && mkdir -p /etc/amnezia/amneziawg /var/run/amneziawg

# Copy binaries from build stages
COPY --from=builder-go /build/amneziawg-go /usr/local/bin/amneziawg-go
COPY --from=builder-tools /out/usr/bin/awg /usr/local/bin/awg
COPY --from=builder-tools /out/usr/bin/awg-quick /usr/local/bin/awg-quick

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

VOLUME ["/etc/amnezia/amneziawg"]

EXPOSE 51820/udp

ENTRYPOINT ["/entrypoint.sh"]