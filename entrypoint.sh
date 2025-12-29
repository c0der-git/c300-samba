#!/bin/sh
set -e

# Simple entrypoint to start Samba daemons and forward signals.
# This starts nmbd and smbd in the background (foreground mode) and waits.


echo "Entry point: checking runtime configuration..."

# If SMBUSER_PASSWORD is provided at container start, (re)create or set the Samba password for smbuser.
if [ -n "$SMBUSER_PASSWORD" ]; then
	echo "Setting smbuser SMB password from SMBUSER_PASSWORD env var"
	# Try adding the user to Samba passdb; if already exists, fall back to setting the password.
	if (echo "$SMBUSER_PASSWORD"; echo "$SMBUSER_PASSWORD") | smbpasswd -s -a smbuser 2>/dev/null; then
		smbpasswd -e smbuser || true
	else
		(echo "$SMBUSER_PASSWORD"; echo "$SMBUSER_PASSWORD") | smbpasswd -s smbuser || true
	fi
else
	echo "No SMBUSER_PASSWORD provided at runtime; using build-time password (if any)"
fi

echo "Starting nmbd and smbd..."

# Start nmbd and smbd in foreground but backgrounded by the shell so we can wait on them.
nmbd -F &
smbd -F &

# Wait for any child to exit
wait -n

# When one exits, terminate the rest
echo "One of the Samba processes exited, shutting down..."
kill $(jobs -p) 2>/dev/null || true
wait

echo "Samba stopped"

exit 0
