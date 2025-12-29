FROM alpine:3.23

# Install samba + utilities
RUN apk add --no-cache \
    samba \
    samba-common-tools \
    bash \
    envsubst \
    iproute2 \
    ipcalc \
    tzdata

# Create samba runtime dirs
RUN mkdir -p /var/log/samba /var/lib/samba /run/samba

# Copy config and entrypoint
COPY smb.conf smb.conf.template /etc/samba/
COPY healthcheck.sh /usr/local/bin/healthcheck.sh
RUN chmod +x /usr/local/bin/healthcheck.sh
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

# Expose SMB ports
EXPOSE 137/udp 138/udp 139/tcp 445/tcp

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD /usr/local/bin/healthcheck.sh || exit 1

ENTRYPOINT ["/entrypoint.sh"]