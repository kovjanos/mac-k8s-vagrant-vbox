# Define the number of master and worker nodes
NUM_MASTER_NODE = 1   # max 4
NUM_WORKER_NODE = 2   # max 8


# USE_PUBLIC_NET: configure an interface with direct public access 
#   yes:  uses the static IPs - see below
#   dhcp: uses dhcp to acquire IP for the if
#   no:   do not configure public if
USE_PUBLIC_NET = "dhcp"

# PUBLIC_BRIDGE_IF: list of interfaces to try to bridge to
#   required in case if USE_PUBLIC_NET != no
PUBLIC_BRIDGE_IF = [ 
  "en0: Ethernet", 
  "en0: Wi-Fi (Wireless)"
]

# PUBLIC_IP_NW + port bases 
#   required in case if USE_PUBLIC_NET = yes 
PUBLIC_IP_NW = "192.168.1."
PUBLIC_MASTER_IP_START = 210
PUBLIC_WORKER_IP_START = 220


DNS="8.8.8.8"    # preferred DNS
VBOX="6.1.34"    # VirtualBox version
DOCKER="20.10"   # Docker version filter for Ubuntu
K8S="1.23"       # k8s version to install 

MASTER_CPU=2
MASTER_MEM=2048
WORKER_CPU=2
WORKER_MEM=2048

# -----------

PRIVATE_IP_NW = "192.168.57."
PRIVATE_MASTER_IP_START = 10
PRIVATE_WORKER_IP_START = 20

HOSTNET_IP_NW = "192.168.56."
HOSTNET_MASTER_IP_START = 10
HOSTNET_WORKER_IP_START = 20

