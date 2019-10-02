variable "name" {
  description = "The name of the resource which is then used in a tag"
}

variable "environment" {
  description = "The environment that generally corresponds to the account you are deploying into."
}

variable "tags" {
  description = "Tags that are appended"
  type        = map(string)
}

variable "terraform_state_region" {
  description = "AWS region used for Terraform states"
}

variable "zone_id" {}
variable "domain_name" {}
variable "public_subnets" {
  type = list
}

variable "vpc_id" {}
variable "sentry_autoscaling_group_id" {}
variable "citizen_autoscaling_group_id" {}
