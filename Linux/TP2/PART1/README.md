# TP2 pt. 1 : Gestion de service

## I. Un premier serveur web

### 1. Installation

``` bash
[neva@web ~]$ sudo dnf install httpd
[...]
========================================================================================================================
 Package                     Architecture     Version                                         Repository           Size
========================================================================================================================
Installing:
 httpd                       x86_64           2.4.37-39.module+el8.4.0+571+fd70afb1           appstream           1.4 M
Installing dependencies:
 apr                         x86_64           1.6.3-11.el8.1                                  appstream           124 k
 apr-util                    x86_64           1.6.1-6.el8.1                                   appstream           104 k
[...]
Installed:
  apr-1.6.3-11.el8.1.x86_64
  apr-util-1.6.1-6.el8.1.x86_64
  apr-util-bdb-1.6.1-6.el8.1.x86_64
  apr-util-openssl-1.6.1-6.el8.1.x86_64
  httpd-2.4.37-39.module+el8.4.0+571+fd70afb1.x86_64
  httpd-filesystem-2.4.37-39.module+el8.4.0+571+fd70afb1.noarch
  httpd-tools-2.4.37-39.module+el8.4.0+571+fd70afb1.x86_64
  mod_http2-1.15.7-3.module+el8.4.0+553+7a69454b.x86_64
  rocky-logos-httpd-84.5-8.el8.noarch

Complete!
```

Démararge du service : ```[neva@web ~]$ sudo systemctl start httpd```

Auto start au boot :
``` bash
[neva@web ~]$ sudo systemctl enable httpd
Created symlink /etc/systemd/system/multi-user.target.wants/httpd.service → /usr/lib/systemd/system/httpd.service.
```

Ouverture du port firewall :
``` bash
[neva@web ~]$ sudo firewall-cmd --add-port 80/tcp
success
```

Le service est actif et démarre automatiquement au boot :
``` bash
[neva@web ~]$ systemctl status httpd
● httpd.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2021-09-29 11:58:23 CEST; 1min 48s ago
     Docs: man:httpd.service(8)
 Main PID: 2182 (httpd)
   Status: "Running, listening on: port 80"
    Tasks: 213 (limit: 4178)
   Memory: 25.8M
   CGroup: /system.slice/httpd.service
           ├─2182 /usr/sbin/httpd -DFOREGROUND
           ├─2183 /usr/sbin/httpd -DFOREGROUND
           ├─2184 /usr/sbin/httpd -DFOREGROUND
           ├─2185 /usr/sbin/httpd -DFOREGROUND
           └─2186 /usr/sbin/httpd -DFOREGROUND

Sep 29 11:58:22 web.tp2.linux systemd[1]: Starting The Apache HTTP Server...
Sep 29 11:58:23 web.tp2.linux systemd[1]: Started The Apache HTTP Server.
Sep 29 11:58:23 web.tp2.linux httpd[2182]: Server configured, listening on: port 80
[neva@web ~]$ systemctl is-active httpd
active
```

On vérifie qu'il est up avec la commande `curl` : 
``` html
[neva@web ~]$ curl localhost
<!doctype html>
<html>
  [...]
      <footer class="col-sm-12">
      <a href="https://apache.org">Apache&trade;</a> is a registered trademark of <a href="https://apache.org">the Apache Software Foundation</a> in the United States and/or other countries.<br />
      <a href="https://nginx.org">NGINX&trade;</a> is a registered trademark of <a href="https://">F5 Networks, Inc.</a>.
      </footer>
  [...]
</html>
```

### 2. Avancer vers la maîtrise du service

Activation du démarrage automatique : `sudo systemctl enable httpd`

Auto start au boot : `[neva@web ~]$ systemctl is-active httpd`

