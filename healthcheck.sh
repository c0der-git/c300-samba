#!/bin/sh
set -e

# 1. smbd must be running
pgrep smbd >/dev/null || exit 1

# 2. nmbd must be running
pgrep nmbd >/dev/null || exit 1

# 3. SMB ports must be listening
ss -lnt | grep -q ':445' || exit 1
ss -lnt | grep -q ':139' || exit 1

# 4. Share must be writable
TEST_FILE="/srv/samba/recordings/.healthcheck"
touch "$TEST_FILE" && rm -f "$TEST_FILE"

exit 0