# proxmox cluster

This will use **terraform** on **libvirt** to create **Debian** VMs which use **cloud-init** and are provisioned by **ansible** with **proxmox** and will join a cluster. By default, we create a cluster with **3 nodes** with **2GB** and **1 vCPU**.

We need an image (*debian-11-genericcloud-amd64.qcow2*). You can find it [here](https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2)

It's all kicked into action by the `clean` command. It

- lints the playbook
- syntax-checks the playbook
- removes abandoned files 
- destroys every VM created, including i's storage
- Initializes terraform
- destroy's terraform old state if any
- apply's the new VMs using terraform
- Runs the ansible playbook

## libvirt

We use libvirt for the VMs. They use **DHCP** for their network on the "*default*" network.

## Terraform

Terraform creates three VM's ("*proxmox1.pve*", "*proxmox2.pve*", "*proxmox3.pve*"). They are setup with 2GB RAM and 1 vCPU. It also gives me an inventory file that I can feed to Ansible

### cloud-init

Cloud-init (template: `cloud_init.cfg`) makes sure we can login to the VMs after creation. It will add a default user (ubuntu) with a public key

**WARNING**: Leaves you with a rootuser with password `linux`!

## Ansible

Ansible fetches the GPG key + repository for Proxmox and builds a private key that gets distributed to the other hosts as well. Without statifying some network resources, I found my network dropping on the VMs. Maybe due to `cloud-init` but at least, this fixes it. The `/etc/hosts` file is also build.

It proceeds with installing some dependencies and packagemanager updates before it start installing proxmox. This step takes the most time.

Finally, it removes some packages (cloud-init among them) and removes an enterprise apt-source which is inaccessible for us and breaks apt.

After the generic playbook for all hosts, Ansible focuses on the first host, creating the cluster there.

On the other nodes, it joins the cluster.

Finally, it reboots every node that needs a reboot

## proxmox

You can reach proxmox on every node on port 8006

# Todo

- Script that runs hourly, fetches git updates, runs ansible pull (using flock to prevent duplicate runs)

- remove ubuntu user

- create local users

  

## adhoc

```bash
ansible -m command -a "sudo pvecm nodes" proxmox
```



### Walkthrough

