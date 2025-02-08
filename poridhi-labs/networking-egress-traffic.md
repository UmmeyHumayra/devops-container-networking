### Create a network namespace red-ns and a bridge br0
```
# sudo ip netns add red-ns
# sudo ip link add br0 type bridge
```

### Bring up the bridge interface to "UP" status and assign an IP address 192.168.0.1/16.
```
# sudo ip link set br0 up
# sudo ip addr add 192.168.0.1/16 dev br0
```

### Check and verify the bridge status and ip address
```
# sudo ip link list
# ip addr show dev br0
```

### Create a virtual ethernet cable with veth0 and ceth0 virtual interfaces at both end. 
```
# sudo ip link add veth0 type veth peer name ceth0
```
```
# ip link list
                               << omitted output >>

6: br0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/ether ce:1d:18:7a:12:88 brd ff:ff:ff:ff:ff:ff
7: ceth0@veth0: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 06:2c:ed:25:5c:d0 brd ff:ff:ff:ff:ff:ff
8: veth0@ceth0: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 46:70:39:ee:3b:70 brd ff:ff:ff:ff:ff:ff
```
### Newly created virtual ethernet interfaces are to be connected with bridge at one end and with the red-ns namespace on the other end. 
**veth0** is to be set with **br0** and `ceth0` is to be set with `red-ns` namespace.
```
# sudo ip link set veth0 master br0
# sudo ip link set ceth0 netns red-ns
```
Check and confirm
```
# sudo ip link list
                               << omitted output >>
8: veth0@if7: <BROADCAST,MULTICAST> mtu 1500 qdisc noop master br0 state DOWN mode DEFAULT group default qlen 1000
    link/ether 46:70:39:ee:3b:70 brd ff:ff:ff:ff:ff:ff link-netns red-ns
```
```
# sudo ip netns exec red-ns ip link list
1: lo: <LOOPBACK> mtu 65536 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
7: ceth0@if8: <BROADCAST,MULTICAST> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 06:2c:ed:25:5c:d0 brd ff:ff:ff:ff:ff:ff link-netnsid 0
```
### Bring veth0 and ceth0 into "UP" status
```
# sudo ip link set veth0 up
# sudo ip netns exec red-ns ip link set ceth0 up
```
### Set IP address on the ceth0 interface of red-ns and then confirm.
```
# sudo ip netns exec red-ns ip addr add 192.168.0.2/16 dev ceth0
```
```
# sudo ip netns exec red-ns ip addr show dev ceth0
7: ceth0@if8: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 06:2c:ed:25:5c:d0 brd ff:ff:ff:ff:ff:ff link-netnsid 0
    inet 192.168.0.2/16 scope global ceth0
       valid_lft forever preferred_lft forever
    inet6 fe80::42c:edff:fe25:5cd0/64 scope link 
       valid_lft forever preferred_lft forever
```
### Check if br0 IP can be pinged from red-ns ceth0. Ping should be successful.
```
# sudo ip netns exec red-ns ping 192.168.0.1 -c 3
PING 192.168.0.1 (192.168.0.1) 56(84) bytes of data.
64 bytes from 192.168.0.1: icmp_seq=1 ttl=64 time=0.168 ms
64 bytes from 192.168.0.1: icmp_seq=2 ttl=64 time=0.100 ms
64 bytes from 192.168.0.1: icmp_seq=3 ttl=64 time=0.101 ms

--- 192.168.0.1 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2039ms
rtt min/avg/max/mdev = 0.100/0.123/0.168/0.031 ms
```

root@1723f892e3b2c1b0:~/code# ip addr show dev eth0
4: eth0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc pfifo_fast state UP group default qlen 1000
    link/ether 8a:e1:47:2c:3c:94 brd ff:ff:ff:ff:ff:ff
    inet 10.62.15.42/16 brd 10.62.255.255 scope global eth0
       valid_lft forever preferred_lft forever
    inet6 fe80::88e1:47ff:fe2c:3c94/64 scope link 
       valid_lft forever preferred_lft forever





root@1723f892e3b2c1b0:~/code# sudo ip netns exec red-ns ping 10.62.15.42 -c 3
ping: connect: Network is unreachable
root@1723f892e3b2c1b0:~/code# sudo ip netns exec red-ns route
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
192.168.0.0     0.0.0.0         255.255.0.0     U     0      0        0 ceth0
root@1723f892e3b2c1b0:~/code# sudo ip netns exec ip route add default via 192.168.0.1
Cannot open network namespace "ip": No such file or directory
root@1723f892e3b2c1b0:~/code# sudo ip netns exec route add default via 192.168.0.1
Cannot open network namespace "route": No such file or directory
root@1723f892e3b2c1b0:~/code# sudo ip netns exec red-ns ip route add default via 192.168.0.1
root@1723f892e3b2c1b0:~/code# sudo ip netns exec red-ns route
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
default         192.168.0.1     0.0.0.0         UG    0      0        0 ceth0
192.168.0.0     0.0.0.0         255.255.0.0     U     0      0        0 ceth0
root@1723f892e3b2c1b0:~/code# sudo ip netns exec red-ns ping 10.62.15.42 -c 3
PING 10.62.15.42 (10.62.15.42) 56(84) bytes of data.
64 bytes from 10.62.15.42: icmp_seq=1 ttl=64 time=0.100 ms
64 bytes from 10.62.15.42: icmp_seq=2 ttl=64 time=0.105 ms
64 bytes from 10.62.15.42: icmp_seq=3 ttl=64 time=0.104 ms

