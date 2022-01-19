# proxmox cluster

This will use **terraform** on **libvirt** to create **Debian** VMs which use **cloud-init** and are provisioned by **ansible** with **proxmox** and will join a cluster. By default, we create a cluster with **3 nodes** with **2GB** and **1 vCPU**.

We need an image (*debian-11-genericcloud-amd64.qcow2*). You can find it [here](https://cloud.debian.org/images/cloud/bullseye/latest/debian-11-genericcloud-amd64.qcow2)

## libvirt

We use libvirt for the VMs. They use **DHCP** for their network on the "*default*" network.



## Terraform

Terraform creates three VM's ("*proxmox1.pve*", "*proxmox2.pve*", "*proxmox3.pve*"). They are setup with 2GB RAM and 1 vCPU. 

### cloud-init

Cloud-init makes sure we can login to the VMs after creation. It will add a default user (ubuntu) with a public key

## Ansible

## proxmox



## adhoc

ansible -m command -a "sudo pvecm nodes" proxmox

### Walkthrough

