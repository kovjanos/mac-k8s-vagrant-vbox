packer {
  required_plugins {
    virtualbox = {
      version = ">= 1.0.2"
      source  = "github.com/hashicorp/virtualbox"
    }
    vagrant = {
      version = ">= 1.0.1"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

variables {
    name      = "jammy-k8s"
    version   = "1"
}

source "vagrant" "ubuntu-jammy64-src" {
  communicator = "ssh"
  source_path = "ubuntu/jammy64"
  provider = "virtualbox"
  output_dir = "${path.root}/../local/build"
  box_name = "jammy64-k8s"
  add_force = false
  skip_add = true
  insert_key = false
  template = "${path.root}/v.tpl"
  synced_folder = "${path.root}/../"
}

build {
  sources = ["sources.vagrant.ubuntu-jammy64-src"]

  provisioner "shell-local" {
    inline = [ "echo Building image..." ]
  }

  provisioner "shell" {
    inline = [ "sh /vagrant/ubuntu/x_sudo_install.sh" ]
  }
}


