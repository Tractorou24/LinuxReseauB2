# TP2 : On va router des trucs

## I. ARP

### 1. Echange ARP

node1 (avant le ping):
```
[neva@node1 ~]$ arp
Address                  HWtype  HWaddress           Flags Mask            Iface
_gateway                 ether   00:50:56:fd:87:dc   C                     ens33
10.2.1.1                 ether   00:50:56:c0:00:02   C                     ens37
``````
On ping la node1 avec node2 et on récupère sa MAC :
```
[neva@node2 ~]$ ping 10.2.1.11
PING 10.2.1.11 (10.2.1.11) 56(84) bytes of data.
64 bytes from 10.2.1.11: icmp_seq=1 ttl=64 time=1.24 ms
64 bytes from 10.2.1.11: icmp_seq=2 ttl=64 time=0.785 ms
64 bytes from 10.2.1.11: icmp_seq=3 ttl=64 time=0.949 ms
64 bytes from 10.2.1.11: icmp_seq=4 ttl=64 time=0.622 ms
^C
--- 10.2.1.11 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3029ms
rtt min/avg/max/mdev = 0.622/0.899/1.242/0.231 ms
[neva@node2 ~]$ ip a
[...]
3: ens37: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:0c:29:1a:2c:47 brd ff:ff:ff:ff:ff:ff
[...]
[neva@node2 ~]$ arp
Address                  HWtype  HWaddress           Flags Mask            Iface
10.2.1.11                ether   00:0c:29:01:66:ef   C                     ens37
192.168.192.254          ether   00:50:56:f3:ce:1f   C                     ens33
10.2.1.1                 ether   00:50:56:c0:00:02   C                     ens37
_gateway                 ether   00:50:56:fd:87:dc   C                     ens33
```

node1 (après le ping) :
```
[neva@node1 ~]$ arp
Address                  HWtype  HWaddress           Flags Mask            Iface
10.2.1.12                ether   00:0c:29:1a:2c:47   C                     ens37
_gateway                 ether   00:50:56:fd:87:dc   C                     ens33
10.2.1.1                 ether   00:50:56:c0:00:02   C                     ens37
[neva@node1 ~]$ ip a
[...]
3: ens37: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:0c:29:01:66:ef brd ff:ff:ff:ff:ff:ff
[...]
```

On voit que l'adresse insérée dans la table ARP de node1 est bien la MAC de node2 (00:0c:29:1a:2c:47).
Inversement, la MAC de node1 (00:0c:29:01:66:ef) est bien dans la table ARP de node2.

### 2. Analyse de trames

Sur node1 :
```
[neva@node1 ~]$ sudo ip -s -s neigh flush all
10.2.1.1 dev ens37 lladdr 00:50:56:c0:00:02 ref 1 used 5/0/5 probes 4 REACHABLE

*** Round 1, deleting 1 entries ***
*** Flush is complete after 1 round ***
[neva@node1 ~]$ sudo tcpdump -i ens37 icmp -s 65535 -w tp2_arp
dropped privs to tcpdump
tcpdump: listening on ens37, link-type EN10MB (Ethernet), capture size 65535 bytes
^C8 packets captured
9 packets received by filter
0 packets dropped by kernel
```

Sur node2:
```
[neva@node2 ~]$ sudo ip -s -s neigh flush all
10.2.1.1 dev ens37 lladdr 00:50:56:c0:00:02 ref 1 used 2/0/2 probes 4 REACHABLE

