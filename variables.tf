variable "project_id" {
  description = "The GCP Project ID."
  type        = string
  default     = "alpine-anvil-473102-c4" # Your project ID
}

variable "gcp_region" {
  description = "The GCP region to deploy resources in."
  type        = string
  default     = "us-central1"
}

variable "gcp_zone" {
  description = "The GCP zone for zonal resources."
  type        = string
  default     = "us-central1-a"
}

variable "gke_region" {
  description = "The region for the GKE cluster (can be same as gcp_region)."
  type        = string
  default     = "us-central1"
}

variable "cluster_name" {
  description = "The name for the GKE cluster."
  type        = string
  default     = "gke-securebank-prod"
}

variable "bastion_ip" {
  description = "The IP address of your bastion host or corporate office to allow kubectl access."
  type        = string
  # IMPORTANT: You must change this value to your current IP!
  default = "174.91.157.19/32"
}

variable "github_repo" {
  description = "Your GitHub repository in 'org/repo' format."
  type        = string
  # CRITICAL: You must change this to your repo!
  default = "gandinehru35-spec/secure-bank" 
}

