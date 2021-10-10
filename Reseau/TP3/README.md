# TP3 : Progressons vers le réseau d'infrastructure

## I. (mini) Architecture réseau

On crée le routeur et on vérifie les paramètres :
``` bash
[neva@router ~]$ ip a
[...]
3: ens37: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    [...]
    inet 10.3.1.126/25 brd 10.3.1.127 scope global noprefixroute ens37
    [...]
4: ens38: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    [...]
    inet 10.3.1.190/25 brd 10.3.1.255 scope global noprefixroute ens38
    [...]
5: ens39: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    [...]
    inet 10.3.1.222/27 brd 10.3.1.223 scope global noprefixroute ens39
    [...]
[neva@router ~]$ ping 8.8.8.8
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=128 time=52.6 ms
[...]
[neva@router ~]$ ping www.google.com
PING www.google.com (172.217.22.132) 56(84) bytes of data.
64 bytes from par21s12-in-f4.1e100.net (172.217.22.132): icmp_seq=1 ttl=128 time=41.5 ms
[...]
[neva@router ~]$ hostname
router.tp3
[neva@router ~]$ sudo firewall-cmd --get-active-zone
public
  interfaces: ens33 ens37 ens38 ens39
[neva@router ~]$ sudo firewall-cmd --add-masquerade --zone=public
success
[neva@router ~]$ sudo firewall-cmd --add-masquerade --zone=public --permanent
success
```

## II. Services d'infra

### 1. Serveur DHCP

Installation et configuration du serveur :
``` bash
[neva@dhcp ~]$ sudo dnf -y install dhcp-server
[sudo] password for neva:
Rocky Linux 8 - AppStream                                                                13 kB/s | 4.8 kB     00:00
[...]
Installed:
  dhcp-server-12:4.3.6-44.el8_4.1.x86_64

Complete!
[neva@dhcp ~]$ sudo vi /etc/dhcp/dhcpd.conf
```
Contenu du fichier :
``` bash
default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet 10.3.1.128 netmask 255.255.255.192 {
    range dynamic-bootp 10.3.1.130 10.3.1.180;
    option broadcast-address 10.3.1.191;
    option routers 10.3.1.190;
    option domain-name-servers 10.3.1.2, 1.1.1.1;
}
```

Suite de la configuration :
``` bash
[neva@dhcp ~]$ sudo systemctl enable --now dhcpd
Created symlink /etc/systemd/system/multi-user.target.wants/dhcpd.service → /usr/lib/systemd/system/dhcpd.service.
[neva@dhcp ~]$ sudo firewall-cmd --add-service=dhcp
success
[neva@dhcp ~]$ sudo firewall-cmd --runtime-to-permanent
success
```

On crée marcel et on vérifie qu'il à bien récupéré une ip via le DHCP :
``` bash
[neva@marcel ~]$ cat /etc/sysconfig/network-scripts/ifcfg-ens33
TYPE=Ethernet
PROXY_METHOD=none
BROWSER_ONLY=no
BOOTPROTO=dhcp
[...]
[neva@marcel ~]$ ip a
[...]
2: ens33: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    [...]
    inet 10.3.1.131/26 brd 10.3.1.191 scope global dynamic noprefixroute ens33
    [...]
```

On regarde si il a bien accès à inetrnet avec de la résolution de nom :
``` bash
[neva@marcel ~]$ ping google.com
PING google.com (172.217.19.238) 56(84) bytes of data.
64 bytes from par21s11-in-f14.1e100.net (172.217.19.238): icmp_seq=1 ttl=127 time=38.1 ms
64 bytes from par21s11-in-f14.1e100.net (172.217.19.238): icmp_seq=2 ttl=127 time=42.6 ms
[...]
```

On vérifie qu'il passe bien par `router.tp3` pour sortir du réseau :
``` bash
[neva@marcel ~]$ traceroute google.com
traceroute to google.com (142.250.179.110), 30 hops max, 60 byte packets
 1  _gateway (10.3.1.190)  2.016 ms  1.933 ms  1.865 ms
 2  192.168.192.2 (192.168.192.2)  1.757 ms  1.660 ms  1.422 ms
 3  * * *
```
Il passe bien par le routeur `10.3.1.190` puis par la carte NAT du routeur `192.168.192.2`.

### 2. Serveur DNS

#### A. Our own DNS server