```bash
$ ./clean
Domain 'proxmox1' destroyed

Domain 'proxmox1' has been undefined
Volume 'vda'(os_image.0) removed.
Volume 'hdd'(/var/lib/libvirt/images/proxmox1-commoninit.iso) removed.

Domain 'proxmox2' destroyed

Domain 'proxmox2' has been undefined
Volume 'vda'(os_image.1) removed.
Volume 'hdd'(/var/lib/libvirt/images/proxmox2-commoninit.iso) removed.

Domain 'proxmox3' destroyed

Domain 'proxmox3' has been undefined
Volume 'vda'(os_image.2) removed.
Volume 'hdd'(/var/lib/libvirt/images/proxmox3-commoninit.iso) removed.

error: failed to get domain 'proxmox4'

error: failed to get domain 'proxmox4'

error: failed to get domain 'proxmox5'

error: failed to get domain 'proxmox5'


Initializing the backend...

Initializing provider plugins...
- Finding latest version of dmacvicar/libvirt...
- Finding latest version of hashicorp/local...
- Finding latest version of hashicorp/template...
- Installing hashicorp/template v2.2.0...
- Installed hashicorp/template v2.2.0 (signed by HashiCorp)
- Installing dmacvicar/libvirt v0.6.12...
- Installed dmacvicar/libvirt v0.6.12 (self-signed, key ID 96B1FE1A8D4E1EAB)
- Installing hashicorp/local v2.1.0...
- Installed hashicorp/local v2.1.0 (signed by HashiCorp)

Partner and community providers are signed by their developers.
If you'd like to know more about provider signing, you can read about it here:
https://www.terraform.io/docs/cli/plugins/signing.html

Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.

Changes to Outputs:

You can apply this plan to save these new output values to the Terraform state, without changing any real infrastructure.

Destroy complete! Resources: 0 destroyed.

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  + create

Terraform will perform the following actions:

  # libvirt_cloudinit_disk.commoninit[0] will be created
  + resource "libvirt_cloudinit_disk" "commoninit" {
      + id        = (known after apply)
      + name      = "proxmox1-commoninit.iso"
      + pool      = "default"
      + user_data = <<-EOT
            #cloud-config
            manage_etc_hosts: false
            users:
              - name: ubuntu
                sudo: ALL=(ALL) NOPASSWD:ALL
                groups: users, admin
                home: /home/ubuntu
                shell: /bin/bash
                lock_passwd: false
                ssh-authorized-keys:
                  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNzf2muhWD6usC+KizmE1ZTElr5OybNe+YMK6DlOu8S85yDn63un6iFOq2dnKhTIMKtwD31GdVcorzWBRaXR1Oj+Ypa5BueeFZnuCD5fUhou2chmW8gsmp1FYtSTcf4Ek5yynUwb3n1dPxQ3f0eW7fcY30jKhyFL7M0HvyGBnXBNcajNRtc7amKSPseg7tKdo5F64W8GdjzrJLyXzyzmD105G0S6Bc8QMgGaPdCoK/WJGAsan0v1XnSOzGRq/BZSrEhPgnIQcEDDSYG8Gwznz2Ex+y081Qn8nFi8NLr3XZwczB1i76wOfXL4I7A+ExPrbFU+qTNC/zRJSyEqwPxW9f wouter@dell
            hostname: proxmox1
            fqdn: proxmox1
            ssh_pwauth: false
            disable_root: false
            chpasswd:
              list: |
                 root:linux
              expire: False
        EOT
    }

  # libvirt_cloudinit_disk.commoninit[1] will be created
  + resource "libvirt_cloudinit_disk" "commoninit" {
      + id        = (known after apply)
      + name      = "proxmox2-commoninit.iso"
      + pool      = "default"
      + user_data = <<-EOT
            #cloud-config
            manage_etc_hosts: false
            users:
              - name: ubuntu
                sudo: ALL=(ALL) NOPASSWD:ALL
                groups: users, admin
                home: /home/ubuntu
                shell: /bin/bash
                lock_passwd: false
                ssh-authorized-keys:
                  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNzf2muhWD6usC+KizmE1ZTElr5OybNe+YMK6DlOu8S85yDn63un6iFOq2dnKhTIMKtwD31GdVcorzWBRaXR1Oj+Ypa5BueeFZnuCD5fUhou2chmW8gsmp1FYtSTcf4Ek5yynUwb3n1dPxQ3f0eW7fcY30jKhyFL7M0HvyGBnXBNcajNRtc7amKSPseg7tKdo5F64W8GdjzrJLyXzyzmD105G0S6Bc8QMgGaPdCoK/WJGAsan0v1XnSOzGRq/BZSrEhPgnIQcEDDSYG8Gwznz2Ex+y081Qn8nFi8NLr3XZwczB1i76wOfXL4I7A+ExPrbFU+qTNC/zRJSyEqwPxW9f wouter@dell
            hostname: proxmox2
            fqdn: proxmox2
            ssh_pwauth: false
            disable_root: false
            chpasswd:
              list: |
                 root:linux
              expire: False
        EOT
    }

  # libvirt_cloudinit_disk.commoninit[2] will be created
  + resource "libvirt_cloudinit_disk" "commoninit" {
      + id        = (known after apply)
      + name      = "proxmox3-commoninit.iso"
      + pool      = "default"
      + user_data = <<-EOT
            #cloud-config
            manage_etc_hosts: false
            users:
              - name: ubuntu
                sudo: ALL=(ALL) NOPASSWD:ALL
                groups: users, admin
                home: /home/ubuntu
                shell: /bin/bash
                lock_passwd: false
                ssh-authorized-keys:
                  - ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDNzf2muhWD6usC+KizmE1ZTElr5OybNe+YMK6DlOu8S85yDn63un6iFOq2dnKhTIMKtwD31GdVcorzWBRaXR1Oj+Ypa5BueeFZnuCD5fUhou2chmW8gsmp1FYtSTcf4Ek5yynUwb3n1dPxQ3f0eW7fcY30jKhyFL7M0HvyGBnXBNcajNRtc7amKSPseg7tKdo5F64W8GdjzrJLyXzyzmD105G0S6Bc8QMgGaPdCoK/WJGAsan0v1XnSOzGRq/BZSrEhPgnIQcEDDSYG8Gwznz2Ex+y081Qn8nFi8NLr3XZwczB1i76wOfXL4I7A+ExPrbFU+qTNC/zRJSyEqwPxW9f wouter@dell
            hostname: proxmox3
            fqdn: proxmox3
            ssh_pwauth: false
            disable_root: false
            chpasswd:
              list: |
                 root:linux
              expire: False
        EOT
    }

  # libvirt_domain.domain[0] will be created
  + resource "libvirt_domain" "domain" {
      + arch        = (known after apply)
      + autostart   = true
      + cloudinit   = (known after apply)
      + disk        = [
          + {
              + block_device = null
              + file         = null
              + scsi         = null
              + url          = null
              + volume_id    = (known after apply)
              + wwn          = null
            },
        ]
      + emulator    = (known after apply)
      + fw_cfg_name = "opt/com.coreos/config"
      + id          = (known after apply)
      + machine     = (known after apply)
      + memory      = 2048
      + name        = "proxmox1"
      + qemu_agent  = false
      + running     = true
      + vcpu        = 1

      + console {
          + source_host    = "127.0.0.1"
          + source_service = "0"
          + target_port    = "0"
          + target_type    = "serial"
          + type           = "pty"
        }
      + console {
          + source_host    = "127.0.0.1"
          + source_service = "0"
          + target_port    = "1"
          + target_type    = "virtio"
          + type           = "pty"
        }

      + graphics {
          + autoport       = true
          + listen_address = "127.0.0.1"
          + listen_type    = "address"
          + type           = "spice"
        }

      + network_interface {
          + addresses      = (known after apply)
          + hostname       = (known after apply)
          + mac            = (known after apply)
          + network_id     = (known after apply)
          + network_name   = "default"
          + wait_for_lease = true
        }
    }

  # libvirt_domain.domain[1] will be created
  + resource "libvirt_domain" "domain" {
      + arch        = (known after apply)
      + autostart   = true
      + cloudinit   = (known after apply)
      + disk        = [
          + {
              + block_device = null
              + file         = null
              + scsi         = null
              + url          = null
              + volume_id    = (known after apply)
              + wwn          = null
            },
        ]
      + emulator    = (known after apply)
      + fw_cfg_name = "opt/com.coreos/config"
      + id          = (known after apply)
      + machine     = (known after apply)
      + memory      = 2048
      + name        = "proxmox2"
      + qemu_agent  = false
      + running     = true
      + vcpu        = 1

      + console {
          + source_host    = "127.0.0.1"
          + source_service = "0"
          + target_port    = "0"
          + target_type    = "serial"
          + type           = "pty"
        }
      + console {
          + source_host    = "127.0.0.1"
          + source_service = "0"
          + target_port    = "1"
          + target_type    = "virtio"
          + type           = "pty"
        }

      + graphics {
          + autoport       = true
          + listen_address = "127.0.0.1"
          + listen_type    = "address"
          + type           = "spice"
        }

      + network_interface {
          + addresses      = (known after apply)
          + hostname       = (known after apply)
          + mac            = (known after apply)
          + network_id     = (known after apply)
          + network_name   = "default"
          + wait_for_lease = true
        }
    }

  # libvirt_domain.domain[2] will be created
  + resource "libvirt_domain" "domain" {
      + arch        = (known after apply)
      + autostart   = true
      + cloudinit   = (known after apply)
      + disk        = [
          + {
              + block_device = null
              + file         = null
              + scsi         = null
              + url          = null
              + volume_id    = (known after apply)
              + wwn          = null
            },
        ]
      + emulator    = (known after apply)
      + fw_cfg_name = "opt/com.coreos/config"
      + id          = (known after apply)
      + machine     = (known after apply)
      + memory      = 2048
      + name        = "proxmox3"
      + qemu_agent  = false
      + running     = true
      + vcpu        = 1

      + console {
          + source_host    = "127.0.0.1"
          + source_service = "0"
          + target_port    = "0"
          + target_type    = "serial"
          + type           = "pty"
        }
      + console {
          + source_host    = "127.0.0.1"
          + source_service = "0"
          + target_port    = "1"
          + target_type    = "virtio"
          + type           = "pty"
        }

      + graphics {
          + autoport       = true
          + listen_address = "127.0.0.1"
          + listen_type    = "address"
          + type           = "spice"
        }

      + network_interface {
          + addresses      = (known after apply)
          + hostname       = (known after apply)
          + mac            = (known after apply)
          + network_id     = (known after apply)
          + network_name   = "default"
          + wait_for_lease = true
        }
    }

  # libvirt_volume.os_image[0] will be created
  + resource "libvirt_volume" "os_image" {
      + format = "qcow2"
      + id     = (known after apply)
      + name   = "os_image.0"
      + pool   = "default"
      + size   = (known after apply)
      + source = "./debian-11-genericcloud-amd64.qcow2"
    }

  # libvirt_volume.os_image[1] will be created
  + resource "libvirt_volume" "os_image" {
      + format = "qcow2"
      + id     = (known after apply)
      + name   = "os_image.1"
      + pool   = "default"
      + size   = (known after apply)
      + source = "./debian-11-genericcloud-amd64.qcow2"
    }

  # libvirt_volume.os_image[2] will be created
  + resource "libvirt_volume" "os_image" {
      + format = "qcow2"
      + id     = (known after apply)
      + name   = "os_image.2"
      + pool   = "default"
      + size   = (known after apply)
      + source = "./debian-11-genericcloud-amd64.qcow2"
    }

  # local_file.hosts_cfg will be created
  + resource "local_file" "hosts_cfg" {
      + content              = (known after apply)
      + directory_permission = "0777"
      + file_permission      = "0644"
      + filename             = "inventory"
      + id                   = (known after apply)
    }

Plan: 10 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + ips = [
      + (known after apply),
      + (known after apply),
      + (known after apply),
    ]
libvirt_volume.os_image[0]: Creating...
libvirt_volume.os_image[2]: Creating...
libvirt_volume.os_image[1]: Creating...
libvirt_cloudinit_disk.commoninit[0]: Creating...
libvirt_cloudinit_disk.commoninit[2]: Creating...
libvirt_cloudinit_disk.commoninit[1]: Creating...
libvirt_volume.os_image[2]: Creation complete after 0s [id=/var/lib/libvirt/images/os_image.2]
libvirt_volume.os_image[1]: Creation complete after 1s [id=/var/lib/libvirt/images/os_image.1]
libvirt_volume.os_image[0]: Creation complete after 1s [id=/var/lib/libvirt/images/os_image.0]
libvirt_cloudinit_disk.commoninit[2]: Creation complete after 1s [id=/var/lib/libvirt/images/proxmox3-commoninit.iso;0fe8e872-5ac8-40ec-b7ce-b1b17594ca53]
libvirt_cloudinit_disk.commoninit[0]: Creation complete after 1s [id=/var/lib/libvirt/images/proxmox1-commoninit.iso;669f0f9f-992a-45e3-baa5-a07b781333ad]
libvirt_cloudinit_disk.commoninit[1]: Creation complete after 1s [id=/var/lib/libvirt/images/proxmox2-commoninit.iso;76dfab98-45d7-445a-a2ed-cf6758324325]
libvirt_domain.domain[0]: Creating...
libvirt_domain.domain[2]: Creating...
libvirt_domain.domain[1]: Creating...
libvirt_domain.domain[0]: Still creating... [10s elapsed]
libvirt_domain.domain[2]: Still creating... [10s elapsed]
libvirt_domain.domain[1]: Still creating... [10s elapsed]
libvirt_domain.domain[0]: Still creating... [20s elapsed]
libvirt_domain.domain[2]: Still creating... [20s elapsed]
libvirt_domain.domain[1]: Still creating... [20s elapsed]
libvirt_domain.domain[0]: Still creating... [30s elapsed]
libvirt_domain.domain[2]: Still creating... [30s elapsed]
libvirt_domain.domain[1]: Still creating... [30s elapsed]
libvirt_domain.domain[2]: Creation complete after 36s [id=7b52bc2b-77ae-4647-b8e4-e319b16a7a43]
libvirt_domain.domain[0]: Creation complete after 37s [id=2653e9d7-bd55-4d0a-8a36-d4d9ec9802d7]
libvirt_domain.domain[1]: Creation complete after 37s [id=bdcef996-7db4-4abd-a4cb-3b3758002794]
local_file.hosts_cfg: Creating...
local_file.hosts_cfg: Creation complete after 0s [id=55db295fe415dba194b352472ca2c696c57bb6dd]

Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

Outputs:

ips = [
  "192.168.122.156",
  "192.168.122.24",
  "192.168.122.204",
]

PLAY [Configure all hosts] *************************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************
ok: [proxmox1]
ok: [proxmox3]
ok: [proxmox2]

TASK [Get Proxmox GPG key] *************************************************************************************************
changed: [proxmox2]
changed: [proxmox3]
changed: [proxmox1]

TASK [Install Proxmox repository] ******************************************************************************************
changed: [proxmox2]
changed: [proxmox3]
changed: [proxmox1]

TASK [Add public key] ******************************************************************************************************
changed: [proxmox2]
changed: [proxmox3]
changed: [proxmox1]

TASK [Add hourly cronjob] **************************************************************************************************
changed: [proxmox1]
changed: [proxmox2]
changed: [proxmox3]

TASK [Add private key] *****************************************************************************************************
changed: [proxmox1]
changed: [proxmox2]
changed: [proxmox3]

TASK [Statify hosts file] **************************************************************************************************
changed: [proxmox1]
changed: [proxmox3]
changed: [proxmox2]

TASK [Statify static network config] ***************************************************************************************
changed: [proxmox1]
changed: [proxmox3]
changed: [proxmox2]

TASK [Install dependencies packages] ***************************************************************************************
changed: [proxmox2]
changed: [proxmox3]
changed: [proxmox1]

TASK [Pass options to dpkg on run] *****************************************************************************************
ok: [proxmox1]
ok: [proxmox2]
ok: [proxmox3]

TASK [Add host to hosts] ***************************************************************************************************
ok: [proxmox2]
ok: [proxmox3]
ok: [proxmox1]

TASK [Install proxmox] *****************************************************************************************************
changed: [proxmox1]
changed: [proxmox2]
changed: [proxmox3]

TASK [remove os-prober & cloud-init] ***************************************************************************************
changed: [proxmox3]
changed: [proxmox1]
changed: [proxmox2]

TASK [Cleanup cloud-init leftovers] ****************************************************************************************
changed: [proxmox1] => (item=/var/lib/cloud/)
changed: [proxmox2] => (item=/var/lib/cloud/)
changed: [proxmox3] => (item=/var/lib/cloud/)
changed: [proxmox1] => (item=/etc/cloud)
changed: [proxmox2] => (item=/etc/cloud)
changed: [proxmox3] => (item=/etc/cloud)

TASK [Remove Enterprise apt-file] ******************************************************************************************
changed: [proxmox1]
changed: [proxmox2]
changed: [proxmox3]

RUNNING HANDLER [restart network] ******************************************************************************************
changed: [proxmox2]
changed: [proxmox3]
changed: [proxmox1]

PLAY [Master] **************************************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************
ok: [proxmox1]

TASK [Create cluster on first host] ****************************************************************************************
changed: [proxmox1]

TASK [Waits for port 8006] *************************************************************************************************
ok: [proxmox1]

TASK [Klaar!] **************************************************************************************************************
ok: [proxmox1] => {
    "msg": "Staat klaar op https://192.168.122.156:8006"
}

PLAY [Nodes] ***************************************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************
ok: [proxmox2]

TASK [Wait for cluster to settle] ******************************************************************************************
Pausing for 10 seconds
(ctrl+C then 'C' = continue early, ctrl+C then 'A' = abort)
ok: [proxmox2]

TASK [Find SSH key] ********************************************************************************************************
changed: [proxmox2]

TASK [Write SSH key to known_hosts] ****************************************************************************************
changed: [proxmox2]

TASK [Join to cluster proxmox1] ********************************************************************************************
changed: [proxmox2]

PLAY [Nodes] ***************************************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************
ok: [proxmox3]

TASK [Wait for cluster to settle] ******************************************************************************************
Pausing for 10 seconds
(ctrl+C then 'C' = continue early, ctrl+C then 'A' = abort)
ok: [proxmox3]

TASK [Find SSH key] ********************************************************************************************************
changed: [proxmox3]

TASK [Write SSH key to known_hosts] ****************************************************************************************
changed: [proxmox3]

TASK [Join to cluster proxmox1] ********************************************************************************************
changed: [proxmox3]

PLAY [All reboot] **********************************************************************************************************

TASK [Gathering Facts] *****************************************************************************************************
ok: [proxmox2]
ok: [proxmox1]
ok: [proxmox3]

TASK [Check if a reboot is needed for ProxMox boxes] ***********************************************************************
ok: [proxmox1]
ok: [proxmox3]
ok: [proxmox2]

TASK [Reboot?] *************************************************************************************************************
changed: [proxmox1]
changed: [proxmox2]
changed: [proxmox3]

PLAY RECAP *****************************************************************************************************************
proxmox1                   : ok=23   changed=15   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
proxmox2                   : ok=24   changed=17   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
proxmox3                   : ok=24   changed=17   unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   


```

