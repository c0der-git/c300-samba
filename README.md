# c300-samba
A lightweight Samba server setup tailored for the Xiaomi C300 Smart IP camera, running inside a Docker container.

## Changelog
- 2025-12-30 Container run script added, healthcheck included
- 2025-12-28 updated Dockerfile, added docker-entrypoint.sh, tweaked smb.conf.alpine.

---

#  How to use the image
## Build docker image
```bash
# build with a default SMB password baked into the image (optional)
docker build --build-arg SMB_PASS='MyBuildPass -t xiaomi-samba:latest .
```

## Set Samba user's password
```bash
export SMB_PASS="STRONG_PASSWORD"
```
## OPTION A: Manual container start
### Go to Samba's data folder
cd /host/path/to/xiaomi-samba/data/folder

### Run the container:
```bash
# run with SMB password set at start (overrides any build-time pass)
docker run -d \
  --name xiaomi-samba \
  --network host \
  -e SMB_USER=xiaomi \
  -e SMB_PASS=$SMB_PASS \
  -v $PWD/data/recordings:/srv/samba/recordings \
  xiaomi-samba
```

Notes:
* Mount a host directory into /srv/samba/share if you want persistent data. If not mounted, the image will use the directory created in the container.
* Ports: 137/udp (NetBIOS), 139 and 445.
* You can test access from a client with the username smbuser and the password you set.

## OPTION B: Start container by script
```bash
chmod +x run_xiaomi_samba.sh
./run_xiaomi_samba.sh
```
Notes:
* If your repo/data directory is not /home/user/dev/samba, edit GIT_DIR and DATA_DIR variables at the top of the script to point to the correct paths.

---

# Check Service Status (Optional)

```bash
# Host's timezone applied?
docker exec -it xiaomi-samba date

# Samba service running?
docker exec -it xiaomi-samba ps aux | grep smbd

# NetBIOS service running?
docker exec -it xiaomi-samba ps aux | grep nmbd
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

# Health & troubleshooting
```bash
# container health
docker inspect -f '{{.State.Health.Status}}' xiaomi-samba

# basic checks
docker exec -it xiaomi-samba date
docker exec -it xiaomi-samba ps aux | grep -E 'smbd|nmbd'
```