# TP1 : (re)Familiaration avec un système GNU/Linux

## 0. Préparation de la machine

Accès internet (On ping un dns et google):
```
[neva@node1 ~]$ ping 1.1.1.1
PING 1.1.1.1 (1.1.1.1) 56(84) bytes of data.
64 bytes from 1.1.1.1: icmp_seq=1 ttl=128 time=43.2 ms
64 bytes from 1.1.1.1: icmp_seq=2 ttl=128 time=17.5 ms
64 bytes from 1.1.1.1: icmp_seq=3 ttl=128 time=17.9 ms
64 bytes from 1.1.1.1: icmp_seq=4 ttl=128 time=17.8 ms
^C
--- 1.1.1.1 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3012ms
rtt min/avg/max/mdev = 17.531/24.109/43.241/11.047 ms
[neva@node1 ~]$ ping www.google.com
PING www.google.com (142.250.75.228) 56(84) bytes of data.
64 bytes from par10s41-in-f4.1e100.net (142.250.75.228): icmp_seq=1 ttl=128 time=19.3 ms
64 bytes from par10s41-in-f4.1e100.net (142.250.75.228): icmp_seq=2 ttl=128 time=18.8 ms
64 bytes from par10s41-in-f4.1e100.net (142.250.75.228): icmp_seq=3 ttl=128 time=19.3 ms
64 bytes from par10s41-in-f4.1e100.net (142.250.75.228): icmp_seq=4 ttl=128 time=20.1 ms
^C
--- www.google.com ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3011ms
rtt min/avg/max/mdev = 18.778/19.365/20.069/0.491 ms
```

Accès au réseau local (On ping une autre machine connectée au même host only):
```
[neva@node1 ~]$ ping 10.101.1.12
PING 10.101.1.12 (10.101.1.12) 56(84) bytes of data.
64 bytes from 10.101.1.12: icmp_seq=1 ttl=64 time=1.03 ms
64 bytes from 10.101.1.12: icmp_seq=2 ttl=64 time=0.766 ms
64 bytes from 10.101.1.12: icmp_seq=3 ttl=64 time=0.538 ms
64 bytes from 10.101.1.12: icmp_seq=4 ttl=64 time=0.636 ms
^C
--- 10.101.1.12 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3050ms
rtt min/avg/max/mdev = 0.538/0.741/1.026/0.185 ms
```

Nom des machines :
```
[neva@node1 ~]$ hostname
node1.tp1.b2
```
```
[neva@node2 ~]$ hostname
node2.tp1.b2
```

Serveur DNS en 1.1.1.1 :
On modifie le nameserver dans /etc/resolv.conf

```
[neva@node1 ~]$ dig google.com
[...]
;; ANSWER SECTION:
google.com.             120     IN      A       216.58.204.142
[...]
;; SERVER: 1.1.1.1#53(1.1.1.1)
[...]
```

L'ip de google est donc 216.58.204.142. Le serveur qui nous a répondu est bien 1.1.1.1.

On ajoute le node2 dans le host de node1 et inversement :
```
[neva@node1 ~]$ cat /etc/hosts
[...]
10.101.1.12 node2
[neva@node1 ~]$ ping node2
PING node2 (10.101.1.12) 56(84) bytes of data.
64 bytes from node2 (10.101.1.12): icmp_seq=1 ttl=64 time=0.657 ms
64 bytes from node2 (10.101.1.12): icmp_seq=2 ttl=64 time=1.53 ms
^C
--- node2 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1005ms
rtt min/avg/max/mdev = 0.657/1.093/1.529/0.436 ms
```

On vérifie que le firewall est actif et les règles actuellement actives :
```
[neva@node1 ~]$ sudo firewall-cmd --state
running
[neva@node1 ~]$ sudo firewall-cmd --list-all
public (active)
  target: default
  icmp-block-inversion: no
  interfaces: ens33 ens37
  sources:
  services: cockpit dhcpv6-client ssh
  ports:
  protocols:
  masquerade: no
  forward-ports:
  source-ports:
  icmp-blocks:
  rich rules:
```

## I. Utilisateurs
### 1. Création et configuration

