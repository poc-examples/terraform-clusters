terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.20.0"
    }
    rhcs = {
      version = ">= 1.6.0"
      source  = "terraform-redhat/rhcs"
    }
  }
}

provider "rhcs" {
  token = var.offline_token
  url   = var.url
}

provider "aws" {
  region = var.region
  ignore_tags {
    key_prefixes = ["kubernetes.io/"]
  }
}
