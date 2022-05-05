Vagrant.configure("2") do |config|
  config.vm.provider "virtualbox" do |v|
    v.check_guest_additions = false
  end

  config.vm.provision "file", source: "../../builder/vagrantKeys/authorized_keys", destination: ".ssh/authorized_keys"

  config.vm.define "source", autostart: false do |source|
	source.vm.box = "{{.SourceBox}}"
	config.ssh.insert_key = {{.InsertKey}}
        config.ssh.private_key_path = [
             "../../builder/vagrantKeys/vagrant",
             "../../builder/vagrantKeys/vagrant-ecdsa" 
        ]
  end

  config.vm.define "output" do |output|
	output.vm.box = "{{.BoxName}}"
	output.vm.box_url = "file://package.box"
	config.ssh.insert_key = {{.InsertKey}}
  end

  {{ if ne .SyncedFolder "" -}}
  		config.vm.synced_folder "{{.SyncedFolder}}", "/vagrant"
  {{- else -}}
  		config.vm.synced_folder ".", "/vagrant", disabled: true
  {{- end}}
end
