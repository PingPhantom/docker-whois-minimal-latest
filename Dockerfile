# Build stage
FROM alpine:latest AS builder
RUN apk add --no-cache build-base libidn2-dev curl

# ดึงเวอร์ชั่นล่าสุดจาก GitHub tags
RUN LATEST_VERSION=$(curl -s https://api.github.com/repos/rfc1036/whois/tags | grep -m1 '"name":' | cut -d'"' -f4) && \
    WHOIS_VERSION=${LATEST_VERSION#v} && \
    echo "Latest whois version: $WHOIS_VERSION" && \
    wget "https://github.com/rfc1036/whois/archive/refs/tags/${LATEST_VERSION}.tar.gz" -O whois.tar.gz && \
    tar -xzf whois.tar.gz && \
    cd "whois-${WHOIS_VERSION}" && \
    make HAVE_ICONV=1 HAVE_LIBIDN2=1 CONFIG_FILE=/etc/whois.conf DEFAULTSERVER=whois.iana.org && \
    strip whois

# Final stage
FROM scratch
COPY --from=builder /whois-*/whois /whois

# สร้าง tmpfs สำหรับ /tmp
VOLUME ["/tmp"]

# ตั้งค่า entrypoint เพื่อรัน whois ในโหมด read-only
ENTRYPOINT ["/whois"]

# ตั้งค่า label เพื่อระบุว่า container นี้ควรรันในโหมด read-only
LABEL org.opencontainers.image.authors="Your Name <your.email@example.com>"
LABEL org.opencontainers.image.description="Minimal whois container, should be run with --read-only flag"
LABEL org.opencontainers.image.source="https://github.com/yourusername/whois-minimal"
LABEL run="docker run --rm --read-only --tmpfs /tmp:rw,noexec,nosuid --log-driver none ${IMAGE}"
