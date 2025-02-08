## Prerequisites - update and upgrade packages, also install iproute2 and net-tools

```
# sudo apt update
# sudo apt upgrade -y
# sudo apt install iproute2
# sudo apt instal net-tools
```
## Create a Linux bridge v-net
```
# sudo ip link add v-net type bridge
```
## Assign IP 10.0.0.1/24 to the bridge and turn it up
```
# sudo ip link set v-net up
# sudo ip addr add 10.0.0.1/24 dev v-net
```
check and confirm
```
# sudo ip link list
# sudo ip addr show dev v-net
```
## Create three network namespaces - blue, gray and lime
```
# sudo ip netns add blue
# sudo ip netns add gray
# sudo ip netns add lime
# sudo ip netns list
```
## Create virtual ethernet pairs 
veth-blue < -------- > veth-blue-br, 
veth-gray < -------- > veth-gray-br, 
veth-lime < -------- > veth-lime-br
```
# sudo ip link add veth-blue type veth peer name veth-blue-br
# sudo ip link add veth-gray type veth peer name veth-gray-br
# sudo ip link add veth-lime type veth peer name veth-lime-br
# sudo ip link list
```
## Move each end of the veth cable to a different namespace
```
# sudo ip link set veth-blue netns blue
# sudo ip link set veth-gray netns gray
# sudo ip link set veth-lime netns lime
```
Check and confirm
```
# sudo ip link list
# sudo ip netns exec blue ip link list
# sudo ip netns exec gray ip link list
# sudo ip netns exec lime ip link list
```
## Add the other end of the virtual interfaces to the bridge
```
# sudo ip link set veth-blue-br master v-net
# sudo ip link set veth-gray-br master v-net
# sudo ip link set veth-lime-br master v-net
```
## Set the bridge interfaces up and confirm
```
# sudo ip link set veth-blue-br up
# sudo ip link set veth-gray-br up
# sudo ip link set veth-lime-br up
# sudo ip link list
```
## Set the namespace interfaces up
```
# sudo ip netns exec blue ip link set veth-blue up
# sudo ip netns exec gray ip link set veth-gray up
# sudo ip netns exec lime ip link set veth-lime up
```
Check and confirm
```
# sudo ip netns exec blue ip link list
# sudo ip netns exec gray ip link list
# sudo ip netns exec lime ip link list
```
## Assign IP addresses to the virtual interfaces within each namespace
veth-blue --> 10.0.0.11/24, 
veth-gray --> 10.0.0.21/24, 
veth-lime --> 10.0.0.31/24
```
# sudo ip netns exec blue ip addr add 10.0.0.11/24 dev veth-blue
# sudo ip netns exec gray ip addr add 10.0.0.21/24 dev veth-gray
# sudo ip netns exec lime ip addr add 10.0.0.31/24 dev veth-lime
```
Check and confirm
```
# sudo ip netns exec blue ip addr show
# sudo ip netns exec gray ip addr show
# sudo ip netns exec lime ip addr show
```
## Set the default route in each network namespace
```
# sudo ip netns exec blue ip route add default via 10.0.0.1
# sudo ip netns exec gray ip route add default via 10.0.0.1
# sudo ip netns exec lime ip route add default via 10.0.0.1
```
check and confirm
```
# sudo ip netns exec blue route
# sudo ip netns exec gray route
# sudo ip netns exec lime route
```
## Add firewall rules in the root namespace
These rules enabled traffic to travel across the v-net virtual bridge.These are useful to allow all traffic to pass through the v-net interface without any restrictions.However, keep in mind that using such rules without any filtering can expose your system to potential security risks.
```
# sudo iptables --append FORWARD --in-interface v-net --jump ACCEPT
# sudo iptables --append FORWARD --out-interface v-net --jump ACCEPT
```
## Test connectivity with ping command
```
# sudo ip netns exec blue ping 10.0.0.21 -c 3
# sudo ip netns exec blue ping 10.0.0.31 -c 3
```
```
# sudo ip netns exec gray ping 10.0.0.11 -c 3
# sudo ip netns exec gray ping 10.0.0.31 -c 3
```
```
# sudo ip netns exec lime ping 10.0.0.11 -c 3
# sudo ip netns exec lime ping 10.0.0.21 -c 3
```
## Clean up (Optional)
```
# sudo ip netns del blue
# sudo ip netns del gray
# sudo ip netns del lime

# sudo ip link delete v-net type bridge
```