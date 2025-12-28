# Base image: Alpine Linux
FROM alpine:latest

# Expose Samba ports 137 (NetBIOS name service), 139 (SMB over NetBIOS), and 445 (SMB over TCP)
EXPOSE 137 139 445

# Install necessary packages: Samba
RUN apk update && \
    apk add --no-cache samba samba-common-tools

# Create the directory for the Samba share
RUN mkdir -p /srv/samba/share && chown -R nobody:nobody /srv/samba/share

# Ensure /var/log/samba directory exists
RUN mkdir -p /var/log/samba && chown -R root:root /var/log/samba

# Copy the smb.conf file from the build context to the container
COPY smb.conf.alpine /etc/samba/smb.conf

# Add build-time argument for SMB user password (default placeholder; override at build-time)
ARG SMBUSER_PASSWORD=changeme

# Create a Samba user without login access and no home directory
RUN adduser -D -H -s /bin/false smbuser || true

# Set the password for the Samba user (non-interactive). If empty, user will be created with a blank password.
RUN if [ -n "$SMBUSER_PASSWORD" ]; then \
            (echo "$SMBUSER_PASSWORD"; echo "$SMBUSER_PASSWORD") | smbpasswd -s -a smbuser && smbpasswd -e smbuser; \
        else echo "No SMBUSER_PASSWORD provided; smbuser created without SMB password"; fi

# Add a small entrypoint script to start Samba daemons properly
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 137 139 445

# Use the entrypoint script (exec form)
CMD ["/usr/local/bin/docker-entrypoint.sh"]

