// Assign the startup scripts

// SUBNETWORK

/*resource "google_compute_subnetwork" "default" {
  name          = "subnetwork"
  ip_cidr_range = "10.0.0.0/24"
  region        = "europe-west6"
  network       = "default"
}*/

// VIRTUAL MACHINES INSTANCES
// Client Machines
resource "google_compute_instance" "vm-client-instance-asia" {
  name         = "client-instance-asia"
  machine_type = "e2-micro"
  zone         = "asia-east1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
    access_config {
      
    }

    network_ip = "10.140.0.10"
  }

  metadata_startup_script = ""
}

resource "google_compute_instance" "vm-client-instance-eu" {
  name         = "client-instance"
  machine_type = "e2-micro"
  zone         = "europe-west6-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
    access_config {
      
    }

    network_ip = "10.172.0.10"
  }

  metadata_startup_script = ""
}

resource "google_compute_instance" "vm-client-instance-us" {
  name         = "client-instance-us"
  machine_type = "e2-micro"
  zone         = "us-central1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
    access_config {
      
    }

    network_ip = "10.128.0.10"
  }

  metadata_startup_script = ""
}

// Edge Servers + P.O. Server

resource "google_compute_instance" "vm-server-instance-asia" {
  name         = "server-instance-asia"
  machine_type = "e2-micro"
  zone         = "asia-east1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
    access_config {
      
    }

    network_ip = "10.140.0.2"
  }

  metadata_startup_script = "startup.sh"
}

resource "google_compute_instance" "vm-origin-server-instance-eu" {
  name         = "origin-server-instance-eu"
  machine_type = "e2-micro"
  zone         = "europe-west6-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
    access_config {
      
    }

    network_ip = "10.172.0.2"
  }

  metadata_startup_script = "startup.sh"
}

resource "google_compute_instance" "vm-server-instance-us" {
  name         = "server-instance-us"
  machine_type = "e2-micro"
  zone         = "us-central1-b"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
    access_config {
      
    }

    network_ip = "10.128.0.2"
  }

  metadata_startup_script = "startup.sh"
}


// INSTANCE GROUPS

resource "google_compute_instance_group" "unmanaged-instance-group-asia" {
  name        = "instance-group-asia"
  description = "Unmanaged instance groups"

  instances = [google_compute_instance.vm-server-instance-asia.self_link]

  named_port {
    name = "http"
    port = "80"
  }

  named_port {
    name = "https"
    port = "443"
  }

  zone = "asia-east1-b"
}

resource "google_compute_instance_group" "unmanaged-instance-group-eu" {
  name        = "instance-group-eu"
  description = "Unmanaged instance groups"

  instances = [google_compute_instance.vm-origin-server-instance-eu.self_link]

  named_port {
    name = "http"
    port = "80"
  }

  named_port {
    name = "https"
    port = "443"
  }

  zone = "europe-west6-a"
}

resource "google_compute_instance_group" "unmanaged-instance-group-us" {
  name        = "instance-group-us"
  description = "Unmanaged instance groups"

  instances = [google_compute_instance.vm-server-instance-us.self_link]

  named_port {
    name = "http"
    port = "80"
  }

  named_port {
    name = "https"
    port = "443"
  }

  zone = "us-central1-b"
}

// HEALTH CHECK

resource "google_compute_health_check" "default" {
  name = "health-check"

  http_health_check {
    request_path = "/"
    port         = 80
  }
}

// Build the Endpoint Service in the Europe Region

resource "google_compute_backend_service" "default" {
  name                  = "backend-service"
  #load_balancing_scheme = "EXTERNAL"
  protocol              = "HTTP"
  #port_name             = "http"
  health_checks         = [google_compute_health_check.default.self_link]
  backend {
    group = google_compute_instance_group.unmanaged-instance-group-asia.self_link
  }

  backend {
    group = google_compute_instance_group.unmanaged-instance-group-eu.self_link
  }

  backend {
    group = google_compute_instance_group.unmanaged-instance-group-us.self_link
  }
}

// URL-MAP

resource "google_compute_url_map" "default" {
  name            = "url-map"
  default_service = google_compute_backend_service.default.self_link
}

// HTTP PROXY

resource "google_compute_target_http_proxy" "default" {
  name    = "http-proxy"
  url_map = google_compute_url_map.default.self_link
}

// INTERNAL ADDRESS

/*resource "google_compute_address" "default" {
  name        = "internal-address"
  subnetwork  = google_compute_subnetwork.default.self_link
  address_type = "INTERNAL"
  region      = "europe-west6"
}*/

resource "google_compute_global_address" "ipv4_address" {
  name = "ipv4-address"
  ip_version = "IPV4"
}

// FORWARDING RULE

resource "google_compute_global_forwarding_rule" "www_forwarding_rule_ipv4" {
  name        = "www-forwarding-rule-ipv4"
  ip_address  = google_compute_global_address.ipv4_address.address
  port_range  = "80"
  target      = google_compute_target_http_proxy.default.self_link
}

/*resource "google_compute_forwarding_rule" "default" {
  name                = "forwarding-rule"
  #load_balancing_scheme = "INTERNAL_MANAGED"
  #region = "europe-west6"
  target              = google_compute_target_http_proxy.default.self_link
  port_range          = "80"
  #network             = "default"
  #subnetwork          = google_compute_subnetwork.default.self_link
  #ip_address          = google_compute_address.default.address
}*/

// Build testing VM instances

