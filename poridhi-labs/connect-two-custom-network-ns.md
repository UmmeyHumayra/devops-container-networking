## Packages to install
```
#sudo apt update
#sudo apt upgrade -y
#sudo apt install iproute2
#sudo apt install net-tools
```
## Enable IP forwarding in the Linux kernel
```
# sudo sysctl -w net.ipv4.ip_forward=1
```
## Create and verify namespaces
```
# sudo ip netns add blue-namespace
# sudo ip netns add lemon-namespace
# sudo ip netns list
```
## Create the virtual ethernet link pair
```
# sudo ip link add veth-blue type veth peer name veth-lemon
```

## Set the both ends of the cable as NIC to the respective network namespaces 
```
# sudo ip link set veth-blue netns blue-namespace
# sudo ip link set veth-lemon netns lemon-namespace
```
## Assign IP addresses to the interfaces and turn interfaces up.
```
# sudo ip netns exec blue-namespace ip addr add 192.168.0.1/24 dev veth-blue
# sudo ip netns exec lemon-namespace ip addr add 192.168.0.2/24 dev veth-lemon

# sudo ip netns exec blue-namespace ip link set veth-blue up
# sudo ip netns exec lemon-namespace ip link set veth-lemon up
```
At this point ping from one namespace to other should be successful since the NICs are directly paired up and are on the same network in a simple setup. In a complex set up, there might be use cases where, we may need to add route to the respective network namespaces in order for the packets to successfully flow from source to destination. 

## Set defaul routes in namespaces
```
# sudo ip netns exec blue-namespace ip route add default via 192.168.0.1
# sudo ip netns exec lemon-namespace ip route add default via 192.168.0.2
```
## Now test connection using ping
```
#  sudo ip netns exec blue-namespace ping 192.168.0.2 -c 3
# sudo ip netns exec lemon-namespace ping 192.168.0.1 -c 3
```
Furthermore, the `arp` command in the context of the `ip netns exec` allows to view the ARP cache of a specific network namespace. The ARP cache contains mappings of IP addresses to MAC addresses. 
```
# sudo ip netns exec blue-namespace arp
# sudo ip netns exec lemon-namespace arp
```