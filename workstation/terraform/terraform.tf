terraform {
  required_version = ">= 1.0.0"
  #   backend "local" {
  #     path = "terraform.tfstate"
  #   }
  backend "s3" {
    bucket = "terraform-state-a0406"
    key    = "certlab/aws_infra"
    region = "us-west-2"

    #    #    dynamodb_table = "terraform-locks"
    #    #    encrypt        = true
  }
  #backend "http" {
  #  address        = "http://localhost:5000/terraform_state/4cdd0c76-d78b-11e9-9bea-db9cd8374f3a"
  #  lock_address   = "http://localhost:5000/terraform_lock/4cdd0c76-d78b-11e9-9bea-db9cd8374f3a"
  #  lock_method    = "PUT"
  #  unlock_address = "http://localhost:5000/terraform_lock/4cdd0c76-d78b-11e9-9bea-db9cd8374f3a"
  #  unlock_method  = "DELETE"
  #}
  #backend "remote" {
  #  hostname     = "app.terraform.io"
  #  organization = "PIETWINS-training"
  #
  #    workspaces {
  #      name = "mijn-aws-app"
  #    }
  #  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.5"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.1.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.1.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 3.1.0"
    }
  }
}
