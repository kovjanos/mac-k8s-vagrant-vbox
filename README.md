# mac-k8s-vagrant-vbox

Creates a few machines and sets up K8S on them.

All nodes are created with
- internal network hosting k8s. Private network ``k8s`` is on ``192.168.57/24``.
- host-only network to access nodes if needed. Host only network is on ``192.168.56/24``.
- optionally with public network (either static or dhcp).
- currently only single-master multi-worker mode is supprted

All hosts are exposed for ssh on localhost on port 221x (masters) or 222x (workers) for easy access.
Put your favourite SSH Public key as ``local/my-ssh-key.pub`` and it will be injected into all hosts,
e.g.:
```bash
# ~/.ssh/config
Host kubemaster1
  HostName localhost
  Port 2211
  User root
  IdentityFile ~/.ssh/id_rsa-foo-bar
  StrictHostKeyChecking = no
```
> NOTE: no need for the ``HostName localhost`` config if you put ``kubemaster1`` for ``127.0.0.1`` into your ``/etc/hosts`` - see also the host's kubectl comment.

&nbsp;
K8S will be installed with
- WEAVE as CNI
- NGINX Ingress Controller - in NodePort mode
- Dashboard (in progress)

For Ingress the host's ``80`` and ``443`` ports are forwarded to the Ingress Controller via the 1st master (``kubemaster1``).
> Note: these are privileged ports, might not work on your system!

Put your host/domain names on your localhost and ready to use ingress, e.g.:
```bash
# /etc/hosts
127.0.0.1   localhost  kubemaster1  foo.bar.com
```
...then create some ingress and should be accessible from your host OS:
```bahs
k config use-context vagrant-admin@vagrant
k create ns ingtest
k -n ingtest run web --image=httpd --port 80
k -n ingtest expose pod web --name websvc
k -n ingtest create ingress ingtesting --class=nginx --rule="foo.bar.com/*=websvc:80"

#from host OS:
curl http://foo.bar.com/
```
&nbsp;

Get your host's kubectl manage the vagrant based k8s via merging the clsuter's config into yours.
```bash
D=$(date +%Y%m%d%H%M%S)
cp ~/.kube/config ~/.kube/config-$D 
KUBECONFIG=local/kube-vagrant-config:~/.kube/config \
  kubectl config view --flatten > ~/.kube/merged-$D
cp -f ~/.kube/merged-$D ~/.kube/config 
```
> NOTE: for this to make it working you need to put the ``kubemaster1`` name on ``127.0.0.1`` into your ``/etc/hosts``

...then set your context and enjoy remote kubectl:
```bash
kubectl config use-context vagrant-admin@vagrant

kubectl get all -A
```

&nbsp;

If you are reinstalling the clsuter quite frequently, then look into [builder](builder/README.md) to prebuild the image with binaries preinstalled!

&nbsp;

## Config 

Install is moved from docker to containred. podman aslo installed on the nodes. Check for the ``./config`` file for more details!

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
  
