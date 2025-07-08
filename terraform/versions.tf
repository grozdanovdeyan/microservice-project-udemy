terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

provider "google" {
  project = "sre-udemy-465306"
  region  = "europe-west4"
  zone    = "europe-west-4-b"
}
default_tags {
 tags = {
  owner = "grozdanovdeyan"
  }
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

