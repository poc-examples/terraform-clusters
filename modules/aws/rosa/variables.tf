variable "ocm_environment" {
    description = "The environment of the OpenShift Cluster Manager (OCM)"
    type        = string
    default     = "production"
}

variable "additional_tags" {
    description = "Additional tags to apply to resources"
    type        = map(string)
    default     = {}
}

variable "path" {
    description = "Path for the IAM roles"
    type        = string
    default     = "/service-role/"
}

variable "worker_node_replicas" {
    description = "Number of worker node replicas"
    type        = number
    default     = 2
}

variable "machine_type" {
    description = "The EC2 instance type for worker nodes"
    type        = string
    default     = "m5.xlarge"
}

variable "vpc_cidr_block" {
    description   = "CIDR block for the VPC"
    type          = string
    default       = "10.0.0.0/16"
}

variable "url" {
    description = "The URL for the RHCS provider"
    type        = string
    default     = "https://api.openshift.com"
}

variable "region" {
    description = "The AWS Region"
    type        = string
    default     = "us-east-2"
}

variable "offline_token" {
    description = "RHCS offline token for authentication"
    type        = string
}

variable "admin_credentials" {
    description = "The openshift admin credentials"
    type        = map(string)
}

variable "rosa_openshift_version" {
    description = "The version of OpenShift to deploy"
    type        = string
}

variable "cluster_name" {
    description = "The name of the OpenShift ROSA cluster"
    type        = string
}