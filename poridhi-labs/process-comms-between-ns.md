## Create blue-namespace and lemon-namespace
```
# sudo ip netns add blue-namespace
# sudo ip netns add lemon-namespace
# sudo ip netns list
```
## Create virtual ethernet link pair veth-blue and veth-lemon
```
# sudo ip link add veth-blue type veth peer name veth-lemon
# sudo ip link list
```

```
                       <<<<< Output omitted >>>>>
6: veth-lemon@veth-blue: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether f2:82:73:6b:d4:3c brd ff:ff:ff:ff:ff:ff
7: veth-blue@veth-lemon: <BROADCAST,MULTICAST,M-DOWN> mtu 1500 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 0e:e5:54:c7:e0:3e brd ff:ff:ff:ff:ff:ff
```
## Add each end of the veth link pair to respective namespaces
```
# sudo ip link set veth-blue netns blue-namespace
# sudo ip link set veth-lemon netns lemon-namespace
```
```
# sudo ip netns exec blue-namespace ip link list
# sudo ip netns exec lemon-namespace ip link list
```
## Assign 192.168.0.1/24 to veth-blue and 192.168.0.2/24 to veth-lemon and turn them up
```
# sudo ip netns exec blue-namespace bash
# ip link set veth-blue up
# ip addr add 192.168.0.1/24 dev veth-blue

# ip link list
# ip addr show
```
```
# sudo ip netns exec lemon-namespace bash
# ip link set veth-lemon up
# ip addr add 192.168.0.2/24 dev veth-lemon

# ip link list
# ip addr show
```
## Now, one ns can ping the other ns successfully. However, we still want to set a default route in each ns. 
```
# sudo ip netns exec blue-namespace ip route add default via 192.168.0.1
# sudo ip netns exec lemon-namespace ip route add default via 192.168.0.2

# sudo ip netns exec blue-namespace route
# sudo ip netns exec lemon-namespace route
```
The connection between two namespaces has been established. Let's move to the second part of the objective. Run a process in one of the namespaces and then try to communicate with that process from the other namespace. 
## Create a server and run
We are going to deploy a web server using python that will display a simple "hello world" text when we do a curl to it from the other namespace. 
### Write a simple hello-world flast application and name the file `server.py`
```
############### server.py ###############

from flask import Flask

app = Flask(__name__)

@app.route('/')
def hello_world():
    return 'Hello, World!\n'

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3000, debug=True)
```
## To run this server wee need to create python virtual environment and install packages

```
# apt install python3.8-venv
# python3 -m venv venv
# source venv/bin/activate
# pip3 install flask
```
## Enter into one of the namespaces and run the python server. 
Let's pick blue-namespace to run the server. Check `ifconfig` command to confirm we are in the right namespace.
```
# sudo ip netns exec blue-namespace bash
# ifconfig

# source venv/bon/activate
# python3 server.py
```
## Let's curl to the python server from lemon-namespace
From another bash terminal run the commands
```
# sudo ip netns exec lemon-namesapce bash
# ifconfig

# curl -v "http://192.168.0.1:3000" 
```
A "200" HTTP response indicates curl is successful. Also the "Hello, World!" text is visible in the terminal that's in lemon-namespace.

## Let's create another server. 
```
from flask import Flask

app = Flask (__name__)

@app.route('/')

def hello_world2():
	return ("Hello, World!\n" "from Process 3!\n")

if __name__ == '__main__':
	app.run(host='0.0.0.0', port=3001, debug=True)

```


####################### All commands #####################

# sudo apt update
# sudo apt upgrade -y
# sudo apt install iproute2
# sudo apt install net-tools

# sudo sysctl -w net.ipv4.ip_forward=1

# sudo ip netns add blue-namespace
# sudo ip netns add lemon-namespace
# sudo ip link add veth-blue type veth peer name veth-lemon
# sudo ip link set veth-blue netns blue-namespace
# sudo ip link set veth-lemon netns lemon-namespace

# sudo ip netns exec blue-namespace bash
# ip link set veth-blue up
# ip addr add 192.168.0.1/24 dev veth-blue
# ip route add default via 192.168.0.1
# exit

# sudo ip netns exec lemon-namespace bash
# ip link set veth-lemon up
# ip addr add 192.168.0.2/24 dev veth-lemon
# ip route add default via 192.168.0.2
# exit

# sudo nano server1.py
################## server1.py ##################
from flask import Flask

app = Flask (__name__)

@app.route('/')

def hello_world():
    return ("Hello, World! \n")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3001, debug=True)
###################### END ######################

# sudo nano server2.py
################## server1.py ##################
from flask import Flask

app = Flask (__name__)

@app.route('/')

def hello_world():
    return ("Hello, World! \n" "reply from PROCESS 2.\n")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3002, debug=True)
###################### END ######################

# sudo nano server3.py
################## server1.py ##################
from flask import Flask

app = Flask (__name__)

@app.route('/')

def hello_world():
    return ("Hello, World! \n" "reply from PROCESS 3.\n")

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=3003, debug=True)
###################### END ######################


# apt install python3.8-venv
# python3 -m venv venv
# source venv/bin/activate
# pip3 install flask

# sudo ip netns exec blue-namespace bash
# source venv/bin/activate
# python3 server1.py

# sudo ip netns exec blue-namespace bash
# curl -v "http://192.168.0.1:3001"



###################### python program to get a reply from Google DNS #########

import subprocess
import platform

def ping(host):
    """
    Pings the specified host and returns the output.

    Args:
        host: The hostname or IP address to ping.

    Returns:
        A string containing the output of the ping command, or None if an error occurs.
        Returns an empty string if the host is unreachable.
    """

    try:
        param = '-n 1' if platform.system().lower() == 'windows' else '-c 1' # Count parameter
        command = ['ping', param, host]

        result = subprocess.run(command, capture_output=True, text=True, check=True)  # capture_output for output, text=True decodes

        return result.stdout  # Return the standard output

    except subprocess.CalledProcessError as e:
        # Handle ping failure (e.g., host unreachable)
        print(f"Ping failed: {e}")
        # Return empty string or handle it as you see fit
        return "" # Or return None, raise exception, etc.

    except FileNotFoundError:
        print("Ping command not found.  Is ping installed?")
        return None

    except Exception as e:
        print(f"An unexpected error occurred: {e}")
        return None



def check_ping_reply(ping_output):
    """
    Checks if the ping reply indicates a successful connection.

    Args:
        ping_output: The output of the ping command.

    Returns:
        True if the ping was successful, False otherwise.
    """
    if not ping_output:  # Check for empty string or None
        return False

    # Check for success messages (platform-dependent) - adapt as needed
    success_keywords = ["bytes from", "ttl=", "time="] # Common keywords
    for keyword in success_keywords:
       if keyword in ping_output.lower():
           return True

    return False # If no success keywords found


if __name__ == "__main__":
    target_host = "8.8.8.8"  # Google's public DNS server

    ping_result = ping(target_host)

    if ping_result is not None:
        print("Ping Output:")
        print(ping_result)

        if check_ping_reply(ping_result):
            print(f"{target_host} is reachable.")
        else:
            print(f"{target_host} is not reachable or the reply format is unexpected.")

############################ END ############################