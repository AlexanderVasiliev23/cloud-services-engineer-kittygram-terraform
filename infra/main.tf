terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }

  backend "s3" {
    endpoints = {
      s3 = "https://storage.yandexcloud.net"
    }
    bucket = "my-test-bucket-b1glqqloj07ds96u2ita"
    region = "ru-central1"
    key    = "tf-state.tfstate"

    skip_region_validation      = true
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }
}

provider "yandex" {
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = "ru-central1-a"
}

resource "yandex_vpc_network" "network" {
  name = "network1"
}

resource "yandex_vpc_subnet" "subnet" {
  name       = "subnet1"
  network_id = yandex_vpc_network.network.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_security_group" "vm_sg" {
  name        = "vm-security-group"
  description = "Разрешить весь исходящий трафик, а также входящий на 80 и 22 порты (SSH и HTTP)"
  network_id  = yandex_vpc_network.network.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    from_port      = 0
    to_port        = 65535
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_compute_instance" "vm-1" {
  name        = "terraform-vm-1"
  platform_id = "standard-v3"

  resources {
    cores  = 6
    memory = 6
  }

  boot_disk {
    initialize_params {
      image_id = "fd8bbhtvdodbbranefoe" # Ubuntu 24.04 LTS
      type = "network-ssd-nonreplicated"
      size = 93
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet.id
    nat       = true
    security_group_ids = [yandex_vpc_security_group.vm_sg.id]
  }

  metadata = {
    user-data = file(var.new_user)
  }
}

output "vm_public_ip" {
  description = "The public IP of the instance"
  value       = yandex_compute_instance.vm-1.network_interface.0.nat_ip_address
}