# FCUP - Cloud System Administration Project 23/24

The "Decentralized Virtual CDN with Opportunistic Offloading" aims to develop a decentralized CDN service using Google Cloud, akin to services provided by Cloudflare and Akamai. The project involves deploying servers globally to meet client demand while minimizing latency, and leveraging client devices for caching with specific constraints.

The evaluation criteria for this project include performance, cost, architecture design, and predictive model accuracy, each with a base and ranking component contributing to the final grade. Key tools and technologies for the project include NGINX, a database using Redis, and managed services from GCP, while excluding PHP and Node.js. The assignment emphasizes detailed reporting on cost analysis, architectural design, and workload prediction models.

## Project Overview

### Architecture

The key components for the creation of a CDN were:
- Subnet
- Clients Virtual Machine Instances
- Origin Server Virtual Machine Instances
- Two Edge Servers Virtual Machine Instances
- Instance Groups: created for each VM
- Backend Service
- Load Balancer: cross-region internal Application Load Balancer
- Private Network: for clients to communicate with other clients

### Configuration

Utilizing Terraform configurations requires the following steps:

1. Confirm Terraform is set up on your system.


    #### Windows users: 

    - Download the Terraform zip file from the [official Terraform website](https://developer.hashicorp.com/terraform/install?product_intent=terraform#Windows).
    - Extract the contents of the zip file to a directory of your choice.
    - Add the path of the extracted Terraform executable to your system's `PATH` environment variable.

    #### MacOS Users: 

    ```code 
    brew install terraform
    ```

    #### Linux Users: 

    ```code
    sudo apt-get update
    sudo apt-get install -y terraform
    ```

2. Obtain the repository by cloning or downloading its contents.
3. Change the working directory to the one that includes the ```main.tf``` file.
4. Execute ```terraform init``` to begin the setup process.
5. Use ```terraform validate``` to ensure the configurations are syntactically correct and error-free.
6. Preview the impending changes to your infrastructure with terraform plan.
7. Implement the infrastructure changes by running ```terraform apply```.
8. Include the ```--auto-approve``` option to streamline the process and skip manual confirmations.

  It is important to acknolegde that in case of any modifications in the Terraform files, we need to reinitiate the process from step 5. The terraform init command is a one-time requirement, only needed for the first-time setup or when we switch to a new set of Terraform configurations.

For our Google Cloud setup we started by creating a new project and a new service account as well. Then we connected the project to our terraform structure resorting to `provider.tf`.

```tf 
terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.6.0"
    }
  }
}

provider "google" {
  project = "ads-project-2324"
  region = "europe-west4"
  zone = "europe-west4-a"
  credentials = "../SA-keys/adsKey.json"
}
```

Upon a succesfull estabilishment, we built a `main.tf` file with a configuration of all the necessary configurations. Including:

- **Subnet:**

```tf
resource "google_compute_subnetwork" "default" {
  name          = "subnetwork"
  ip_cidr_range = "10.0.0.0/24"
  region        = "eu-west6"
  network       = "default"
}
```


- **For the Clients VMs:**

```tf
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

    network_ip = "10.140.0.1"
  }

  metadata_startup_script = ""
}

resource "google_compute_instance" "vm-client-instance-eu" {
  name         = "client-instance"
  machine_type = "e2-micro"
  zone         = "eu-west6-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-12"
    }
  }

  network_interface {
    network = "default"
    access_config {
      
    }

    network_ip = "10.172.0.1"
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

    network_ip = "10.128.0.1"
  }

  metadata_startup_script = ""
}
```

- **For the Origin Server VM:**

```tf
resource "google_compute_instance" "vm-origin-server-instance-eu" {
  name         = "origin-server-instance-eu"
  machine_type = "e2-micro"
  zone         = "eu-west6-a"

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
```

- **For the Edge Servers VM:**

```tf
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
```

The startup script is shown below:

```sh
sudo apt update

# INSTALL NGINX
sudo apt install nginx

# HTTPS
sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/nginx/ssl/nginx.key -out /etc/nginx/ssl/nginx.crt
```

- **For the Instance Groups:**

```tf
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

  zone = "eu-west6-a"
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
```

- **For the Health Checks:**

```tf
resource "google_compute_health_check" "default" {
  name = "health-check"

  http_health_check {
    request_path = "/"
    port         = 80
  }
}
```

- **For the Backend Service:**

```tf
resource "google_compute_backend_service" "default" {
  name                  = "backend-service"
  load_balancing_scheme = "EXTERNAL"
  protocol              = "HTTP"
  port_name             = "http"
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
```

- **For the URL-Map:**

```tf
resource "google_compute_url_map" "default" {
  name            = "url-map"
  default_service = google_compute_backend_service.default.self_link
}
```

- **For the HTTP-Proxy:**

```tf
resource "google_compute_target_http_proxy" "default" {
  name    = "http-proxy"
  url_map = google_compute_url_map.default.self_link
}
```

Work by: 
- Raquel Carneiro, up202005330
- Tomás Carmo, up202007590