On crée l'utilisateur admin, on lui ajoute un mot de passe, on crée le groupe admins, on ajoute admin dans admins et on donne les permissions sudo à admins :
```
[neva@node1 ~]$ su -
Password:
[root@node1 ~]# useradd admin -m -d /home/admin -s /bin/bash
[root@node1 ~]# passwd admin
Changing password for user admin.
New password:
BAD PASSWORD: The password is shorter than 8 characters
Retype new password:
passwd: all authentication tokens updated successfully.
[root@node1 ~]# groupadd admins
[root@node1 ~]# usermod -a -G admins admin
[root@node1 ~]# visudo
```

On ajoute cette ligne dans sudoers : ```%admins ALL=(ALL)       ALL```

### 2. SSH

On crée la clé avec l'hôte (W10) :
```
PS C:\Users\DIRECTEUR_PC2> ssh-keygen -t rsa -b 4096
Generating public/private rsa key pair.
Enter file in which to save the key (C:\Users\DIRECTEUR_PC2/.ssh/id_rsa):
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in C:\Users\DIRECTEUR_PC2/.ssh/id_rsa.
Your public key has been saved in C:\Users\DIRECTEUR_PC2/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:KcPV7w5C/9/2RGB/CVNIYFzjlZztkZgW3l1/3D1IZfQ directeur_pc2@DIRECTEUR-PC2
The key's randomart image is:
+---[RSA 4096]----+
|          .o+*O**|
|         ...+=BBO|
|        . . .*o+E|
|     . . . . .oo=|
|      + S   .  .+|
|       + . .   ..|
|        . o .   .|
|         . +   o.|
|            o...+|
+----[SHA256]-----+
```

On mets la clé publique sur node1 : ```ssh-copy-id -i ~/.ssh/id_rsa.pub neva@10.101.1.11```

Elle a bien été ajoutée :
```
[neva@node1 ~]$ ls .ssh/
authorized_keys
```

On peut maitenant se connecter sans mot de passe :
```
PS C:\Users\DIRECTEUR_PC2> ssh neva@10.101.1.11
Activate the web console with: systemctl enable --now cockpit.socket

Last login: Wed Sep 22 12:41:30 2021 from 10.101.1.1
[neva@node1 ~]$
```

## II. Partitionnement

### 2. Partitionnement

Ajout des disques en PV :
```
[neva@node1 ~]$ sudo pvcreate /dev/sdb
  Physical volume "/dev/sdb" successfully created.
[neva@node1 ~]$ sudo pvcreate /dev/sdc
  Physical volume "/dev/sdc" successfully created.
```
Création et extension au 2ème disque du VG :
```
[neva@node1 ~]$ sudo vgcreate secdsk /dev/sdb
  Volume group "secdsk" successfully created
[neva@node1 ~]$ sudo vgextend secdsk /dev/sdc
  Volume group "secdsk" successfully extended
```
Création des 3 LV :
```
[neva@node1 ~]$ sudo lvcreate -L 1024M secdsk -n secdskpart1
  Logical volume "secdskpart1" created.
[neva@node1 ~]$ sudo lvcreate -L 1024M secdsk -n secdskpart2
  Logical volume "secdskpart2" created.
[neva@node1 ~]$ sudo lvcreate -L 1024M secdsk -n secdskpart3
  Logical volume "secdskpart3" created.
```
Formatage des 3 LV :
```
[neva@node1 ~]$ mkfs -t ext4 /dev/secdsk/secdskpart1
mke2fs 1.45.6 (20-Mar-2020)
Could not open /dev/secdsk/secdskpart1: Permission denied
[neva@node1 ~]$ sudo mkfs -t ext4 /dev/secdsk/secdskpart1
mke2fs 1.45.6 (20-Mar-2020)
Creating filesystem with 262144 4k blocks and 65536 inodes
[...]
Writing superblocks and filesystem accounting information: done

[neva@node1 ~]$ sudo mkfs -t ext4 /dev/secdsk/secdskpart2
mke2fs 1.45.6 (20-Mar-2020)
Creating filesystem with 262144 4k blocks and 65536 inodes
[...]
Writing superblocks and filesystem accounting information: done

[neva@node1 ~]$ sudo mkfs -t ext4 /dev/secdsk/secdskpart3
mke2fs 1.45.6 (20-Mar-2020)
Creating filesystem with 262144 4k blocks and 65536 inodes
[...]
Writing superblocks and filesystem accounting information: done
```
Montage des 3 LV :
```
[neva@node1 ~]$ sudo mkdir -p /mnt/secdskpart1
[neva@node1 ~]$ sudo mkdir -p /mnt/secdskpart2
[neva@node1 ~]$ sudo mkdir -p /mnt/secdskpart3
[neva@node1 ~]$ sudo mount -t auto /dev/secdsk/secdskpart1 /mnt/secdskpart1
[neva@node1 ~]$ sudo mount -t auto /dev/secdsk/secdskpart2 /mnt/secdskpart2
[neva@node1 ~]$ sudo mount -t auto /dev/secdsk/secdskpart3 /mnt/secdskpart3
```

