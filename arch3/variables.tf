variable "name" {
  description = "Name to be used on all the resources as identifier"
  default     = "model2"
}

variable "cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "A list of public subnets inside the VPC."
  default     = ["10.0.0.0/24","10.0.2.0/24"]
}

variable "private_subnets" {
  description = "A list of public subnets inside the VPC."
  default     = ["10.0.1.0/24","10.0.3.0/24"]
}
variable "azs" {
  description = "A list of Availability zones in the region"
  default     = ["us-east-1a", "us-east-1b"]
}

variable "map_public_ip_on_launch" {
  description = "should be false if you do not want to auto-assign public IP on launch"
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  default     = { "Terraform" = true }
}

variable "private_subnet_tags" {
  description = "Additional tags for the public subnets"
  default     = {}
}

variable "count" {
  default     = 2
}