Fichier du service apache :
``` bash
[neva@web ~]$ cat /etc/systemd/system/multi-user.target.wants/httpd.service
[...]
[Unit]
Description=The Apache HTTP Server
Wants=httpd-init.service
After=network.target remote-fs.target nss-lookup.target httpd-init.service
Documentation=man:httpd.service(8)

[Service]
Type=notify
Environment=LANG=C

ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
# Send SIGWINCH for graceful stop
KillSignal=SIGWINCH
KillMode=mixed
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

Utilisateur utilisé par apache : 
``` bash
[neva@web ~]$ cat /etc/httpd/conf/httpd.conf | grep "User "
User apache
```

On vérifie que le service tourne bien avec cet utilisateur :
``` bash
[neva@web ~]$   
apache      2183    2182  0 11:58 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache      2184    2182  0 11:58 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache      2185    2182  0 11:58 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache      2186    2182  0 11:58 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
neva        2630    1530  0 12:27 pts/0    00:00:00 grep --color=auto apache
```

On voit que tous les fichiers appartiennent à l'utilisateur root :
``` bash
[neva@web ~]$ ls -al /var/www
total 4
drwxr-xr-x.  4 root root   33 Sep 29 11:52 .
drwxr-xr-x. 22 root root 4096 Sep 29 11:52 ..
drwxr-xr-x.  2 root root    6 Jun 11 17:35 cgi-bin
drwxr-xr-x.  2 root root    6 Jun 11 17:35 html
```

On voit que le contenu du site peut etre lu et exécuté par l'utilisateur apache, mais pas modifié.

On crée le nouel utilisateur pour apache :

```[neva@web ~]$ sudo useradd -d /var/www/ -g apache -M -N -s /sbin/nologin newApacheUser```

On change la ligne `User = apache` en `User = newApacheUser`

On restart et on vérifie qu'il tourne bien sur le nouvel utilisateur :
``` bash
[neva@web ~]$ sudo systemctl restart httpd
[neva@web ~]$ ps -ef | grep newApac
newApac+    1773    1771  0 09:47 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
newApac+    1774    1771  0 09:47 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
newApac+    1775    1771  0 09:47 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
newApac+    1776    1771  0 09:47 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
```

On remplace `Listen 80` par `Listen 8080` pour qu'il tourne sur le port 443.
```
[neva@web ~]$ sudo systemctl restart httpd
[neva@web ~]$ ss -ltn | grep 8080
LISTEN 0      128                *:8080            *:*
[neva@web ~]$ sudo firewall-cmd --add-port=8080/tcp
[neva@web ~]$ curl localhost:8080
<!doctype html>
<html>
[...]
</html>
```

L'accès depuis le navigateur fonctionne.

## II. Une stack web plus avancée

### 1. Intro

Installation du serveur web et de nextcloud :
``` bash
dnf install epel-release
dnf update
dnf install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
dnf module list php
dnf module enable php:remi-7.4
dnf install -y httpd vim wget zip unzip libxml2 openssl php74-php php74-php-ctype php74-php-curl php74-php-gd php74-php-iconv php74-php-json php74-php-libxml php74-php-mbstring php74-php-openssl php74-php-posix php74-php-session php74-php-xml php74-php-zip php74-php-zlib php74-php-pdo php74-php-mysqlnd php74-php-intl php74-php-bcmath php74-php-gmp
systemctl enable httpd
mkdir /etc/httpd/sites-available
vi /etc/httpd/sites-available/web.tp2.linux
# On ajoute la config du site
ln -s /etc/httpd/sites-available/web.tp2.linux /etc/httpd/sites-enabled/
mkdir -p /var/www/sub-domains/web.tp2.linux/html
timedatectl
vi /etc/opt/remi/php74/php.ini
wget https://download.nextcloud.com/server/releases/nextcloud-22.2.0.zip
unzip nextcloud-22.2.0.zip
cd nextcloud/
cp -Rf * /var/www/sub-domains/web.tp2.linux/html/
chown -Rf apache.apache /var/www/sub-domains/web.tp2.linux/html
systemctl restart httpd
firewall-cmd --add-port=80/tcp
vim /etc/httpd/conf/httpd.conf
# On ajoute le site-enabld/* dans le ficier de conf
```
Installation de la base de donnée :
``` bash
sudo dnf install mariadb-server
systemctl enable mariadb
systemctl restart mariadb
mysql_secure_installation
sudo mysql_secure_installation
```

Le port de mariadb est 3306 :
``` bash
[neva@db ~]$ ss -ltn
State         Recv-Q        Send-Q               Local Address:Port               Peer Address:Port       Process
LISTEN        0             128                        0.0.0.0:22                      0.0.0.0:*
LISTEN        0             80                             *:3306                            *:*
LISTEN        0             128                           [::]:22                         [::]:*
```

### B. Base de données

Installation de la base et de l'utilisateur nextcloud :
```
MariaDB [(none)]> CREATE USER 'nextcloud'@'10.101.1.11' IDENTIFIED BY 'nextcloud';
Query OK, 0 rows affected (0.000 sec)

MariaDB [(none)]> CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
Query OK, 1 row affected (0.000 sec)

MariaDB [(none)]> GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'10.101.1.11';
Query OK, 0 rows affected (0.000 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.000 sec)
```

On se connecte a la base depuis web :
``` bash
[neva@web ~]$ mysql -u nextcloud -h 10.101.1.12 -p
Enter password:
[...]
MariaDB [(none)]> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| nextcloud          |
+--------------------+
2 rows in set (0.002 sec)

MariaDB [(none)]> USE nextcloud;
Database changed
MariaDB [nextcloud]> SHOW TABLES;
Empty set (0.001 sec)****
```

On regarde quels sont les utilisateurs de la base de donnée :
``` bash
MariaDB [(none)]> SELECT user, host FROM mysql.user;
+-----------+--------------+
| user      | host         |
+-----------+--------------+
| nextcloud | 10.101.1.11  |
| nextcloud | 10.102.1.11  |
| root      | 127.0.0.1    |
| root      | ::1          |
| root      | db.tp2.linux |
| root      | localhost    |
+-----------+--------------+
6 rows in set (0.000 sec)
```

Dans le navigateur, on rentre le un om d'utilisateur, un mot de passe et les infos de la base de données (ip, user, passwd).

Affichage du nombre de tables créées par nextcloud :
``` bash
MariaDB [nextcloud]> USE nextcloud;
Database changed
MariaDB [nextcloud]> SELECT FOUND_ROWS();
+--------------+
| FOUND_ROWS() |
+--------------+
|           87 |
+--------------+
1 row in set (0.000 sec)

# OU :

SELECT COUNT(*) from information_schema.tables where TABLE_SCHEMA = 'nextcloud';
```

Liste des machines avec ip :
| Machine         | IP            | Service     | Port ouvert     | IP autorisées |
| --------------- | ------------- | ----------- | --------------- | ------------- |
| `web.tp2.linux` | `10.101.1.11` | Serveur Web | 80tcp / 22tcp   | *             |
| `db.tp2.linux`  | `10.101.1.12` | Serveur Db  | 3306tcp / 22tcp | `10.101.1.11` |
