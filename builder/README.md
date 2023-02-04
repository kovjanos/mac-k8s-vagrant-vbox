
This was made to speed up cluster creation tests with custom box already having updates and binaries installed.

Download & install the required tools:
- vagrant
- packer
- virtualbox


Get the base image, e.g.
```bash
vagrant box add ubuntu/jammy64 --provider virtualbox
vagrant box update --box ubuntu/jammy64
```

&nbsp;

> Note: in current packer (1.8.0) there is an old go/crypto library used by the ssh communicatior which can't connect to Ubuntu22.04's sshd after the initial boot. To work around the issue there is an ecdsa-sha2-nistp521 ssh-key injected into the image for build. The key then removed before create the new box from it.


&nbsp;

Build the box - adjust the meta.json if you need proper versioning:
```bash
rm -rf local/build 
PACKER_LOG=1 packer init builder/ 
PACKER_LOG=1 SSH_AUTH_SOCK='' packer build builder/
vagrant box add --force local/jammy64-k8s builder/meta.json 
```

After pushing to local repo, don't forget to change the Vagrantfile and set you new prebuilt image:
```bash
BOX_NAME = "local/jammy64-k8s"
BOX_PREINSTALLED = 1 
```
