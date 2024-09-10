# Base image: Alpine Linux
FROM alpine:latest

# Expose Samba ports 137 (NetBIOS name service), 139 (SMB over NetBIOS), and 445 (SMB over TCP)
EXPOSE 137 139 445

# Install necessary packages: Samba
RUN apk update && \
    apk add --no-cache samba samba-common-tools

# Create the directory for the Samba share
RUN mkdir -p /srv/samba/share && chown nobody:nogroup /srv/samba/share

# Ensure /var/log/samba directory exists
RUN mkdir -p /var/log/samba && chown nobody:nogroup /var/log/samba

# Copy the smb.conf file from the build context to the container
COPY smb.conf.alpine /etc/samba/smb.conf

# Add build-time argument for SMB user password
ARG SMBUSER_PASSWORD

# Create a Samba user without login access and no home directory
RUN adduser -D -H -s /bin/false smbuser

# Set the password for the Samba user
RUN (echo "$SMBUSER_PASSWORD"; echo "$SMBUSER_PASSWORD") | smbpasswd -s -a smbuser && smbpasswd -e smbuser

# Start smbd and nmbd in the foreground
CMD smbd -F & nmbd -F & tail -f /dev/null

