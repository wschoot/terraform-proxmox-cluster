terraform {
  required_version = ">= 0.13"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
    }
  }
}

provider "libvirt" {
  uri = "qemu:///system"
}

variable "memoryMB" { default = 1024 * 2 }
variable "cpu"      { default = 1 }
variable "network"  { default = "default" }
variable "domain"   { default = "pve" }

variable "hostname" {
  type    = list(string)
  default = ["proxmox1"]
  #default = ["proxmox1", "proxmox2", "proxmox3"]
}

variable "ssh_username" {
  description = "the ssh user to use"
  default     = "ubuntu"
}

variable "ssh_private_key" {
  description = "the private key to use"
  default     = "~/.ssh/id_rsa"
}

resource "libvirt_volume" "os_image" {
  count = length(var.hostname)
  name = "os_image.${count.index}"
  pool = "default"
  source = "./debian-11-genericcloud-amd64.qcow2"
  format = "qcow2"
}

resource "libvirt_cloudinit_disk" "commoninit" {
  count     = length(var.hostname)
  name      = "${var.hostname[count.index]}-commoninit.iso"
  user_data = data.template_file.user_data[count.index].rendered
}

data "template_file" "user_data" {
  count    = length(var.hostname)
  template = file("${path.module}/cloud_init.cfg")
  vars = {
    hostname = element(var.hostname, count.index),
    fqdn     = element(var.hostname, count.index),
  }
}

resource "libvirt_domain" "domain" {
  count      = length(var.hostname)
  name       = var.hostname[count.index]
  memory     = var.memoryMB
  vcpu       = var.cpu
  autostart  = true

  disk {
    volume_id = element(libvirt_volume.os_image.*.id, count.index)
  }

  network_interface {
    network_name   = var.network
    wait_for_lease = true
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = "true"
  }

  cloudinit = libvirt_cloudinit_disk.commoninit[count.index].id
}

output "ips" {
  value = libvirt_domain.domain.*.network_interface.0.addresses.0
}

# https://stackoverflow.com/questions/45489534/best-way-currently-to-create-an-ansible-inventory-from-terraform
resource "local_file" "hosts_cfg" {
  content = templatefile(
    "${path.module}/inventory.tmpl",
    {
      proxmoxservers = libvirt_domain.domain.*
    }
  )
  filename = "inventory"
  file_permission = "0644"
}

