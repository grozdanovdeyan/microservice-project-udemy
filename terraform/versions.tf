# versions.tf

terraform {
  required_version = ">= 1.0" 

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0" 
    }
  }
}

# Define variables for project and region
# This allows you to easily change them without modifying the provider block directly
variable "project_id" {
  description = "The GCP Project ID where resources will be created."
  type        = string
  default     = "sre-udemy-465306" # Your project ID
}

variable "region" {
  description = "The GCP region where resources will be deployed."
  type        = string
  default     = "europe-west3" 
}

# Configure the Google Cloud provider
provider "google" {
  project = var.project_id # Reference the project_id variable
  region  = var.region     # Reference the region variable
}
