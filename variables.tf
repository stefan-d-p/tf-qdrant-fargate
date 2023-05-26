# Networking Variables

variable "aws_az" {
  type        = string
  description = "AWS Availability Zone"
  default     = "eu-central-1a"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC Subnet Range"
  default     = "10.1.10.0/26"
}

variable "public_subnet_cidr" {
  type        = string
  description = "Public Subnet Range"
  default     = "10.1.10.0/28"
}