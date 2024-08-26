FROM --platform=$BUILDPLATFORM alpine:latest AS builder

RUN apk add --no-cache build-base libidn2-dev curl

ARG TARGETARCH
RUN if [ "$TARGETARCH" = "arm" ]; then \
        export CFLAGS="-march=armv7-a -mfpu=neon-vfpv4 -mfloat-abi=hard"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        export CFLAGS="-march=armv8-a+crypto"; \
    fi

RUN LATEST_VERSION=$(curl -s https://api.github.com/repos/rfc1036/whois/tags | grep -m1 '"name":' | cut -d'"' -f4) && \
    WHOIS_VERSION=${LATEST_VERSION#v} && \
    echo "Latest whois version: $WHOIS_VERSION" && \
    wget "https://github.com/rfc1036/whois/archive/refs/tags/${LATEST_VERSION}.tar.gz" -O whois.tar.gz && \
    tar -xzf whois.tar.gz && \
    cd "whois-${WHOIS_VERSION}" && \
    make HAVE_ICONV=1 HAVE_LIBIDN2=1 CONFIG_FILE=/etc/whois.conf DEFAULTSERVER=whois.iana.org && \
    strip whois

FROM scratch
ARG TARGETARCH
COPY --from=builder /whois-*/whois /whois

VOLUME ["/tmp"]

ENTRYPOINT ["/whois"]

LABEL org.opencontainers.image.authors="Your Name <your.email@example.com>"
LABEL org.opencontainers.image.description="Minimal whois container for ${TARGETARCH}, should be run with --read-only flag"
LABEL org.opencontainers.image.source="https://github.com/yourusername/whois-minimal"
LABEL run="docker run --rm --read-only --tmpfs /tmp:rw,noexec,nosuid --log-driver none ${IMAGE}"
