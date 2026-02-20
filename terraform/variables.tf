variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1"
}

variable "az_a" {
  description = "First Availability Zone"
  type        = string
  default     = "ap-south-1a"
}

variable "az_b" {
  description = "Second Availability Zone"
  type        = string
  default     = "ap-south-1b"
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# ── Frontend (Public) ────────────────────────────────────────────────────────
variable "frontend_subnet_a_cidr" {
  description = "CIDR for frontend public subnet in AZ-A"
  type        = string
  default     = "10.0.1.0/24"
}

variable "frontend_subnet_b_cidr" {
  description = "CIDR for frontend public subnet in AZ-B"
  type        = string
  default     = "10.0.2.0/24"
}

# ── Containerization (Private) ───────────────────────────────────────────────
variable "container_subnet_a_cidr" {
  description = "CIDR for containerization private subnet in AZ-A"
  type        = string
  default     = "10.0.3.0/24"
}

variable "container_subnet_b_cidr" {
  description = "CIDR for containerization private subnet in AZ-B"
  type        = string
  default     = "10.0.4.0/24"
}

# ── Backend (Private) ────────────────────────────────────────────────────────
variable "backend_subnet_a_cidr" {
  description = "CIDR for backend private subnet in AZ-A"
  type        = string
  default     = "10.0.5.0/24"
}

variable "backend_subnet_b_cidr" {
  description = "CIDR for backend private subnet in AZ-B"
  type        = string
  default     = "10.0.6.0/24"
}

variable "project_name" {
  description = "Name prefix applied to all resources"
  type        = string
  default     = "three-tier"
}
