# TP4 : Vers un réseau d'entreprise

## I. Dumb switch
### Setup topologie 1

On définit les ip sur les 2 VPCS :
```
PC1> ip 10.1.1.1 255.255.255.0
Checking for duplicate address...
PC2> ip 10.1.1.2 255.255.255.0
Checking for duplicate address...
```
On ping le n°2 depuis le n°1 :
```
PC1> ping 10.1.1.2 -c 4

84 bytes from 10.1.1.2 icmp_seq=1 ttl=64 time=3.062 ms
84 bytes from 10.1.1.2 icmp_seq=2 ttl=64 time=1.409 ms
84 bytes from 10.1.1.2 icmp_seq=3 ttl=64 time=2.783 ms
84 bytes from 10.1.1.2 icmp_seq=4 ttl=64 time=3.513 ms
```
## II. VLAN
### Setup topologie 2

On ajoute la nouvelle ip sur le VPCS 3 et on vérifie les pings :
```
PC3> ip 10.1.1.3 255.255.255.0
Checking for duplicate address...
PC3> ping 10.1.1.1 -c 2
84 bytes from 10.1.1.1 icmp_seq=1 ttl=64 time=3.648 ms
84 bytes from 10.1.1.1 icmp_seq=2 ttl=64 time=4.790 ms
PC3> ping 10.1.1.2 -c 2
84 bytes from 10.1.1.2 icmp_seq=1 ttl=64 time=6.255 ms
84 bytes from 10.1.1.2 icmp_seq=2 ttl=64 time=6.223 ms
```

On configure les vlan sur le switch :
```
Switch>enable
Switch#conf t
Enter configuration commands, one per line.  End with CNTL/Z.
Switch(config)#vlan 10
Switch(config-vlan)#name left
Switch(config-vlan)#exit
Switch(config)#vlan 20
Switch(config-vlan)#name right
Switch(config-vlan)#exit
Switch(config)# interface Gi0/1
Switch(config-if)# switchport mode access
Switch(config-if)# switchport access vlan 10
Switch(config-if)# exit
Switch(config)# interface Gi0/2
Switch(config-if)# switchport mode access
Switch(config-if)# switchport access vlan 10
Switch(config-if)# exit
Switch(config)# interface Gi0/3
Switch(config-if)# switchport mode access
Switch(config-if)# switchport access vlan 20
Switch(config-if)# exit
```

On enregistre : `Switch>copy running-config startup-config`

On teste les pings :
```
PC1> ping 10.1.1.3 -c 2
host (10.1.1.3) not reachable
PC1> ping 10.1.1.2 -c 2
84 bytes from 10.1.1.2 icmp_seq=1 ttl=64 time=4.712 ms
84 bytes from 10.1.1.2 icmp_seq=2 ttl=64 time=1.857 ms
PC3> ping 10.1.1.2 -c 2
host (10.1.1.2) not reachable
```

## III. Routing

### Setup topologie 3

On ajoute les ip sur les VPCS de la même facon que dans la partie 2 en rajoutant la gateway.

Puis on configure les vlan sur le switch :
```
Switch(config)#vlan 11
Switch(config-vlan)#name clients
Switch(config-vlan)#exit
Switch(config)#vlan 12
Switch(config-vlan)#name servers
Switch(config-vlan)#exit
Switch(config)#vlan 13
Switch(config-vlan)#name routers
Switch(config-vlan)#exit
Switch(config)#exit
Switch(config)#interface Gi0/0
Switch(config-if)#switchport trunk encapsulation dot1q
Switch(config-if)#switchport mode trunk
Switch(config-if)#switchport trunk allowed vlan add 11,12,13
Switch(config-if)#exit
Switch(config)#interface Gi0/1
Switch(config-if)#switchport mode access
Switch(config-if)#switchport access vlan 11
Switch(config-if)#exit

// Et on fait pareil avec les autres pc et serveurs.
```

On configure le routeur pour chaque vlan :
```
R1(config)#interface FastEthernet0/0.11
R1(config-subif)#encapsulation dot1Q 11
R1(config-subif)#ip addr 10.1.1.254 255.255.255.0
R1(config-subif)#exit

// Et on le fait pour les 2 vlan restants.
```

Les routes par défaut sont ajoutées sur les VPCS et la VM.
Le routeur fonctionne, on peut ping le vlan client depuis admin...
```
adm1> ping 10.1.1.1 -c4
84 bytes from 10.1.1.1 icmp_seq=1 ttl=63 time=30.339 ms
84 bytes from 10.1.1.1 icmp_seq=2 ttl=63 time=21.085 ms
84 bytes from 10.1.1.1 icmp_seq=3 ttl=63 time=20.437 ms
84 bytes from 10.1.1.1 icmp_seq=4 ttl=63 time=21.463 ms
84 bytes from 10.1.1.1 icmp_seq=5 ttl=63 time=22.987 ms
```

## IV. NAT

### Setup topologie 4

On conencte le cloud sur GNS3 et on configure le DHCP sur le routeur :
```
R1#conf t
R1(config)#int FastEthernet 1/0
R1(config-if)#ip address dhcp
R1(config-if)#no shut
R1(config-if)#exit
R1(config)#exit
```

On peut maintenant ping `1.1.1.1` depuis un VPCS ou depuis la VM.
```
PC1> ping 1.1.1.1
1.1.1.1 icmp_seq=1 timeout
1.1.1.1 icmp_seq=2 timeout
84 bytes from 1.1.1.1 icmp_seq=3 ttl=127 time=46.047 ms
84 bytes from 1.1.1.1 icmp_seq=4 ttl=127 time=39.678 ms
84 bytes from 1.1.1.1 icmp_seq=5 ttl=127 time=44.053 ms
```

On configure le dns dans les VPCS et dans la VM :

`PC1> ip dns 1.1.1.1` pour le VPCS

Et on rajoute `nameserver 1.1.1.1` dans `/etc/resolv.conf` pour la vm.

On peut maintenant ping `google.com` :
```
PC1> ping google.com
google.com resolved to 172.217.18.206

84 bytes from 172.217.18.206 icmp_seq=1 ttl=127 time=40.702 ms
84 bytes from 172.217.18.206 icmp_seq=2 ttl=127 time=41.415 ms
84 bytes from 172.217.18.206 icmp_seq=3 ttl=127 time=55.571 ms
84 bytes from 172.217.18.206 icmp_seq=4 ttl=127 time=46.830 ms
84 bytes from 172.217.18.206 icmp_seq=5 ttl=127 time=41.274 ms
```