--- 10.62.15.42 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2048ms
rtt min/avg/max/mdev = 0.100/0.103/0.105/0.002 ms
root@1723f892e3b2c1b0:~/code# 



root@1723f892e3b2c1b0:~/code# sudo iptables -t nat -L -n -v
Chain PREROUTING (policy ACCEPT 136 packets, 8300 bytes)
 pkts bytes target     prot opt in     out     source               destination         
  133  8048 DOCKER     all  --  *      *       0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL

Chain INPUT (policy ACCEPT 131 packets, 7908 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 306 packets, 19560 bytes)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 DOCKER     all  --  *      *       0.0.0.0/0           !127.0.0.0/8          ADDRTYPE match dst-type LOCAL

Chain POSTROUTING (policy ACCEPT 306 packets, 19560 bytes)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 MASQUERADE  all  --  *      !docker0  172.17.0.0/16        0.0.0.0/0           

Chain DOCKER (2 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 RETURN     all  --  docker0 *       0.0.0.0/0            0.0.0.0/0           
root@1723f892e3b2c1b0:~/code# sudo iptables -t nat -A POSTROUTING -s 192.168.0.0/16 -j MASQUERADE
root@1723f892e3b2c1b0:~/code# sudo ip netns exec red-ns ping 8.8.8.8 -c 3
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.

--- 8.8.8.8 ping statistics ---
3 packets transmitted, 0 received, 100% packet loss, time 2031ms

root@1723f892e3b2c1b0:~/code# 


root@1723f892e3b2c1b0:~/code# sudo ip netns exec red-ns ping 8.8.8.8 -c 3
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.

--- 8.8.8.8 ping statistics ---
3 packets transmitted, 0 received, 100% packet loss, time 2031ms

root@1723f892e3b2c1b0:~/code# sudo iptables --append FORWARD --in-interface br0 -jump ACCEPT
Bad argument `ACCEPT'
Try `iptables -h' or 'iptables --help' for more information.
root@1723f892e3b2c1b0:~/code# sudo iptables --append FORWARD --in-interface br0 --jump ACCEPT
root@1723f892e3b2c1b0:~/code# sudo iptables --append FORWARD --out-interface br0 --jump ACCEPT
root@1723f892e3b2c1b0:~/code# sudo ip netns exec red-ns ping 8.8.8.8 -c 3
PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
64 bytes from 8.8.8.8: icmp_seq=1 ttl=54 time=43.1 ms
64 bytes from 8.8.8.8: icmp_seq=2 ttl=54 time=43.0 ms
64 bytes from 8.8.8.8: icmp_seq=3 ttl=54 time=43.0 ms

--- 8.8.8.8 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 2003ms
rtt min/avg/max/mdev = 42.976/43.010/43.074/0.044 ms
root@1723f892e3b2c1b0:~/code# 


root@1723f892e3b2c1b0:~/code# sudo iptables -t nat -L -n -v
Chain PREROUTING (policy ACCEPT 4 packets, 336 bytes)
 pkts bytes target     prot opt in     out     source               destination         
  133  8048 DOCKER     all  --  *      *       0.0.0.0/0            0.0.0.0/0            ADDRTYPE match dst-type LOCAL

Chain INPUT (policy ACCEPT 0 packets, 0 bytes)
 pkts bytes target     prot opt in     out     source               destination         

Chain OUTPUT (policy ACCEPT 6 packets, 384 bytes)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 DOCKER     all  --  *      *       0.0.0.0/0           !127.0.0.0/8          ADDRTYPE match dst-type LOCAL

Chain POSTROUTING (policy ACCEPT 6 packets, 384 bytes)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 MASQUERADE  all  --  *      !docker0  172.17.0.0/16        0.0.0.0/0           
    1    84 MASQUERADE  all  --  *      *       192.168.0.0/16       0.0.0.0/0           

Chain DOCKER (2 references)
 pkts bytes target     prot opt in     out     source               destination         
    0     0 RETURN     all  --  docker0 *       0.0.0.0/0            0.0.0.0/0           
root@1723f892e3b2c1b0:~/code# 