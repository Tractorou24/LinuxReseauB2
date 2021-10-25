# TP2 pt. 2 : Maintien en condition opérationnelle

## I. Monitoring

*On fait tout sur les 2 machines*

On installe netdata :
```
[neva@db ~]$ su -
Password:
[root@db ~]# bash <(curl -Ss https://my-netdata.io/kickstart.sh)
[...]
[root@db ~]# logout
[neva@db ~]$ sudo systemctl enable --now netdata
[neva@db ~]$  sudo firewall-cmd --add-port=19999/tcp
success
[neva@db ~]$ sudo firewall-cmd --add-port=19999/tcp --permanent
success
[neva@db ~]$ ss -ltn | grep 19999
LISTEN 0      128          0.0.0.0:19999      0.0.0.0:*
LISTEN 0      128             [::]:19999         [::]:*
```

On crée un webhook discord et on l'ajoute dans la conf de netdata, puis on vérifie le fonctionnement.

`bash -x /usr/libexec/netdata/plugins.d/alarm-notify.sh test "sysadmin"`
![](https://i.imgur.com/sgAagt9.png)

On ajoute l'alarme de la RAM :
`sudo vim /etc/netdata/health.d/ram-usage.conf`

Le fichier `ram_usage.conf` :
```
 alarm: ram_usage
    on: system.ram
lookup: average -1m percentage of used
 units: %
 every: 1m
  warn: $this > 50
  crit: $this > 90
  info: The percentage of RAM being used by the system.
```

Après un RAM stress :
![](https://i.imgur.com/bLm1Vzz.png)

## II. Backup

### 2. Partage NFS

On crée l'architcture du partage :
```
[neva@backup ~]$ mkdir /srv/backup
[neva@backup ~]$ cd /srv/backup
[neva@backup ~]$ mkdir web.tp2.linux
[neva@backup ~]$ mkdir db.tp2.linux
```

Installation du nfs :
``` bash
[neva@backup ~]$ sudo dnf -y install nfs-utils
[...]
[neva@backup ~]$ sudo vim /etc/idmapd.conf
# Domain = backup.tp2.linux
[neva@backup ~]$ sudo vim /etc/exports
# /srv/backup/web.tp2.linux 10.101.1.11/24(rw,no_root_squash)
# /srv/backup/db.tp2.linux 10.101.1.12(rw, no_root_squash)
[neva@backup ~]$ sudo systemctl enable --now rpcbind nfs-server
Created symlink /etc/systemd/system/multi-user.target.wants/nfs-server.service → /usr/lib/systemd/system/nfs-server.service.
[neva@backup ~]$ sudo firewall-cmd --add-service=nfs
success
[neva@backup ~]$ sudo firewall-cmd --add-service=nfs --permanent
success
```

On monte les 2 dossiers sur les 2 vm :
``` bash
[neva@web ~]$ sudo mount -t nfs 10.101.1.13:/srv/backup/web.tp2.linux /mnt/backup/
[neva@web ~]$ df -h
[...]
10.101.1.13:/srv/backup/web.tp2.linux   14G  2.4G   12G  18% /mnt/backup
[neva@web ~]$ touch /mnt/backup/toto
```

Dans /etc/fstab, on rajoute `10.101.1.13:/srv/backup/web.tp2.linux /mnt/backup/ nfs  defaults        0 0`

Et on fait la même chose dans db.tp2.linux en remplacant web par db.

Ajour et partitionnement d'un disque de 5Go sur `backup` :
```
[neva@backup ~]$ lsblk
NAME        MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda           8:0    0   16G  0 disk
├─sda1        8:1    0    1G  0 part /boot
└─sda2        8:2    0   15G  0 part
  ├─rl-root 253:0    0 13.4G  0 lvm  /
  └─rl-swap 253:1    0  1.6G  0 lvm  [SWAP]
sdb           8:16   0    5G  0 disk
sr0          11:0    1  9.2G  0 rom
[neva@backup ~]$ sudo pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
[neva@backup ~]$ sudo vgcreate backdsk /dev/sdb
  Volume group "backdsk" successfully created
[neva@backup ~]$ sudo lvcreate -L 1024M backdsk -n secdskpart
  Logical volume "secdskpart" created.
[neva@backup ~]$  sudo mkfs -t ext4 /dev/backdsk/secdskpart
*mke2fs 1.45.6 (20-Mar-2020)
Creating filesystem with 262144 4k blocks and 65536 inodes
[...]
Writing superblocks and filesystem accounting information: done
[neva@backup ~]$ sudo mount -t auto /dev/backdsk/secdskpart /srv/backup/
```

On rajoute `/dev/backdsk/secdskpart /srv/backup/            ext4    defaults        0 0` dans `/etc/fstab`.

### 3. Backup de fichiers

Sur web, on exécute le script :
```
[neva@web ~]$ ./tp2_backup.sh /mnt/backup toto tata titi
/mnt/backup ~
~
```

On vérifie que la backup est bien sur backup et on l'extrait pour vérifier si les fichiers toto, tata et titi sont la :
```
[neva@backup ~]$ ls /srv/backup/web.tp2.linux/
tp2_backup_20211012_121829.tar.gz
[neva@backup ~]$ tar -xvf /srv/backup/web.tp2.linux/tp2_backup_20211012_121829.tar.gz
toto
tata
titi
```

Si on veut créer une 6ème backup, la 1ère est supprimée pour qu'on en ait toujours 5 au maximum.

### 4. Unité de service

#### A. Unité de service

Une fois le service créé, on teste :
``` bash
[neva@web ~]$ ls /mnt/backup/
[neva@web ~]$ sudo systemctl start tp2_backup
[neva@web ~]$ ls /mnt/backup/
```

#### B. Timer

On ajoite le timer et on teste :
``` bash
[neva@web ~]$ sudo vim /etc/systemd/system/tp2_backup.timer
[neva@web ~]$ sudo systemctl daemon-reload
[neva@web ~]$ sudo systemctl start tp2_backup.timer
[neva@web ~]$ sudo systemctl status tp2_backup.timer
● tp2_backup.timer - Periodically run our TP2 backup script
   Loaded: loaded (/etc/systemd/system/tp2_backup.timer; disabled; vendor preset: disabled)
   Active: active (waiting) since Sun 2021-10-24 17:16:48 CEST; 9s ago
  Trigger: Sun 2021-10-24 17:17:00 CEST; 2s left

Oct 24 17:16:48 web.tp2.linux systemd[1]: Started Periodically run our TP2 backup script.
[neva@web ~]$ sudo systemctl status tp2_backup.timer
● tp2_backup.timer - Periodically run our TP2 backup script
   Loaded: loaded (/etc/systemd/system/tp2_backup.timer; disabled; vendor preset: disabled)
   Active: active (waiting) since Sun 2021-10-24 17:16:48 CEST; 15s ago
  Trigger: Sun 2021-10-24 17:18:00 CEST; 55s left

Oct 24 17:16:48 web.tp2.linux systemd[1]: Started Periodically run our TP2 backup script.
[neva@web ~]$ ls /mnt/backup/
tp2_backup_20211024_171502.tar.gz  tp2_backup_20211024_171648.tar.gz  tp2_backup_20211024_171702.tar.gz
```

#### C. Contexte

On modifie les fichiers et on vérifie que le timer va bien s'executer a la bonne heure :
```
[neva@web ~]$ sudo systemctl list-timers
NEXT                          LEFT     LAST                          PASSED      UNIT                         ACTIVATES
[...]
tp2_backup.timer             tp2_backu>
Mon 2021-10-25 17:18:55 CEST  23h left Sun 2021-10-24 17:18:55 CEST  7min ago    systemd-tmpfiles-clean.timer systemd-t>
[...]
4 timers listed.
```

### 5. Backup de base de données

On crée le script et on le rend exécutable.
Puis on ajoute un service et un timer.  
 ```
[neva@db ~]$ sudo vim /etc/systemd/system/tp2_backup_db.service
[neva@db ~]$ sudo systemctl daemon-reload
[neva@db ~]$ rm /mnt/backup/*
[neva@db ~]$ sudo systemctl start tp2_backup_db
[neva@db ~]$ ls /mnt/backup
tp2_backup_db_20211024_180328.tar.gz
[neva@db ~]$ sudo vim /etc/systemd/system/tp2_backup_db.timer
[neva@db ~]$ sudo systemctl daemon-reload
[neva@db ~]$ sudo systemctl start tp2_backup_db.timer
[neva@db ~]$ sudo systemctl status tp2_backup_db.timer
● tp2_backup_db.timer - Periodically run our TP2 backup script
   Loaded: loaded (/etc/systemd/system/tp2_backup_db.timer; disabled; vendor preset: disabled)
   Active: active (waiting) since Sun 2021-10-24 18:01:25 CEST; 12s ago
  Trigger: Mon 2021-10-25 03:30:00 CEST; 9h left

Oct 24 18:01:25 db.tp2.linux systemd[1]: Started Periodically run our TP2 backup script.
 ```

 ## III. Reverse Proxy

``` bash
[neva@front ~]$ sudo dnf install nginx
[...]
Complete.
[neva@front ~]$ sudo systemctl enable --now nginx
Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service → /usr/lib/systemd/system/nginx.service.
[neva@front ~]$ curl localhost
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
  <head>
    <title>Test Page for the Nginx HTTP Server on Rocky Linux</title>
[...]
```

Nom d'utilisateur nginx : nginx

Modif de la configuration :
``` bash
[neva@front ~]$ cat /etc/hosts
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6

10.101.1.11 web.tp2.linux
[neva@front ~]$ cat /etc/nginx/conf.d/web.tp2.linux.conf
server {
    listen 80;

    server_name web.tp2.linux; 

    location / {
        proxy_pass http://web.tp2.linux;
    }
}
```

## IV. Firewalling

Configuration sur db.tp2.linux :
``` bash
[neva@db ~]$ sudo firewall-cmd --get-active-zones
db
  sources: 10.101.1.11/24
drop
  interfaces: ens37 ens33
ssh
  sources: 10.101.1.1/24
[neva@db ~]$ sudo firewall-cmd --get-default-zone
drop
```

Configuration de web.tp2.linux :
``` bash
[neva@web ~]$ sudo firewall-cmd --get-active-zones
drop
  interfaces: ens37 ens33
ssh
  sources: 10.101.1.1/24
web
  sources: 10.101.1.14/24
[neva@web ~]$ sudo firewall-cmd --get-default-zone
drop
```

Configuration de backup.tp2.linux :
``` bash
[neva@backup ~]$ sudo firewall-cmd --get-active-zones
backup
  sources: 10.101.1.11/24 10.101.1.12/24
drop
  interfaces: ens33
public
  interfaces: ens37
ssh
  sources: 10.101.1.1/24
[neva@backup ~]$ sudo firewall-cmd --get-default-zone
drop
```

Configuration de front.tp2.linux :
``` bash
[neva@front ~]$ sudo firewall-cmd --get-active-zones
drop
  interfaces: ens33 ens37
front
  sources: 10.101.1.0/24
ssh
  sources: 10.101.1.1/24
[neva@front ~]$  sudo firewall-cmd --get-default-zone
drop
```

### Tableau récap :

| Machine            | IP            | Service                 | Port ouvert                | IPs autorisées                         |
| ------------------ | ------------- | ----------------------- | -------------------------- | -------------------------------------- |
| `web.tp2.linux`    | `10.102.1.11` | Serveur Web             | 22tcp / 80tcp              | 10.101.1.1                             |
| `db.tp2.linux`     | `10.102.1.12` | Serveur Base de Données | 22tcp / 3306tcp / 19999tcp | 10.101.1.11 / 10.101.1.11              |
| `backup.tp2.linux` | `10.102.1.13` | Serveur de Backup (NFS) | 22tcp / 2049tcp            | 10.101.1.1 / 10.101.1.11 / 10.101.1.12 |
| `front.tp2.linux`  | `10.102.1.14` | Reverse Proxy           | 22tcp / 80tcp              | 10.101.1.0                             |
Toutes les ip sont en /24.
