# mac-k8s-vagrant-vbox

Creates a few machines and sets up K8S on them.

All nodes are created with
- internal network hosting k8s. Private network 'k8s' is on 192.168.57/24.
- host-only network to access nodes if needed. Host only network is on 192.168.56/24.
- optionally with public network (either static or dhcp).

All hosts are exposed for ssh on localhost on port 221x (masters) or 222x (workers)

Put your favourite SSH Public key into local/my-ssh-key.pub and it will be injected into all hosts.



Props to be set in the Vagrant file:
- NUM_MASTER_NODE

  Define the number of master nodes you need. Currently no HA is supported, this is only for further development. 
  If you define more than 4 noes, you will need to update the pre-generated hosts file within ubuntu/setup/01_setup-hosts.sh
  Max master nodes can be 9!

- NUM_WORKER_NODE

  Define the number of worker nodes you need.
  If you define more than 8 noes, you will need to update the pre-generated hosts file within ubuntu/setup/01_setup-hosts.sh
  Max worker nodes can be 79!
  
- USE_PUBLIC_NET

  Whether to configure public network on the nodes or not:
  - dhcp : use dhcp to assign IP to the public interface 
  - yes  : use static IP addresses for the public interface - make sure addresses won't clash on your network!
  
- PUBLIC_BRIDGE_IF

  List of host interfaces to try to use for the public interface.
  
- PUBLIC_IP_NW PUBLIC_MASTER_IP_START PUBLIC_WORKER_IP_START

  IP address configuration for the public interfaces in case if USE_PUBLIC_NET=yes. The IP_NW sets in which net these should be in, and the IP_START variables set how the addresses will be calculated. E.g.:
  
     IP= PUBLIC_IP_NW || "PUBLIC_MASTER_IP_START + #number-of-the-nodes"
     
- DNS

  The address of your preferred DNS server. E.g.  DNS=8.8.8.8
  
- VBOX

  Version of your VirtualBox - this is required to install the right version of VBox Guest Addons
  
- DOCKER

  The version of docker-ce for Ubuntu availbale in their repo. E.g. DOCKER=20.10 
  Note: make sure the repo has the Ubuntu specific release!
  
- K8S

  Version of k8s to install