Vagrant.configure("2") do |config|
  #config.vm.box = "ubuntu/impish64"
  config.vm.box = "davekpatrick/ubuntu-2204"

  # Auto or `vagrant box outdated`?
  config.vm.box_check_update = false

  # Provision Master Nodes
  (1..NUM_MASTER_NODE).each do |i|
    config.vm.define "kubemaster#{i}" do |node|
      # Name shown in the GUI
      node.vm.provider "virtualbox" do |vb|
        vb.name = "kubemaster#{i}"
        vb.memory = MASTER_MEM
        vb.cpus = MASTER_CPU
      end
      node.vm.hostname = "kubemaster#{i}"
      node.vm.network :private_network, ip: PRIVATE_IP_NW + "#{PRIVATE_MASTER_IP_START + i}", virtualbox__intnet: "k8s"
      node.vm.network :forwarded_port, id: "ssh", guest: 22, host: "#{2210 + i}"
      node.vm.network :private_network, ip: HOSTNET_IP_NW + "#{HOSTNET_MASTER_IP_START + i}"
      if USE_PUBLIC_NET == "yes"
        node.vm.network :public_network, ip: PUBLIC_IP_NW + "#{PUBLIC_MASTER_IP_START + i}", bridge: PUBLIC_BRIDGE_IF
      else
        if USE_PUBLIC_NET == "dhcp"
          node.vm.network :public_network, type: "dhcp", bridge: PUBLIC_BRIDGE_IF
        end
      end

      if i == 1
        node.vm.network :forwarded_port, id: "ingress-http",  guest: 30001, host_ip: "0.0.0.0", host: "80"
        node.vm.network :forwarded_port, id: "ingress-https", guest: 30002, host_ip: "0.0.0.0", host: "443"
        node.vm.network :forwarded_port, id: "kubeapisrv",    guest: 6443,  host_ip: "0.0.0.0", host: "36443"
      end

      node.vm.provision "setup-hosts",   :type => "shell", :path => "ubuntu/setup/01_setup-hosts.sh" do |s|
        s.args = ["enp0s8"]
      end
      node.vm.provision "setup-dns",     :type => "shell", :path => "ubuntu/setup/02_update-dns.sh"  do |s|
        s.args = [DNS]
      end
      node.vm.provision "setup-upgrade", :type => "shell", :path => "ubuntu/setup/03_upgrade.sh"
      node.vm.provision "setup-vboxadd", :type => "shell", :path => "ubuntu/setup/04_install-guest-additions.sh" do |s|
        s.args = [VBOX]
      end
      node.vm.provision "setup-docker",  :type => "shell", :path => "ubuntu/setup/05_install-docker.sh" do |s|
        s.args = [DOCKER]
      end
      node.vm.provision "setup-sshkey",  :type => "shell", :path => "ubuntu/setup/06_add-ssh-key.sh"

      node.vm.provision :shell do |shell|
        shell.privileged = true
        shell.inline = 'echo rebooting'
        shell.reboot = true
      end

      node.vm.provision "setup-ks8-route", :type => "shell", :run => "always", :path => "ubuntu/k8s/setup_route.sh" do |s|
        s.args = ["enp0s8"]
      end
      node.vm.provision "setup-k8s-bin",   :type => "shell", :path => "ubuntu/k8s/01_install.sh" do |s|
        s.args = [K8S]
      end
      node.vm.provision "setup-k8s-cp",      :type => "shell", :path => "ubuntu/k8s/02_controlplane.sh"
      node.vm.provision "setup-k8s-ingress", :type => "shell", :path => "ubuntu/k8s/04_ingress.sh"
      node.vm.provision "setup-k9s",         :type => "shell", :path => "ubuntu/k8s/05_k9s.sh"
    end
  end

  # Provision Worker Nodes
  (1..NUM_WORKER_NODE).each do |i|
    config.vm.define "kubenode#{i}" do |node|
      node.vm.provider "virtualbox" do |vb|
        vb.name = "kubenode#{i}"
        vb.memory = WORKER_MEM
        vb.cpus = WORKER_CPU
      end
      node.vm.hostname = "kubenode#{i}"
      node.vm.network :private_network, ip: PRIVATE_IP_NW + "#{PRIVATE_WORKER_IP_START + i}", virtualbox__intnet: "k8s"
      node.vm.network :forwarded_port, id: "ssh", guest: 22, host: "#{2220 + i}"
      node.vm.network :private_network, ip: HOSTNET_IP_NW + "#{HOSTNET_MASTER_IP_START + i}"
      if USE_PUBLIC_NET == "yes"
        node.vm.network :public_network, ip: PUBLIC_IP_NW + "#{PUBLIC_WORKER_IP_START + i}", bridge: PUBLIC_BRIDGE_IF
      else
        if USE_PUBLIC_NET == "dhcp"
          node.vm.network :public_network, type: "dhcp", bridge: PUBLIC_BRIDGE_IF
        end
      end

      node.vm.provision "setup-hosts",   :type => "shell", :path => "ubuntu/setup/01_setup-hosts.sh" do |s|
        s.args = ["enp0s8"]
      end
      node.vm.provision "setup-dns",     :type => "shell", :path => "ubuntu/setup/02_update-dns.sh"  do |s|
        s.args = [DNS]
      end
      node.vm.provision "setup-upgrade", :type => "shell", :path => "ubuntu/setup/03_upgrade.sh"
      node.vm.provision "setup-vboxadd", :type => "shell", :path => "ubuntu/setup/04_install-guest-additions.sh"  do |s|
        s.args = [VBOX]
      end
      node.vm.provision "setup-docker",  :type => "shell", :path => "ubuntu/setup/05_install-docker.sh"  do |s|
        s.args = [DOCKER]
      end
      node.vm.provision "setup-sshkey",  type: "shell", :path => "ubuntu/setup/06_add-ssh-key.sh"

      node.vm.provision :shell do |shell|
        shell.privileged = true
        shell.inline = 'echo rebooting'
        shell.reboot = true
      end

      node.vm.provision "setup-ks8-route", :type => "shell", :run => "always", :path => "ubuntu/k8s/setup_route.sh" do |s|
        s.args = ["enp0s8"]
      end
      node.vm.provision "setup-k8s-bin",   :type => "shell", :path => "ubuntu/k8s/01_install.sh"  do |s|
        s.args = [K8S]
      end
      node.vm.provision "setup-k8s-wrk",   :type => "shell", :path => "ubuntu/k8s/03_join-worker.sh"
    end
  end
end

