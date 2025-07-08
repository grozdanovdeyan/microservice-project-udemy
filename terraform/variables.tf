# variables.tf

# GCP Project ID
variable "project_id" {
  description = "The GCP Project ID where resources will be created."
  type        = string
  # You can set a default here, or leave it blank if you always provide it via terraform.tfvars or CLI.
  default     = "sre-udemy-465306"
}

# GCP Region
variable "region" {
  description = "The GCP region where resources will be deployed (e.g., europe-west3)."
  type        = string
  default     = "europe-west3"
}

# Cluster Name
variable "cluster_name" {
  description = "Name for the GKE cluster and associated VPC resources."
  type        = string
  default     = "microservice-course-project"
}

# VPC CIDR Block
variable "vpc_cidr" {
  description = "The CIDR block for the VPC network."
  type        = string
  default     = "10.0.0.0/16"
}

# Public Subnets CIDR Blocks
variable "public_subnets" {
  description = "List of CIDR blocks for public subnets."
  type        = list(string)
  default = [
    "10.0.0.0/20",
    "10.0.16.0/20",
    "10.0.32.0/20"
  ]
}

# Private Subnets CIDR Blocks
variable "private_subnets" {
  description = "List of CIDR blocks for private subnets."
  type        = list(string)
  default = [
    "10.0.48.0/20",
    "10.0.64.0/20",
    "10.0.80.0/20"
  ]
}

# GKE Pods Secondary IP Range CIDR
variable "gke_pods_cidr" {
  description = "CIDR block for GKE pods secondary IP range."
  type        = string
  default     = "10.10.0.0/14" # Example, adjust as needed
}

# GKE Services Secondary IP Range CIDR
variable "gke_services_cidr" {
  description = "CIDR block for GKE services secondary IP range."
  type        = string
  default     = "10.20.0.0/20" # Example, adjust as needed
}

# GKE Master IPv4 CIDR Block (for private cluster endpoint)
variable "master_ipv4_cidr_block" {
  description = "CIDR block for the GKE master's internal IP address (for private cluster)."
  type        = string
  default     = "10.99.0.0/28" # Example, ensure no overlap with VPC or subnets
}

# Enable Public Endpoint for GKE Control Plane
variable "enable_public_endpoint" {
  description = "Whether to enable a public endpoint for the GKE control plane."
  type        = bool
  default     = true
}

# Enable Cloud NAT Gateway
variable "enable_nat_gateway" {
  description = "Whether to enable Cloud NAT Gateway for private subnets."
  type        = bool
  default     = true
}

