# c300-samba

A lightweight Samba server setup tailored for the Xiaomi C300 Smart IP camera, running inside a Docker container.

---

## 🚀 Installation & Setup

### 1. Set SMB User Password

Edit or create the `.env` file with the Samba user password:

```bash
echo "SMBUSER_PASSWORD=<MY_STRONG_PASSWORD>" >> ~/c300-samba/.env
cd ~/c300-samba
export $(cat .env | xargs)
```

Alternatively, export it directly:

```bash
export SMBUSER_PASSWORD=<MY_STRONG_PASSWORD>
```

---

### 2. Create Shared Folders on the Host

```bash
mkdir -p ~/c300-samba/logs
mkdir -p ~/c300-samba/share
```

---

### 3. Build Docker Image

```bash
docker build \
  --build-arg SMBUSER_PASSWORD=$SMBUSER_PASSWORD \
  -t nt1-samba-server .
```

---

### 4. Run the Docker Container

Replace `<logs_folder@host>` and `<share_folder@host>` with full paths to the actual folders created above:

```bash
docker run -d \
  --name xiaomiC300-samba-server \
  -m 512m --cpus="1" \
  -p 137:137/udp -p 139:139 -p 445:445 \
  -v <logs_folder@host>:/var/log/samba \
  -v <share_folder@host>:/srv/samba/share \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  nt1-samba-server
```

---

### 5. Check Service Status (Optional)

```bash
# Host's timezone applied?
docker exec -it xiaomiC300-samba-server date

# Samba service running?
docker exec -it xiaomiC300-samba-server ps aux | grep smbd

# NetBIOS service running?
docker exec -it xiaomiC300-samba-server ps aux | grep nmbd
```

---

### 6. Verify from Remote Host

```bash
smbclient //server-ip/share -U smbuser
```

---

## 📁 Directory Structure

```
~/c300-samba/
├── .env
├── Dockerfile
├── logs/
└── share/
```

---

## 🛠 Requirements

- Docker
- A Linux host machine
- Optional: `smbclient` for testing from remote hosts

---

## 📄 License

[MIT](LICENSE)

