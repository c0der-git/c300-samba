# c300-samba
Samba server adapted for Xiaomi C300 Smart IP camera

## Installation
1. In .env file, Set **SMBUSER password** to access \\c300-samba\share
2. Create folders for **logs** and **share** on a host machine
~~~~
# <logs_folder@host>
mkdir ~/c300-samba/logs
# <share_folder@host>
mkdir ~/c300-samba/logs
~~~~
3. Build "nt1-samba-server" docker image
~~~~
export $(cat .env | xargs) \
  && docker build \
  --build-arg SMBUSER_PASSWORD=$SMBUSER_PASSWORD \
  -t nt1-samba-server .
~~~~
5. Run docker container replacing **logs_folder@host, share_folder@host** with the correct values
~~~~
`docker run -d \
  --name xiaomiC300-samba-server \
  -m 512m --cpus="1" \
  -p 137:137/udp -p 139:139 -p 445:445 \
  -v <logs_folder@host>:/var/log/samba \
  -v <share_folder@host>:/srv/samba/share \
  -v /etc/localtime:/etc/localtime:ro \
  -v /etc/timezone:/etc/timezone:ro \
  nt1-samba-server`
~~~~
7. Check services status inside the container
~~~~
`# Host's timezone applied?
docker exec -it xiaomiC300-samba-server date

# Samba service is running?
docker exec -it xiaomiC300-samba-server ps aux | grep smbd

# NetBIOS service is running?
docker exec -it xiaomiC300-samba-server ps aux | grep nmbd
~~~~
8. Check samba server availability from the (remote) host
~~~~
smbclient //server-ip/share -U smbuser
~~~~