*** Round 1, deleting 1 entries ***
*** Flush is complete after 1 round ***
[neva@node2 ~]$ ping 10.2.1.11
PING 10.2.1.11 (10.2.1.11) 56(84) bytes of data.
64 bytes from 10.2.1.11: icmp_seq=1 ttl=64 time=1.18 ms
64 bytes from 10.2.1.11: icmp_seq=2 ttl=64 time=0.654 ms
64 bytes from 10.2.1.11: icmp_seq=3 ttl=64 time=1.32 ms
64 bytes from 10.2.1.11: icmp_seq=4 ttl=64 time=0.907 ms
^C
--- 10.2.1.11 ping statistics ---
4 packets transmitted, 4 received, 0% packet loss, time 3023ms
rtt min/avg/max/mdev = 0.654/1.015/1.316/0.255 ms
```

Les paquets ARP sur Wireshark :
![](https://i.imgur.com/EyZUjD3.png)

Les trames :
| Ordre | Type trame  | Source                      | Destination                   |
| ----- | ----------- | --------------------------- | ----------------------------- |
| 1     | Requête ARP | `node1` `00:0c:29:01:66:ef` | Broadcast `ff:ff:ff:ff:ff:ff` |
| 2     | Réponse ARP | `node2` `00:0c:29:1a:2c:47` | `node1` `00:0c:29:01:66:ef`   |

## II. Routage
### 1. Mise en place du routage

```
[neva@router ~]$ sudo firewall-cmd --add-masquerade --zone=public
success
[neva@router ~]$ sudo firewall-cmd --add-masquerade --zone=public --permanent
success
```

Ajout des routes statiques :

Sur node1 :
```
[neva@node1 ~]$ sudo ip route add default via 10.2.1.11
[neva@node1 ~]$ ip route show
default via 10.2.1.11 dev ens37
10.2.1.0/24 dev ens37 proto kernel scope link src 10.2.1.12 metric 100
```
Sur macel :
```
[neva@marcel ~]$ sudo ip route add default via 10.2.2.11
[neva@marcel ~]$ sudo ip route show
default via 10.2.2.11 dev ens37
10.2.2.0/24 dev ens37 proto kernel scope link src 10.2.2.12 metric 100
```

On peut maintenant ping marcel depuis node1 et inversement :
```
[neva@node1 ~]$ ping 10.2.2.12
PING 10.2.2.12 (10.2.2.12) 56(84) bytes of data.
64 bytes from 10.2.2.12: icmp_seq=1 ttl=63 time=1.40 ms
64 bytes from 10.2.2.12: icmp_seq=2 ttl=63 time=1.18 ms
[...]
```
```
[neva@marcel ~]$ ping 10.2.1.12
PING 10.2.1.12 (10.2.1.12) 56(84) bytes of data.
64 bytes from 10.2.1.12: icmp_seq=1 ttl=63 time=1.36 ms
64 bytes from 10.2.1.12: icmp_seq=2 ttl=63 time=1.16 ms
[...]
```

### 2. Analyse de trames :

Sur node1 :
```
[neva@node1 ~]$ sudo ip neigh flush all
[neva@node1 ~]$ ping 10.2.2.12
PING 10.2.2.12 (10.2.2.12) 56(84) bytes of data.
64 bytes from 10.2.2.12: icmp_seq=1 ttl=63 time=1.69 ms
64 bytes from 10.2.2.12: icmp_seq=2 ttl=63 time=1.06 ms
^C
--- 10.2.2.12 ping statistics ---
2 packets transmitted, 2 received, 0% packet loss, time 1005ms
rtt min/avg/max/mdev = 1.060/1.375/1.691/0.317 ms
[neva@node1 ~]$ arp
Address                  HWtype  HWaddress           Flags Mask            Iface
_gateway                 ether   00:50:56:36:bb:3f   C                     ens37
10.2.1.1                 ether   00:50:56:c0:00:02   C                     ens37
```

Sur marcel :
```
[neva@marcel ~]$ sudo ip neigh flush all
        [...PING...]
[neva@marcel ~]$ arp
Address                  HWtype  HWaddress           Flags Mask            Iface
_gateway                 ether   00:50:56:26:e1:1d   C                     ens37
10.2.2.1                 ether   00:50:56:c0:00:03   C                     ens37
```

Sur le routeur :
```
[neva@router ~]$ sudo ip neigh flush all
        [...PING...]
[neva@router ~]$ arp
Address                  HWtype  HWaddress           Flags Mask            Iface
10.2.1.12                ether   00:50:56:37:b9:53   C                     ens37
_gateway                 ether   00:50:56:fd:87:dc   C                     ens33
10.2.2.12                ether   00:50:56:20:1d:93   C                     ens38
10.2.1.1                 ether   00:50:56:c0:00:02   C                     ens37
```

On peut déduire que node1 utilise sa route par défaut (car marcel n'est pas dans son réseau), que le routeur reçcoit la demande et la transmet à marcel.
Au début, aucune machine ne conaissait ses voisines. A la fin, node1 et marcel connaissent router, qui lui connait les 2.

On recommance en activant ```tcpdump``` :

Les trames :
| Ordre | Type trame   | IP Source | Mac Source                   | IP Destination | Destination                   |
| ----- | ------------ | --------- | ---------------------------- | -------------- | ----------------------------- |
| 1     | Requête ARP  |           | `node1` `00:50:56:37:b9:53`  |                | Broadcast `ff:ff:ff:ff:ff:ff` |
| 2     | Réponse ARP  |           | `router` `00:50:56:36:bb:3f` |                | `node1` `00:50:56:37:b9:53`   |
| 3     | Requête ICMP | 10.2.1.12 | `node1` `00:50:56:37:b9:53`  | 10.2.2.12      | `router` `00:50:56:36:bb:3f`  |
| 4     | Requête ARP  |           | `marcel` `00:50:56:26:e1:1d` |                | Broadcast `ff:ff:ff:ff:ff:ff` |
| 5     | Réponse ARP  |           | `router` `00:50:56:20:1d:93` |                | `marcel` `00:50:56:26:e1:1d`  |
| 6     | Requête ICMP | 10.2.1.12 | `marcel` `00:50:56:26:e1:1d` | 10.2.2.12      | `router` `00:50:56:20:1d:93`  |
| 7     | Réponse ICMP | 10.2.2.12 | `router` `00:50:56:20:1d:93` | 10.2.2.11      | `marcel` `00:50:56:20:1d:93`  |
| 8     | Réponse ICMP | 10.2.2.12 | `router` `00:50:56:36:bb:3f` | 10.2.1.12      | `node1` `00:50:56:37:b9:53`   |

### 3. Accès internet

La route par défaut a été ajoutée à la partie précédente.

Pour ajouter un serveur dns, on modifie la ligne nameserver dans /etc/resolv.conf.

On teste la conenction au dns et à google.com.
```
[neva@marcel ~]$ ping 1.1.1.1
PING 1.1.1.1 (1.1.1.1) 56(84) bytes of data.
64 bytes from 1.1.1.1: icmp_seq=1 ttl=127 time=22.4 ms
[...]
[neva@marcel ~]$ dig www.google.com
[...]
;; QUESTION SECTION:
;www.google.com.                        IN      A

