# TP1 - Mise en jambes

##  I. Exploration locale en solo

### 1. Affichage d'informations sur la pile TCP/IP locale

Infos cartes réseau :
```
PS C:\Users\DIRECTEUR_PC2> Get-NetAdapter

Name                      InterfaceDescription                    ifIndex Status       MacAddress             LinkSpeed
----                      --------------------                    ------- ------       ----------             ---------
Ethernet                  Realtek PCIe GbE Family Controller           10 Disconnected XX-XX-XX-XX-XX-XX          0 bps
Wi-Fi                     Intel(R) Wi-Fi 6 AX201 160MHz                 8 Up           XX-XX-XX-XX-XX-XX       104 Mbps
```

Passerelle de la carte wifi :
```
PS C:\Users\DIRECTEUR_PC2> ipconfig

Configuration IP de Windows
[...]
Carte réseau sans fil Wi-Fi :
   [...]
   Passerelle par défaut. . . . . . . . . : 10.33.3.253
```

En interface graphique :

Control Panel/View network status and tasks/[Network Name]/Details
![](https://i.imgur.com/bA2iqfW.png)

La gateway sert à faire aller sur d'autres réseaux que celui d'Ynov.
### 2. Modifications des informations
#### A. Modification d'adresse IP (part 1)

Modification d'IP par GUI :

Control Panel/View network status and tasks/[Network Name]/Properties/Internet Protocol Version 4/Properties
![](https://i.imgur.com/zWPosbZ.png)

Il est possible de perdre l'accès a internet si l'ip est déja utilisée.

#### B. Table ARP

Avant ping :
```
PS C:\Users\DIRECTEUR_PC2> arp -a

Interface : 169.254.66.94 --- 0x3
  Adresse Internet      Adresse physique      Type
  169.254.255.255       ff-ff-ff-ff-ff-ff     statique
  224.0.0.22            01-00-5e-00-00-16     statique

Interface : 169.254.134.63 --- 0x7
  Adresse Internet      Adresse physique      Type
  224.0.0.22            01-00-5e-00-00-16     statique

Interface : 10.33.3.81 --- 0x8
  Adresse Internet      Adresse physique      Type
  10.33.3.253           00-12-00-40-4c-bf     dynamique
  10.33.3.255           ff-ff-ff-ff-ff-ff     statique
  224.0.0.22            01-00-5e-00-00-16     statique

Interface : 172.25.48.1 --- 0x34
  Adresse Internet      Adresse physique      Type
  172.25.63.255         ff-ff-ff-ff-ff-ff     statique
  224.0.0.22            01-00-5e-00-00-16     statique
```

Après ping :
```
PS C:\Users\DIRECTEUR_PC2> arp -a

Interface : 169.254.66.94 --- 0x3
  Adresse Internet      Adresse physique      Type
  169.254.255.255       ff-ff-ff-ff-ff-ff     statique
  224.0.0.22            01-00-5e-00-00-16     statique
  239.255.255.250       01-00-5e-7f-ff-fa     statique

Interface : 169.254.134.63 --- 0x7
  Adresse Internet      Adresse physique      Type
  169.254.255.255       ff-ff-ff-ff-ff-ff     statique
  224.0.0.22            01-00-5e-00-00-16     statique
  239.255.255.250       01-00-5e-7f-ff-fa     statique

Interface : 10.33.3.81 --- 0x8
  Adresse Internet      Adresse physique      Type
  10.33.1.103           18-65-90-ce-f5-63     dynamique
  10.33.2.8             a4-5e-60-ed-0b-27     dynamique
  10.33.3.253           00-12-00-40-4c-bf     dynamique
  10.33.3.255           ff-ff-ff-ff-ff-ff     statique
  224.0.0.22            01-00-5e-00-00-16     statique
  239.255.255.250       01-00-5e-7f-ff-fa     statique

Interface : 172.25.48.1 --- 0x34
  Adresse Internet      Adresse physique      Type
  172.25.63.255         ff-ff-ff-ff-ff-ff     statique
  224.0.0.22            01-00-5e-00-00-16     statique
  239.255.255.250       01-00-5e-7f-ff-fa     statique
```
On voit que les ip 10.33.1.103 et 10.33.2.8 ont étées rajoutées après leur ping.

#### C. nmap

Scan du réseau :
```
PS C:\Users\DIRECTEUR_PC2> nmap -sP 10.33.0.0/22
Starting Nmap 7.92 ( https://nmap.org ) at 2021-09-13 12:11 Paris, Madrid (heure dÆÚtÚ)
Nmap scan report for 10.33.0.2
Host is up (0.060s latency).
MAC Address: DC:F5:05:CE:EC:F7 (AzureWave Technology)
Nmap scan report for 10.33.0.21
Host is up (0.019s latency).
MAC Address: B0:FC:36:CE:9C:89 (CyberTAN Technology)
Nmap scan report for 10.33.0.34
Host is up (0.10s latency).
MAC Address: AC:67:5D:83:9F:E6 (Intel Corporate)
Nmap scan report for 10.33.0.57
Host is up (0.059s latency).
MAC Address: F0:18:98:8C:6F:CD (Apple)
Nmap scan report for 10.33.0.95
Host is up (0.091s latency).
[...]
Nmap scan report for 10.33.3.81
Host is up.
Nmap done: 1024 IP addresses (95 hosts up) scanned in 20.53 seconds
```
Table ARP après le scan :
```
PS C:\Users\DIRECTEUR_PC2> arp -a
[...]
Interface : 10.33.3.81 --- 0x8
  Adresse Internet      Adresse physique      Type
  10.33.0.127           08-71-90-c8-1a-4f     dynamique
  10.33.0.245           84-fd-d1-f1-23-7c     dynamique
  10.33.1.63            70-66-55-a3-83-43     dynamique
  10.33.1.90            d0-ab-d5-18-55-f6     dynamique
  10.33.1.122           14-f6-d8-e6-67-48     dynamique
  10.33.1.152           e8-d0-fc-8a-ac-9f     dynamique
  10.33.1.194           20-16-b9-84-86-1d     dynamique
  10.33.1.205           e8-84-a5-31-6a-be     dynamique
  10.33.2.27            3c-58-c2-ec-71-33     dynamique
  10.33.2.46            80-30-49-cb-43-8f     dynamique
  10.33.2.84            e4-b3-18-48-36-68     dynamique
  10.33.2.122           18-56-80-70-9c-48     dynamique
  10.33.2.161           c8-09-a8-29-05-13     dynamique
  10.33.2.199           c8-e2-65-69-56-a4     dynamique
  10.33.2.203           f8-95-ea-1d-37-85     dynamique
  10.33.2.208           a4-b1-c1-72-13-98     dynamique
  10.33.2.209           a4-b1-c1-72-13-98     dynamique
  10.33.3.5             74-d8-3e-0d-06-b0     dynamique
  10.33.3.33            c8-58-c0-63-5a-92     dynamique
  10.33.3.139           34-cf-f6-37-2c-fb     dynamique
  10.33.3.163           50-eb-71-d6-73-dd     dynamique
  10.33.3.179           94-e7-0b-0a-46-aa     dynamique
  10.33.3.189           c2-6f-43-3d-c7-fa     dynamique
  10.33.3.236           3e-02-9d-7d-30-8f     dynamique
  10.33.3.249           58-96-1d-17-43-f5     dynamique
  10.33.3.253           00-12-00-40-4c-bf     dynamique
  10.33.3.255           ff-ff-ff-ff-ff-ff     statique
  224.0.0.22            01-00-5e-00-00-16     statique
  224.0.0.251           01-00-5e-00-00-fb     statique
  224.0.0.252           01-00-5e-00-00-fc     statique
  239.255.102.18        01-00-5e-7f-66-12     statique
  239.255.255.250       01-00-5e-7f-ff-fa     statique
[...]
```

#### D. Modification d'adresse IP (partie 2)

On cherche les adresses non utilisées :
```
PS C:\Users\DIRECTEUR_PC2> nmap -v -sn -n 10.33.0.0/22 -oG - | findstr "Down"
Host: 10.33.0.0 ()      Status: Down
Host: 10.33.0.1 ()      Status: Down
Host: 10.33.0.3 ()      Status: Down
Host: 10.33.0.4 ()      Status: Down
[...]
Host: 10.33.3.255 ()    Status: Down
```
On change ensuite d'IP statiquement, comme expliqué précédamment.
On choisit l'adresse 10.33.0.1 :
```
PS C:\Users\DIRECTEUR_PC2> ipconfig /all

Configuration IP de Windows
[...]
Carte réseau sans fil Wi-Fi :

   Suffixe DNS propre à la connexion. . . :
   Description. . . . . . . . . . . . . . : Intel(R) Wi-Fi 6 AX201 160MHz
   Adresse physique . . . . . . . . . . . : 3C-58-C2-9D-98-38
   DHCP activé. . . . . . . . . . . . . . : Non
   Configuration automatique activée. . . : Oui
   Adresse IPv6 de liaison locale. . . . .: fe80::a82e:ad3d:ec8:2775%8(préféré)
   Adresse IPv4. . . . . . . . . . . . . .: 10.33.0.1(préféré)
   Masque de sous-réseau. . . . . . . . . : 255.255.252.0
   Passerelle par défaut. . . . . . . . . : 10.33.3.253
   IAID DHCPv6 . . . . . . . . . . . : 322721986
   DUID de client DHCPv6. . . . . . . . : 00-01-00-01-26-99-48-CE-B0-25-AA-39-5C-26
   Serveurs DNS. . .  . . . . . . . . . . : 1.1.1.1
                                       8.8.8.8
   NetBIOS sur Tcpip. . . . . . . . . . . : Activé
[...]
PS C:\Users\DIRECTEUR_PC2> ping 1.1.1.1

Envoi d’une requête 'Ping'  1.1.1.1 avec 32 octets de données :
Réponse de 1.1.1.1 : octets=32 temps=17 ms TTL=58
Réponse de 1.1.1.1 : octets=32 temps=17 ms TTL=58
Réponse de 1.1.1.1 : octets=32 temps=17 ms TTL=58
Réponse de 1.1.1.1 : octets=32 temps=17 ms TTL=58

Statistiques Ping pour 1.1.1.1:
    Paquets : envoyés = 4, reçus = 4, perdus = 0 (perte 0%),
Durée approximative des boucles en millisecondes :
    Minimum = 17ms, Maximum = 17ms, Moyenne = 17ms
```
On voit que l'adresse IP a bien été modifiée(Adresse IPv4) et que le DHCP est désactivé. On à toujours accès à internet (ping 1.1.1.1).

## II. Exploration locale en duo

### 1. Modification d'adresse IP

Configuration des machines :
Le premier aura 192.168.0.1 et le 2ème 192.168.0.2.
![](https://i.imgur.com/ods44w3.png)

Les changements ont bien pris effet :
```
PS C:\Users\DIRECTEUR_PC2> ipconfig

Configuration IP de Windows
[...]
Carte Ethernet Ethernet :

   Suffixe DNS propre à la connexion. . . :
   Adresse IPv6 de liaison locale. . . . .: fe80::f166:4347:db54:1052%10
   Adresse IPv4. . . . . . . . . . . . . .: 192.168.0.1
   Masque de sous-réseau. . . . . . . . . : 255.255.255.252
   Passerelle par défaut. . . . . . . . . :
[...]
```

Ping de la 2ème machine :
```
PS C:\Users\DIRECTEUR_PC2> ping 192.168.0.2

Envoi d’une requête 'Ping'  192.168.0.2 avec 32 octets de données :
Réponse de 192.168.0.2 : octets=32 temps=1 ms TTL=128
Réponse de 192.168.0.2 : octets=32 temps=1 ms TTL=128
Réponse de 192.168.0.2 : octets=32 temps<1ms TTL=128
Réponse de 192.168.0.2 : octets=32 temps=2 ms TTL=128

Statistiques Ping pour 192.168.0.2:
    Paquets : envoyés = 4, reçus = 4, perdus = 0 (perte 0%),
Durée approximative des boucles en millisecondes :
    Minimum = 0ms, Maximum = 2ms, Moyenne = 1ms
```
### 2. Utilisation d'un des deux comme gateway

Depuis la 2ème machine :

Ping 8.8.8.8 ->
```
PS C:\Users\nicol> ping 8.8.8.8

Envoi d’une requête 'Ping'  8.8.8.8 avec 32 octets de données :
Réponse de 8.8.8.8 : octets=32 temps=25 ms TTL=114
Réponse de 8.8.8.8 : octets=32 temps=34 ms TTL=114

Statistiques Ping pour 8.8.8.8:
    Paquets : envoyés = 2, reçus = 2, perdus = 0 (perte 0%),
Durée approximative des boucles en millisecondes :
    Minimum = 25ms, Maximum = 34ms, Moyenne = 29ms
```

tracert vers www.google.com ->
```
PS C:\Users\nicol> tracert www.google.com

Détermination de l’itinéraire vers www.google.com [142.250.179.68]
avec un maximum de 30 sauts :

  1     3 ms     2 ms     2 ms  DIRECTEUR-PC2 [192.168.0.1]
  2     *        *        *     Délai d’attente de la demande dépassé.
  3     4 ms     5 ms     4 ms  10.33.3.253
  4     5 ms     6 ms     7 ms  10.33.10.254
  5     4 ms     3 ms     4 ms  reverse.completel.net [92.103.174.137]
  6    11 ms     9 ms     8 ms  92.103.120.182
  7    21 ms    19 ms    21 ms  172.19.130.113
  8    19 ms    19 ms    19 ms  46.218.128.78
  9    21 ms    21 ms    21 ms  186.144.6.194.rev.sfr.net [194.6.144.186]
 10    22 ms    21 ms    22 ms  186.144.6.194.rev.sfr.net [194.6.144.186]
 11    22 ms    22 ms    23 ms  72.14.194.30
 12    23 ms    22 ms    22 ms  108.170.231.111
 13    22 ms    21 ms    21 ms  142.251.49.133
 14    21 ms    21 ms    21 ms  par21s19-in-f4.1e100.net [142.250.179.68]

Itinéraire déterminé.
```

### 3. Petit chat privé

Serveur :
```
PS C:\Users\DIRECTEUR_PC2\Desktop\Ynov> .\nc.exe -l -p 8888
Salut !
Hola ! Ca va ?
Super et toi ?
Je sais pas mettre de GIF dans ce truc... Donc ca va pas !
gifdechat.gif
=(
```

Client :
```
PS C:\Users\nicol\Downloads> .\nc.exe 192.168.0.1 8888
Salut !
[...]
```
Si on veut préciser sur quelle ip écouter (en mode serveur) : `.\nc.exe -l -p 8888 192.168.0.2`

### 4. Firewall

Pour activer les ping, il faut autoriser les règles `File and Printer Sharing (Echo Request - ICMPv4-In)` dans le pare feu.
Pour NETCAT, il faut ajouter une règle avec le programme et ajouter les ports voulus.

![](https://i.imgur.com/xy1TLTH.png)

![](https://i.imgur.com/A8WW3Kt.png)

## III. Manipulations d'autres outils/protocoles côté client

### 1. DHCP
```
PS C:\Users\DIRECTEUR_PC2> ipconfig /all
[...]

Carte réseau sans fil Wi-Fi :

   Suffixe DNS propre à la connexion. . . : auvence.co
   Description. . . . . . . . . . . . . . : Intel(R) Wi-Fi 6 AX201 160MHz
   Adresse physique . . . . . . . . . . . : 3C-58-C2-9D-98-38
   DHCP activé. . . . . . . . . . . . . . : Oui
   Configuration automatique activée. . . : Oui
   Adresse IPv6 de liaison locale. . . . .: fe80::a82e:ad3d:ec8:2775%8(préféré)
   Adresse IPv4. . . . . . . . . . . . . .: 10.33.3.80(préféré)
   Masque de sous-réseau. . . . . . . . . : 255.255.252.0
   Bail obtenu. . . . . . . . . . . . . . : jeudi 16 septembre 2021 09:50:01
   Bail expirant. . . . . . . . . . . . . : jeudi 16 septembre 2021 13:03:07
   Passerelle par défaut. . . . . . . . . : 10.33.3.253
   Serveur DHCP . . . . . . . . . . . . . : 10.33.3.254
   IAID DHCPv6 . . . . . . . . . . . : 322721986
   DUID de client DHCPv6. . . . . . . . : 00-01-00-01-26-99-48-CE-B0-25-AA-39-5C-26
   Serveurs DNS. . .  . . . . . . . . . . : 10.33.10.2
                                       10.33.10.148
                                       10.33.10.155
   NetBIOS sur Tcpip. . . . . . . . . . . : Activé
[...]
```
L'IP du DHCP est 10.33.3.254. Notre bail DHCP expirera le 16/09 à 13:03:07.

### 2. DNS

IP DNS:
```
PS C:\Users\DIRECTEUR_PC2> ipconfig /all
[...]

Carte réseau sans fil Wi-Fi :
   [...]
   Serveurs DNS. . .  . . . . . . . . . . : 10.33.10.2
                                       10.33.10.148
                                       10.33.10.155
[...]
```

On voit ici que le PC connait 3 serveurs DNS.

IP Google et Ynov :
```
PS C:\Users\DIRECTEUR_PC2> nslookup google.com
Serveur :   UnKnown
Address:  10.33.10.2

Réponse ne faisant pas autorité :
Nom :    google.com
Addresses:  2a00:1450:4007:815::200e
          142.250.179.78

PS C:\Users\DIRECTEUR_PC2> nslookup ynov.com
Serveur :   UnKnown
Address:  10.33.10.2

Réponse ne faisant pas autorité :
Nom :    ynov.com
Address:  92.243.16.143
```

Ici, l'IP de www.google.com est 142.250.179.78 et celle d'www.ynov.com est 92.243.16.143.

On peut savoir que l'adresse 10.33.10.2 est une machine d'ynov (adresse locale), que c'est le DNS. On peut savoir qu'elle exécute des services windows (kpasswd5, microsoft-ds, msrpc...). Cela doit surement être un windows server.

Liste des ports ouverts permettant de déduire quelle est la machine :

```
PS C:\Users\DIRECTEUR_PC2> nmap 10.33.10.2
Starting Nmap 7.92 ( https://nmap.org ) at 2021-09-16 11:41 Paris, Madrid (heure dÆÚtÚ)
Nmap scan report for 10.33.10.2
Host is up (0.0073s latency).
Not shown: 988 closed tcp ports (reset)
PORT     STATE SERVICE
53/tcp   open  domain
88/tcp   open  kerberos-sec
135/tcp  open  msrpc
139/tcp  open  netbios-ssn
389/tcp  open  ldap
445/tcp  open  microsoft-ds
464/tcp  open  kpasswd5
593/tcp  open  http-rpc-epmap
636/tcp  open  ldapssl
3268/tcp open  globalcatLDAP
3269/tcp open  globalcatLDAPssl
3389/tcp open  ms-wbt-server

Nmap done: 1 IP address (1 host up) scanned in 1.41 seconds
```

On sait aussi qu'un service ssh est installé (il y a une réponse) :
```
PS C:\Users\DIRECTEUR_PC2> ssh admin@10.33.10.2
ssh: connect to host 10.33.10.2 port 22: Connection refused
```

Reverse lookup :
```
PS C:\Users\DIRECTEUR_PC2> nslookup 78.74.21.21
Serveur :   UnKnown
Address:  10.33.10.2

Nom :    host-78-74-21-21.homerun.telia.com
Address:  78.74.21.21

PS C:\Users\DIRECTEUR_PC2> nslookup 92.146.54.88
Serveur :   UnKnown
Address:  10.33.10.2

Nom :    apoitiers-654-1-167-88.w92-146.abo.wanadoo.fr
Address:  92.146.54.88
```

Ces adresses sont surement des routeurs et appartiennent a des companies de télécommunication.
https://www.ip-tracker.org/lookup.php?ip=apoitiers-654-1-167-88.w92-146.abo.wanadoo.fr
https://www.ip-tracker.org/lookup.php?ip=host-78-74-21-21.homerun.telia.com

## IV. Wireshark

Paquets du ping avec la passerelle (trafic autre effacé) :
```
1	0.000000	10.33.3.80	10.33.3.253	ICMP	74	Echo (ping) request  id=0x0100, seq=2569/2314, ttl=128 (reply in 2)
2	0.002218	10.33.3.253	10.33.3.80	ICMP	74	Echo (ping) reply    id=0x0100, seq=2569/2314, ttl=255 (request in 1)
[...]
6	1.015338	10.33.3.80	10.33.3.253	ICMP	74	Echo (ping) request  id=0x0100, seq=2570/2570, ttl=128 (reply in 7)
7	1.018378	10.33.3.253	10.33.3.80	ICMP	74	Echo (ping) reply    id=0x0100, seq=2570/2570, ttl=255 (request in 6)
[...]
16	2.021918	10.33.3.80	10.33.3.253	ICMP	74	Echo (ping) request  id=0x0100, seq=2571/2826, ttl=128 (reply in 17)
17	2.024686	10.33.3.253	10.33.3.80	ICMP	74	Echo (ping) reply    id=0x0100, seq=2571/2826, ttl=255 (request in 16)
[...]
```

Paquets du NETCAT avec le 2ème PC en Ethernet :
```
1	0.000000	192.168.0.2	192.168.0.3	UDP	305	54915 → 54915 Len=263
2	0.055079	192.168.0.1	192.168.0.3	UDP	305	54915 → 54915 Len=263
[...]
15	1.782343	192.168.0.2	192.168.0.1	TCP	62	1054 → 8888 [SYN] Seq=0 Win=64240 Len=0 MSS=1460 SACK_PERM=1
16	1.782465	192.168.0.1	192.168.0.2	TCP	62	8888 → 1054 [SYN, ACK] Seq=0 Ack=1 Win=64240 Len=0 MSS=1460 SACK_PERM=1
17	1.785194	192.168.0.2	192.168.0.1	TCP	60	1054 → 8888 [ACK] Seq=1 Ack=1 Win=64240 Len=0
[...]
24	2.342132	192.168.0.1	192.168.0.2	TCP	59	8888 → 1054 [PSH, ACK] Seq=1 Ack=1 Win=64240 Len=5
25	2.396929	192.168.0.2	192.168.0.1	TCP	60	1054 → 8888 [ACK] Seq=1 Ack=6 Win=64235 Len=0
[...]
30	4.607085	192.168.0.1	192.168.0.2	TCP	54	8888 → 1054 [RST, ACK] Seq=6 Ack=1 Win=0 Len=0
```
Si on regarde le paquet 24, on voit qu'il contient notre message ! On peut le trouver en regardans sa taille (ici 5).

![](https://i.imgur.com/YtUhyAq.png)