On fait en sorte que les partitions soient montées au démarrage (fichier /etc/fstabs). Pour cela on rajoute lces lignes dans le fichier.
```
/dev/secdsk/secdskpart1 /mnt/secdskpart1        ext4    defaults        0 0
/dev/secdsk/secdskpart2 /mnt/secdskpart2        ext4    defaults        0 0
/dev/secdsk/secdskpart3 /mnt/secdskpart3        ext4    defaults        0 0
```
Après redémmarage, les partions sont bien montées.

## III. Gestion de services

### 1. Interaction avec un service existant

On vérifie que firewalld est démarré et est automatiquement allumé au démarrage :
Loaded (activé au boot) / active (en fonctionnement)
```
[neva@node1 ~]$ systemctl status firewalld
● firewalld.service - firewalld - dynamic firewall daemon
   Loaded: loaded (/usr/lib/systemd/system/firewalld.service; enabled; vendor preset: enabled)
   Active: active (running) since Sat 2021-09-25 19:25:37 CEST; 5min ago
     Docs: man:firewalld(1)
 Main PID: 1024 (firewalld)
    Tasks: 2 (limit: 11218)
   Memory: 30.4M
   CGroup: /system.slice/firewalld.service
           └─1024 /usr/libexec/platform-python -s /usr/sbin/firewalld --nofork --nopid
```
### 2. Création de service

#### A. Unité simpliste
Contenu du fichier et installation du service :
```
[neva@node1 ~]$ cat /etc/systemd/system/web.service
[Unit]
Description=Simple python web service

[Service]
ExecStart=/usr/bin/python3.6 -m http.server 8888

[Install]
WantedBy=multi-user.target
[neva@node1 ~]$ sudo systemctl start web
[neva@node1 ~]$ sudo systemctl enable web
[neva@node1 ~]$ systemctl status web
● web.service - Simple python web service
   Loaded: loaded (/etc/systemd/system/web.service; enabled; vendor preset: disabled)
   Active: active (running) since Sat 2021-09-25 19:43:29 CEST; 4min 44s ago
 Main PID: 6088 (python3.6)
    Tasks: 1 (limit: 11218)
   Memory: 9.8M
   CGroup: /system.slice/web.service
           └─6088 /usr/bin/python3.6 -m http.server 8888
```
Il faut bien que le port 8888 soit ouvert pour héberger le serveur !

![](https://i.imgur.com/Zf12VGb.png)

#### B. Modification de l'unité
Création de l'utilisateur web :
```
[neva@node1 ~]$ su -
Password:
[root@node1 ~]# useradd --no-create-home web
[root@node1 ~]# passwd web
Changing password for user web.
New password:
BAD PASSWORD: The password is shorter than 8 characters
Retype new password:
passwd: all authentication tokens updated successfully.
```
On rajoute ces 2 lignes dans le fichier du service :
```
User=web
WorkingDirectory=/srv/webserver
```
Ajout du fichier toto : ```web@node1 /]$ sudo touch /srv/webserver/toto```

Vérifiation du fonctinnement du serveur :
````
PS C:\Users\DIRECTEUR_PC2> curl http://10.101.1.11:8888/

StatusCode        : 200
StatusDescription : OK
[...]
```