;; ANSWER SECTION:
www.google.com.         72      IN      A       216.58.214.164
[...]
[neva@marcel ~]$ ping www.google.com
PING www.google.com (216.58.214.164) 56(84) bytes of data.
64 bytes from mad01s26-in-f164.1e100.net (216.58.214.164): icmp_seq=1 ttl=127 time=38.7 ms
64 bytes from mad01s26-in-f164.1e100.net (216.58.214.164): icmp_seq=2 ttl=127 time=21.4 ms
[...]
```

Les trames :
| Ordre | Type trame   | IP Source | Mac Source                   | IP Destination | Destination                   |
| ----- | ------------ | --------- | ---------------------------- | -------------- | ----------------------------- |
| 1     | Requête ARP  |           | `node1` `00:50:56:37:b9:53`  |                | Broadcast `ff:ff:ff:ff:ff:ff` |
| 2     | Réponse ARP  |           | `router` `00:50:56:36:bb:3f` |                | `node1` `00:50:56:37:b9:53`   |
| 3     | Requête ICMP | 10.2.1.12 | `node1` `00:50:56:37:b9:53`  | 8.8.8.8        | `router` `00:50:56:36:bb:3f`  |
| 4     | Réponse ICMP | 8.8.8.8   | `router` `00:50:56:36:bb:3f` | 10.2.1.12      | `node1` `00:50:56:37:b9:53`   |

## III. DHCP

Installation et configuration du serveur :
```
[neva@node1 ~]$ sudo dnf -y install dhcp-server
[sudo] password for neva:
Rocky Linux 8 - AppStream                                                                13 kB/s | 4.8 kB     00:00
[...]
Installed:
  dhcp-server-12:4.3.6-44.el8_4.1.x86_64

Complete!
[neva@node1 ~]$ sudo vi /etc/dhcp/dhcpd.conf
```
Contenu du fichier :
```
default-lease-time 600;
max-lease-time 7200;
authoritative;

