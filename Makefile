# This is the makefile that creates multiple network namespaces and connect them using bridges and routing. 

# Variables for IP Addresses
NS1_IP = 192.168.1.2
NS2_IP = 192.168.2.2
ROUTER_NS1_IP = 192.168.1.1
ROUTER_NS2_IP = 192.168.2.1
NETMASK = 24

all: system_prerequisits create_net_br create_ns create_vifs_conn config_ips setup_routing iptables_rule iptables_rules ping

system_prerequisits:
	sudo apt update && sudo apt upgrade -y
	sudo apt install iproute2 net-tools tcpdump -y

create:
	# network bridges
	sudo ip link add br1 type bridge
	sudo ip link add br2 type bridge
	sudo ip link set br1 up
	sudo ip link set br2 up
	# Namespaces
	sudo ip netns add ns1
	sudo ip netns add ns2
	sudo ip netns add router-ns
	sudo ip netns list
	# Virtual Interfaces and Connections
	sudo ip link add v-ns1-ns type veth peer name v-ns1
	sudo ip link add vr-ns1-ns type veth peer name vr-ns1
	sudo ip link add v-ns2-ns type veth peer name v-ns2
	sudo ip link add vr-ns2-ns type veth peer name vr-ns2
	sudo ip link set v-ns1-ns netns ns1
	sudo ip link set v-ns2-ns netns ns2
	sudo ip link set vr-ns1-ns netns router-ns
	sudo ip link set vr-ns2-ns netns router-ns
	sudo ip link set v-ns1 master br1
	sudo ip link set vr-ns1 master br1
	sudo ip link set v-ns2 master br2
	sudo ip link set vr-ns2 master br2
	sudo ip link set v-ns1 up
	sudo ip link set vr-ns1 up
	sudo ip link set v-ns2 up
	sudo ip link set vr-ns2 up

config_ips:
	sudo ip netns exec ns1 ip link set v-ns1-ns up
	sudo ip netns exec ns1 ip addr add $(NS1_IP)/$(NETMASK) dev v-ns1-ns
	sudo ip netns exec ns2 ip link set v-ns2-ns up
	sudo ip netns exec ns2 ip addr add $(NS2_IP)/$(NETMASK) dev v-ns2-ns
	sudo ip netns exec router-ns ip link set vr-ns1-ns up
	sudo ip netns exec router-ns ip addr add $(ROUTER_NS1_IP)/$(NETMASK) dev vr-ns1-ns
	sudo ip netns exec router-ns ip link set vr-ns2-ns up
	sudo ip netns exec router-ns ip addr add $(ROUTER_NS2_IP)/$(NETMASK) dev vr-ns2-ns

setup_routing:
	sudo ip netns exec ns1 ip route add default via $(ROUTER_NS1_IP)
	sudo ip netns exec ns2 ip route add default via $(ROUTER_NS2_IP)
	sudo sysctl -w net.ipv4.ip_forward=1

iptables_rules: # these FW rules may or may not be needed, depends on the FW rules in the linux system
	sudo iptables --append FORWARD --in-interface br1 --jump ACCEPT
	sudo iptables --append FORWARD --out-interface br1 --jump ACCEPT
	sudo iptables --append FORWARD --in-interface br2 --jump ACCEPT
	sudo iptables --append FORWARD --out-interface br2 --jump ACCEPT

ping: 
	sudo ip netns exec ns1 ping $(ROUTER_NS1_IP) -c 2
	sudo ip netns exec ns2 ping $(ROUTER_NS2_IP) -c 2
	sudo ip netns exec router-ns ping $(NS1_IP) -c 2
	sudo ip netns exec router-ns ping $(NS2_IP) -c 2

clean:
	sudo ip netns del ns1
	sudo ip netns del ns2
	sudo ip netns del router-ns
	sudo ip link del br1
	sudo ip link del br2
