# c300-samba
A lightweight Samba server setup tailored for the Xiaomi C300 Smart IP camera, running inside a Docker container.

## Changelog
- 2025-12-28 updated Dockerfile, added docker-entrypoint.sh, tweaked smb.conf.alpine.

---

#  How to use the image
Recommended build (set build-time password if you want a build-time default; optional):
```bash
# build with a default SMB password baked into the image (optional)
docker build --build-arg SMBUSER_PASSWORD='MyBuildPass' -t c300-samba:latest .
```

Preferred runtime: set the SMB password at container start via env (entrypoint will create or update the Samba user password):
```bash
# run with SMB password set at start (overrides any build-time pass)
docker run -d --name c300-samba \
-p 137:137/udp -p 139:139 -p 445:445 \
-e SMBUSER_PASSWORD='MyRuntimePass' \
-v /host/path/to/logs:/var/log/samba \
-v /host/path/to/share:/srv/samba/share \
-v /etc/localtime:/etc/localtime:ro \
-v /etc/timezone:/etc/timezone:ro \
c300-samba:latest
```

Notes:
* Mount a host directory into /srv/samba/share if you want persistent data. If not mounted, the image will use the directory created in the container.
* Ports: 137/udp (NetBIOS), 139 and 445.
* You can test access from a client with the username smbuser and the password you set.

---

# Check Service Status (Optional)

```bash
# Host's timezone applied?
docker exec -it c300-samba date

# Samba service running?
docker exec -it c300-samba ps aux | grep smbd

# NetBIOS service running?
docker exec -it c300-samba ps aux | grep nmbd
```

---

# Verify access from local host
## Connect to samba server
```bash
smbclient -L //127.0.0.1 -U smbuser%MyRuntimePass \
  --option='client min protocol=NT1' \
  --option='client max protocol=NT1'
```
## Create an empty local file from inside smbclient
```bash
!touch empty.txt
put empty.txt
```
---