Instalation et configuration du DNS :
``` bash
[neva@dns1 ~]$ sudo dnf install bind
R[...]
Installing:
 bind                     x86_64                     32:9.11.26-4.el8_4                     appstream                     2.1 M
[...]
Complete!
[neva@dns1 ~]$ cat /etc/resolv.conf
nameserver 1.1.1.1
[neva@dns1 ~]$ sudo cat /etc/named.conf
//
// named.conf
//
[...]
zone "serveur1.tp3" IN {
        type master;
        file "/var/named/forward.serveur1.tp3";
        allow-update { none; };
};

zone "serveur2.tp3" IN {
        type master;
        file "/var/named/forward.serveur2.tp3";
        allow-update { none; };
};
[...]
[neva@dns1 ~]$ sudo cat /var/named/forward.serveur1.tp3
@       IN SOA dns1.serveur1.tp3 mail.toto (
                                2014030801      ; serial
                                3600      ; refresh
                                1800      ; retry
                                604800      ; expire
                                86400 )    ; minimum

; define nameservers
        IN  NS  dns1.serveur1.tp3.
;
; DNS Server IP addresses and hostnames
dns1 IN  A   10.3.1.2
;
;client records
routeur IN A 10.3.1.126
[neva@dns1 ~]$ sudo cat /var/named/forward.serveur2.tp3
@       IN SOA dns1.serveur1.tp3 mail.toto (
                                2014030801      ; serial
                                3600      ; refresh
                                1800      ; retry
                                604800      ; expire
                                86400 )    ; minimum

; define nameservers
        IN  NS  dns1.serveur1.tp3.
;



;
;client records
routeur IN A 10.3.1.222
[neva@dns1 ~] sudo firewall-cmd --add-service=dns
success
```

On le teste depuis marcel :
``` bash
[neva@marcel ~]$ cat /etc/resolv.conf
nameserver 10.3.1.2
[neva@marcel ~]$ dig routeur
[...]
;; QUESTION SECTION:
;routeur.                       IN      A

;; AUTHORITY SECTION:
.                       10393   IN      SOA     a.root-servers.net. nstld.verisign-grs.com. 2021100401 1800 900 604800 86400
[...]
[neva@marcel ~]$ dig google.com
[...]
;; QUESTION SECTION:
;google.com.                    IN      A

;; ANSWER SECTION:
google.com.             160     IN      A       142.250.179.110

;; AUTHORITY SECTION:
google.com.             172660  IN      NS      ns1.google.com.
google.com.             172660  IN      NS      ns2.google.com.
google.com.             172660  IN      NS      ns3.google.com.
google.com.             172660  IN      NS      ns4.google.com.

;; ADDITIONAL SECTION:
ns2.google.com.         172660  IN      A       216.239.34.10
ns1.google.com.         172660  IN      A       216.239.32.10
ns3.google.com.         172660  IN      A       216.239.36.10
[...]
```

On ajoute le dns sur toutes les machines en modifiant `nameserver` dans `/etc/resolv.conf`.

On a rien à rajouter dans la config du dhcp puis ce que la lingne du dns avait déja été ajoutée dans la première configuration.

Après avoir démarré johnny, avoir configuré son hostname et sa connecton en dhcp, on teste si la résolution de nom est disponible :
``` bash
[neva@johnny ~]$ dig routeur.serveur1.tp3
[...]
;; QUESTION SECTION:
;routeur.serveur1.tp3.          IN      A

;; ANSWER SECTION:
routeur.serveur1.tp3.   86400   IN      A       10.3.1.126

;; AUTHORITY SECTION:
serveur1.tp3.           86400   IN      NS      dns1.serveur1.tp3.

;; ADDITIONAL SECTION:
dns1.serveur1.tp3.      86400   IN      A       10.3.1.2
[...]
```

## III. Services métier

### 1. Serveur Web

On crée la machine et on configure son réseau et son hostneme et on l'ajoute au dns.
On installe le serveur web : 
``` bash
[neva@web1 ~]$ sudo dnf install nginx
Last metadata expiration check: 0:00:11 ago on Tue 05 Oct 2021 12:12:02 PM CEST.
Dependencies resolved.
[...]
Complete!
[neva@web1 ~]$ sudo systemctl enable --now nginx
Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service → /usr/lib/systemd/system/nginx.service.
[neva@web1 ~]$ sudo firewall-cmd --add-port=80/tcp
success
```

On vérifie qu'il est acessible depuis `marcel` : 
``` html
[neva@marcel ~]$ dig web1.serveur2.tp3
[...]
;; QUESTION SECTION:
;web1.serveur2.tp3.             IN      A
]
;; ANSWER SECTION:
web1.serveur2.tp3.      86400   IN      A       10.3.1.194
[...]
[neva@marcel ~]$ curl web1.serveur2.tp3
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en">
[...]
</html>
```

On installe la VM nfs1 et on la configure, puis on installe le serveur nfs :
``` bash
[neva@nfs1 ~]$ sudo mkdir /srv/nfs_share/
[neva@nfs1 ~]$ cd /srv/nfs_share/
[neva@nfs1 nfs_share]$ sudo dnf -y install nfs-utils
[...]
Complete!
[neva@nfs1 nfs_share]$ sudo vi /etc/idmapd.conf
# On change le domain name en serveur2.tp3
[neva@nfs1 nfs_share]$ sudo vi /etc/exports
# On ajoute /srv/nfs_share 10.3.1.192/27(rw,no_root_squash)
[neva@nfs1 nfs_share]$ sudo systemctl enable --now rpcbind nfs-server
[neva@nfs1 nfs_share]$ sudo firewall-cmd --add-service=nfs
success
[neva@nfs1 nfs_share]$ sudo firewall-cmd --add-service={nfs3,mountd,rpc-bind}
success
[neva@nfs1 nfs_share]$ sudo firewall-cmd --runtime-to-permanent
success
```

