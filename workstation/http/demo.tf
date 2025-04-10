terraform {
  backend "http" {
    address = "http://localhost:5000/terraform_state/4cdd0c76-d78b-11e9-9bea-db9cd8374f3a"
    lock_address = "http://localhost:5000/terraform_lock/4cdd0c76-d78b-11e9-9bea-db9cd8374f3a"
    lock_method = "PUT"
    unlock_address = "http://localhost:5000/terraform_lock/4cdd0c76-d78b-11e9-9bea-db9cd8374f3a"
    unlock_method = "DELETE"
  }
}

provider "aws" {
  profile    = "default"
  region     = "us-east-1"
  version    = "~> 2.27"
}

resource "aws_instance" "web_server" {
  # Ubuntu 20.04 LTS HVM, find your AMI ID for Ubuntu at https://cloud-images.ubuntu.com/locator/ec2/
  ami           = "ami-0de267fcccc5a245a"
  instance_type = "t1.micro"
  key_name      = "id_aws"
  root_block_device {
    delete_on_termination = true
  }
}
