#!/bin/sh
set -e

SMB_USER=${SMB_USER:-xiaomi}
SMB_PASS=${SMB_PASS:-xiaomi123}

# Detect interface automatically (primary)
AUTO_IFACE="$(ip route get 8.8.8.8 2>/dev/null \
  | awk '{for (i=1;i<=NF;i++) if ($i=="dev") {print $(i+1); exit}}')"

if [ -n "$AUTO_IFACE" ]; then
  SAMBA_IFACE="$AUTO_IFACE"
  echo "[*] Auto-detected interface: $SAMBA_IFACE"
else
  echo "[!] Auto-detection failed"
fi

# Fallback to env SAMBA_IFACE (secondary)
if [ -z "${SAMBA_IFACE:-}" ]; then
  echo "[!] SAMBA_IFACE not set and auto-detection failed"
  echo "[!] Will use existing smb.conf without regeneration"
  SKIP_RENDER=1
else
  SKIP_RENDER=0
fi

# Calculate LAN subnet if interface is known
LAN_SUBNET=""

if [ "$SKIP_RENDER" -eq 0 ]; then
  CIDR="$(ip -4 addr show dev "$SAMBA_IFACE" \
    | awk '/inet / {print $2; exit}')"

  if [ -z "$CIDR" ]; then
    echo "[!] No IPv4 address found on interface $SAMBA_IFACE"
    SKIP_RENDER=1
  else
    NET="$(ipcalc -n "$CIDR" | awk -F= '/NETWORK/ {print $2}')"
    PREFIX="$(echo "$CIDR" | cut -d/ -f2)"
    LAN_SUBNET="${NET}/${PREFIX}"
    export LAN_SUBNET
  fi
fi

echo "[*] Samba interface : $SAMBA_IFACE"
echo "[*] LAN subnet      : $LAN_SUBNET"

# Render smb.conf only if everything is available
if [ "$SKIP_RENDER" -eq 0 ] && [ -n "$LAN_SUBNET" ]; then
  echo "[*] Samba interface : $SAMBA_IFACE"
  echo "[*] LAN subnet      : $LAN_SUBNET"
  echo "[*] Rendering smb.conf from template"
  envsubst < /etc/samba/smb.conf.template > /etc/samba/smb.conf
else
  echo "[!] Using existing /etc/samba/smb.conf"
fi

# Sanity check
testparm -s >/dev/null

# Prepare directories
mkdir -p \
  /var/log/samba \
  /var/lib/samba/private \
  /var/lib/samba/usershares \
  /run/samba \
  /srv/samba/recordings

chmod 0700 /var/lib/samba/private
chmod 1777 /var/lib/samba/usershares

# Create user if missing
if ! id "$SMB_USER" >/dev/null 2>&1; then
    adduser -D -H "$SMB_USER"
fi

# Initialize Samba passdb if missing
if [ ! -f /var/lib/samba/private/passdb.tdb ]; then
    echo -e "$SMB_PASS\n$SMB_PASS" | smbpasswd -a -s "$SMB_USER"
    smbpasswd -e "$SMB_USER"
fi

chown -R "$SMB_USER:$SMB_USER" /srv/samba
chmod -R 0777 /srv/samba

echo "[*] Starting nmbd in foreground..."
nmbd --foreground --debug-stdout -d 2 &

sleep 1

echo "[*] Starting smbd in foreground..."
exec smbd -F --no-process-group --debug-stdout -d 2