subnet 10.2.1.0 netmask 255.255.255.0 {
        range dynamic-bootp 10.2.1.13 10.2.1.254;
        option broadcast-address 10.2.1.255;
        option routers 10.2.1.11;
}
```

Suite de la configuration :
```
[neva@node1 ~]$ sudo systemctl enable --now dhcpd
Created symlink /etc/systemd/system/multi-user.target.wants/dhcpd.service → /usr/lib/systemd/system/dhcpd.service.
[neva@node1 ~]$ sudo firewall-cmd --add-service=dhcp
success
[neva@node1 ~]$ sudo firewall-cmd --runtime-to-permanent
success
```

### Analyse de trames :
| Ordre | Type trame   | IP Source | Mac Source                  | IP Destination  | Destination                   |
| ----- | ------------ | --------- | --------------------------- | --------------- | ----------------------------- |
| 1     | DHCP Request | 0.0.0.0   | `node2` `00:0c:29:1a:2c:47` | 255.255.255.255 | Broadcast `ff:ff:ff:ff:ff:ff` |
| 2     | DHCP AWK     | 10.2.1.12 | `node1` `00:50:56:37:b9:53` | 10.2.1.14       | `node2` `00:0c:29:1a:2c:47`   |

## IV. TCP et UDP

### 1. netcat UDP

On doit ouvrir le port UDP de notre netcap pour pouvoir communiquer ! `sudo firewall-cmd --add-port=portNB/udp`
On doit préciser -u dans la commande netcat pour le serveur et le client (pour l'UDP).

Analyse de trames :
| Ordre | Type trame | IP Source | Mac Source                  | IP Destination | Destination                 |
| ----- | ---------- | --------- | --------------------------- | -------------- | --------------------------- |
| 1     | UDP        | 10.2.1.14 | `node2` `00:0c:29:1a:2c:47` | 10.2.1.12      | `node1` `00:50:56:37:b9:53` |

### 2. netcat TCP

On doit ouvrir le port UDP de notre netcap pour pouvoir communiquer ! `sudo firewall-cmd --add-port=portNB/tcp`

Analyse de trames :
| Ordre | Type trame  | IP Source | Mac Source                  | IP Destination | Destination                 |
| ----- | ----------- | --------- | --------------------------- | -------------- | --------------------------- |
| 1     | TCP SYN     | 10.2.1.14 | `node2` `00:0c:29:1a:2c:47` | 10.2.1.12      | `node1` `00:50:56:37:b9:53` |
| 2     | TCP SYN ACK | 10.2.1.12 | `node1` `00:50:56:37:b9:53` | 10.2.1.14      | `node2` `00:0c:29:1a:2c:47` |
| 3     | TCP ACK     | 10.2.1.14 | `node2` `00:0c:29:1a:2c:47` | 10.2.1.12      | `node1` `00:50:56:37:b9:53` |
| 4     | TCP PSN ACK | 10.2.1.14 | `node2` `00:0c:29:1a:2c:47` | 10.2.1.12      | `node1` `00:50:56:37:b9:53` |
| 5     | TCP ACK     | 10.2.1.12 | `node1` `00:50:56:37:b9:53` | 10.2.1.14      | `node2` `00:0c:29:1a:2c:47` |
| 6     | TCP FIN ACK | 10.2.1.14 | `node2` `00:0c:29:1a:2c:47` | 10.2.1.12      | `node1` `00:50:56:37:b9:53` |
| 7     | TCP FIN ACK | 10.2.1.12 | `node1` `00:50:56:37:b9:53` | 10.2.1.14      | `node2` `00:0c:29:1a:2c:47` |
| 8     | TCP ACK     | 10.2.1.14 | `node2` `00:0c:29:1a:2c:47` | 10.2.1.12      | `node1` `00:50:56:37:b9:53` |

### 3. Deeper

On écoute depuis node1 et marcel se connecte. Le message a été envoyé par marcel.

Analyse de trames :
| Ordre | Type trame  | IP Source | Mac Source                   | IP Destination | Destination                  |
| ----- | ----------- | --------- | ---------------------------- | -------------- | ---------------------------- |
| 1     | TCP SYN     | 10.2.1.11 | `router` `00:50:56:36:bb:3f` | 10.2.1.12      | `router` `00:50:56:37:b9:53` |
| 2     | TCP SYN ACK | 10.2.1.12 | `node1` `00:50:56:37:b9:53`  | 10.2.1.11      | `router` `00:50:56:36:bb:3f` |
| 3     | TCP ACK     | 10.2.1.11 | `router` `00:50:56:36:bb:3f` | 10.2.1.12      | `node1` `00:50:56:37:b9:53`  |
| 2     | TCP PSH ACK | 10.2.1.12 | `node1` `00:50:56:37:b9:53`  | 10.2.1.11      | `router` `00:50:56:36:bb:3f` |
| 3     | TCP ACK     | 10.2.1.11 | `router` `00:50:56:36:bb:3f` | 10.2.1.12      | `node1` `00:50:56:37:b9:53`  |
| 2     | TCP FIN ACK | 10.2.1.12 | `node1` `00:50:56:37:b9:53`  | 10.2.1.11      | `router` `00:50:56:36:bb:3f` |
| 3     | TCP ACK     | 10.2.1.11 | `router` `00:50:56:36:bb:3f` | 10.2.1.12      | `node1` `00:50:56:37:b9:53`  |
| 3     | TCP FIN ACK | 10.2.1.11 | `router` `00:50:56:36:bb:3f` | 10.2.1.12      | `node1` `00:50:56:37:b9:53`  |
| 2     | TCP ACK     | 10.2.1.12 | `node1` `00:50:56:37:b9:53`  | 10.2.1.11      | `router` `00:50:56:36:bb:3f` |

### 4. Analyse de protocoles communs

SSH : Port 22 TCP

HTTPS : Port 443 TCP/TLS

DIG : Port 53 / UPD mais de plus en plus TCP