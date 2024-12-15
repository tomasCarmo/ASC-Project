terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.6.0"
    }
  }
}

provider "google" {
  project = "csa-project2"
  #project = "cloudcomputingadm"
  region = "europe-west6"
  zone = "europe-west6-a"
  credentials = "../credentials/account2.json"
}