On configure le client nfs :
``` bash
[neva@web1 ~]$ sudo mkdir /srv/nfs
[neva@web1 ~]$ sudo dnf -y install nfs-utils
Last metadata expiration check: 0:35:55 ago on Tue 05 Oct 2021 12:12:02 PM CEST.
Dependencies resolved.
[...]
Complete!
[neva@web1 ~]$ sudo vi /etc/idmapd.conf
[neva@web1 ~]$ sudo mount -t nfs nfs1.serveur2.tp3:/srv/nfs_share /srv/nfs
```

Si je crée un fichier toto depuis `nfs`, on peut le voir depuis `web1` :
``` bash
# Sur nfs1
[neva@nfs1 nfs_share]$ sudo touch /srv/nfs_share/toto
# Sur web1
[neva@web1 ~]$ ls /srv/nfs/
toto
```

## IV. Un peu de théorie : TCP et UDP

[ssh]:https://github.com/Tractorou24/LinuxReseauB2/tree/master/Reseau/TP3/tp3_ssh.pcap
[http]:https://github.com/Tractorou24/LinuxReseauB2/tree/master/Reseau/TP3/tp3_http.pcap
[dns]:https://github.com/Tractorou24/LinuxReseauB2/tree/master/Reseau/TP3/tp3_dns.pcap
[nfs]:https://github.com/Tractorou24/LinuxReseauB2/tree/master/Reseau/TP3/tp3_nfs.pcap
[3way]:https://github.com/Tractorou24/LinuxReseauB2/tree/master/Reseau/TP3/tp3_3way.pcap

| Protocole     | TCP ou UDP ? | Fichier de capture |
| ------------- | :----------- | ------------------ |
| SSH           | TCP          | [:link:][ssh]      |
| HTTP          | TCP          | [:link:][http]     |
| DNS           | UDP          | [:link:][dns]      |
| NFS           | UDP          | [:link:][nfs]      |
| TCP HANDSHAKE | TCP          | [:link:][3way]     |

## V. El final

Tableau des réseaux :
| Nom du réseau | Adresse du réseau | Masque            | Nombre de clients possibles | Adresse passerelle | Adresse broadcast |
| ------------- | ----------------- | ----------------- | --------------------------- | ------------------ | ----------------- |
| `client1`     | `10.3.1.128`      | `255.255.255.192` | 62                          | `10.3.1.190`       | `10.3.1.191`      |
| `server1`     | `10.3.1.0`        | `255.255.255.128` | 126                         | `10.3.1.126`       | `10.3.1.127`      |
| `server2`     | `10.3.1.192`      | `255.255.255.224` | 30                          | `10.3.1.222`       | `10.3.1.223`      |

Tableau d'adressage :
| Nom machine  | Adresse IP `client1` | Adresse IP `server1` | Adresse IP `server2` | Adresse de passerelle |
| ------------ | -------------------- | -------------------- | -------------------- | --------------------- |
| `router.tp3` | `10.3.1.190/26`      | `10.3.1.126/25`      | `10.3.1.222/27`      | Carte NAT             |
| `dhcp.tp3`   | `10.3.1.189/26`      |                      |                      | `10.3.1.190/26`       |
| `marcel.tp3` | `10.3.1.131/26` DHCP |                      |                      | `10.3.1.190/26`       |
| `johnny.tp3` | `10.3.1.167/26` DHCP |                      |                      | `10.3.1.190/26`       |
| `dns1.tp3`   |                      | `10.3.1.2/25`        |                      | `10.3.1.126/25`       |
| `web1.tp3`   |                      |                      | `10.3.1.194/27`      | `10.3.1.222/27`       |
| `nfs1.tp3`   |                      |                      | `10.3.1.195/27`      | `10.3.1.222/27`       |


Schéma d'adressage et de réseau :
![](https://i.imgur.com/rkIOlTV.png)

[dhcpd]:https://github.com/Tractorou24/LinuxReseauB2/tree/master/Reseau/TP3/dhcpd.conf
[named]:https://github.com/Tractorou24/LinuxReseauB2/tree/master/Reseau/TP3/named.conf
[zone1]:https://github.com/Tractorou24/LinuxReseauB2/tree/master/Reseau/TP3/forward.serveur1.tp3
[zone2]:https://github.com/Tractorou24/LinuxReseauB2/tree/master/Reseau/TP3/forward.serveur2.tp3

Fichiers :
| Nom        | Lien            |
| ---------- | :-------------- |
| dhcpd.conf | [:link:][dhcpd] |
| named.conf | [:link:][named] |
| zone1      | [:link:][zone1] |
| zone2      | [:link:][zone2] |
