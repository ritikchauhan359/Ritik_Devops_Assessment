provider "google" {
  credentials = file(var.gcp_credentials_file)
  project     = var.project
  region      = var.region
  zone        = var.zone
}

resource "google_compute_instance" "sre_vm" {
  name         = "sre-vm"
  machine_type = "e2-medium"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    ssh-keys = "ubuntu:${file(var.ssh_public_key)}"
  }

  tags = ["http-server", "https-server"]

provisioner "remote-exec" {
    inline = [
      "sudo apt update",
      "sudo apt install -y docker.io docker-compose git",
      "sudo usermod -aG docker ubuntu",
      "git clone https://github.com/ritikchauhan359/Ritik_Devops_Assessment.git",
      "cd your-docker-repo",
      "sudo docker-compose up -d"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.ssh_private_key)
      host        = self.network_interface[0].access_config[0].nat_ip
    }
  }
}


resource "google_compute_firewall" "allow_http_https" {
  name    = "allow-http-https"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server", "https-server"]
}
