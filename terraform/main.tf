# main.tf

# Data block to fetch available GCP zones (equivalent to AWS Availability Zones)
# This will find zones like europe-west3-a, europe-west3-b, etc.
data "google_compute_zones" "available" {
  project = var.project_id
  region  = var.region
  status  = "UP" # Ensure zones are active
}

# GCP VPC Network Module
# Source: https://registry.terraform.io/modules/terraform-google-modules/network/google/latest
module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 8.0" # Use a recent stable version for the network module

  project_id   = var.project_id
  network_name = "${var.cluster_name}-vpc"
  routing_mode = "REGIONAL" # Or "GLOBAL" if you need global routing

  # Define subnets with secondary ranges for GKE pods/services
  subnets = [
    for i, subnet_cidr in var.public_subnets : {
      subnet_name           = "public-subnet-${i + 1}-${data.google_compute_zones.available.names[i]}"
      subnet_ip             = subnet_cidr
      subnet_region         = var.region
      subnet_private_access = false # Public subnet
      subnet_flow_logs      = false
      description           = "Public subnet for ${var.cluster_name} in ${data.google_compute_zones.available.names[i]}"
      secondary_ip_range    = [] # No secondary range for public subnets here
    },
    for i, subnet_cidr in var.private_subnets : {
      subnet_name           = "private-subnet-${i + 1}-${data.google_compute_zones.available.names[i]}"
      subnet_ip             = subnet_cidr
      subnet_region         = var.region
      subnet_private_access = true # Private subnet
      subnet_flow_logs      = false
      description           = "Private subnet for ${var.cluster_name} in ${data.google_compute_zones.available.names[i]}"
      secondary_ip_range = [
        { range_name = "gke-pods-${i + 1}", ip_cidr_range = var.gke_pods_cidr },
        { range_name = "gke-services-${i + 1}", ip_cidr_range = var.gke_services_cidr }
      ]
    }
  ]

  # Cloud NAT configuration (equivalent to AWS NAT Gateway)
  create_nat_gateway = var.enable_nat_gateway
  nat_ip_allocate_option = "AUTO_ONLY" # Automatically allocate public IPs
  nat_log_config = {
    enable = false
    filter = "ALL"
  }
  nat_subnetworks = [
    for subnet in module.vpc.subnets : {
      name = subnet.subnet_name
      source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
    } if subnet.subnet_private_access # Only NAT for private subnets
  ]
}

# --- GKE Cluster (Autopilot) ---
# Source: https://registry.terraform.io/modules/terraform-google-modules/kubernetes-engine/google//modules/autopilot-private-cluster
module "gke_cluster" {
  source  = "terraform-google-modules/kubernetes-engine/google//modules/autopilot-private-cluster"
  version = "~> 29.0" # Use a recent stable version for the GKE module

  project_id   = var.project_id
  name         = var.cluster_name
  region       = var.region
  network      = module.vpc.network_name
  # Use the first private subnet created by the VPC module for the cluster's main subnet
  subnetwork   = module.vpc.subnets_names_map["private-subnet-1-${data.google_compute_zones.available.names[0]}"]

  # For private clusters, you need to specify master_ipv4_cidr_block
  master_ipv4_cidr_block = var.master_ipv4_cidr_block

  # Enable Public Access for the control plane (if desired)
  # Note: enable_private_endpoint must be true for a private cluster.
  # enable_public_endpoint controls if a public IP is also exposed for the control plane.
  enable_private_endpoint = true
  enable_public_endpoint  = var.enable_public_endpoint

  # Autopilot clusters are always on a release channel.
  release_channel = "REGULAR" # Or "STABLE", "RAPID"

  # Logging and Monitoring
  logging_service   = "logging.googleapis.com/kubernetes"
  monitoring_service = "monitoring.googleapis.com/kubernetes"

  # Grant necessary roles to the GKE service agent for cluster operation
  grant_host_vm_service_agent_roles = true

  # Optional: Grant your user/service account `container.admin` role on the cluster
  # This makes it easier to manage the cluster with kubectl after creation.
  # Ensure the service account running Terraform has permissions to grant these roles.
  # This assumes the service account running Terraform has `roles/container.admin` on the project.
  # If you want to grant access to a specific user, you'd typically do it via `google_container_cluster_iam_member`
  # or `kubectl create clusterrolebinding` after the cluster is up.
  # For simplicity, if the user running `terraform apply` has `roles/container.admin` on the project,
  # they will automatically have access to the cluster.
}

# Output the VPC network name and self_link for reference
output "vpc_network_name" {
  description = "The name of the VPC network"
  value       = module.vpc.network_name
}

output "vpc_network_self_link" {
  description = "The self_link of the VPC network"
  value       = module.vpc.network_self_link
}

output "public_subnet_names" {
  description = "Names of the public subnets"
  value       = [for s in module.vpc.subnets : s.subnet_name if s.subnet_private_access == false]
}

output "private_subnet_names" {
  description = "Names of the private subnets"
  value       = [for s in module.vpc.subnets : s.subnet_name if s.subnet_private_access == true]
}

# Output the GKE cluster name and endpoint
output "gke_cluster_name" {
  description = "The name of the GKE cluster"
  value       = module.gke_cluster.name
}

output "gke_cluster_endpoint" {
  description = "The endpoint of the GKE cluster"
  value       = module.gke_cluster.endpoint
}
