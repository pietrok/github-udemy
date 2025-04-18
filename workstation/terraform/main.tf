# IaC Buildout for Terraform Associate Exam

/*
Name: IaC Buildout for Terraform Associate Exam
Description: AWS Infra Buildout
Account: Bhutan
*/

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Environment = terraform.workspace
      Owner       = "Coyote"
      Provisioned = "Terraform"
    }
  }
}
locals {
  team        = "api_mgmt_dev"
  application = "corp_api"
  server_name = "ec2-${var.environment}-api-${var.variables_sub_az}"

  service_name = "Automation"
  app_team     = "HaX0r Cloud Team"
  createdby    = "terrafart"
}


locals {
  # Common tags to be assigned to all resources
  common_tags = {
    Name      = lower(local.server_name)
    Owner     = lower(local.team)
    App       = lower(local.application)
    Service   = lower(local.service_name)
    AppTeam   = lower(local.app_team)
    CreatedBy = lower(local.createdby)
  }
}

locals {
  maximum = max(var.num_1, var.num_2, var.num_3)
  minimum = min(var.num_1, var.num_2, var.num_3, 44, 20)
}

#Retrieve the list of AZs in the current AWS region
data "aws_availability_zones" "available" {}
data "aws_region" "current" {}

#Define the VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = upper(var.vpc_name)
    Environment = upper(var.environment)
    Terraform   = upper("true")
    Region      = upper(data.aws_region.current.name)
  }
}

#Deploy the private subnets
resource "aws_subnet" "private_subnets" {
  for_each          = var.private_subnets
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, each.value)
  availability_zone = tolist(data.aws_availability_zones.available.names)[each.value]

  tags = {
    Name      = each.key
    Terraform = "true"
  }
}

#Deploy the public subnets
resource "aws_subnet" "public_subnets" {
  for_each                = var.public_subnets
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, each.value + 100)
  availability_zone       = tolist(data.aws_availability_zones.available.names)[each.value]
  map_public_ip_on_launch = true

  tags = {
    Name      = each.key
    Terraform = "true"
  }
}

#Create route tables for public and private subnets
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
    #nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name      = "demo_public_rtb"
    Terraform = "true"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    # gateway_id     = aws_internet_gateway.internet_gateway.id
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
  tags = {
    Name      = "demo_private_rtb"
    Terraform = "true"
  }
}

#Create route table associations
resource "aws_route_table_association" "public" {
  depends_on     = [aws_subnet.public_subnets]
  route_table_id = aws_route_table.public_route_table.id
  for_each       = aws_subnet.public_subnets
  subnet_id      = each.value.id
}

resource "aws_route_table_association" "private" {
  depends_on     = [aws_subnet.private_subnets]
  route_table_id = aws_route_table.private_route_table.id
  for_each       = aws_subnet.private_subnets
  subnet_id      = each.value.id
}

#Create Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "demo_igw"
  }
}

#Create EIP for NAT Gateway
resource "aws_eip" "nat_gateway_eip" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.internet_gateway]
  tags = {
    Name = "demo_igw_eip"
  }
}

#Create NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  depends_on    = [aws_subnet.public_subnets]
  allocation_id = aws_eip.nat_gateway_eip.id
  subnet_id     = aws_subnet.public_subnets["public_subnet_1"].id
  tags = {
    Name = "demo_nat_gateway"
  }
}

resource "aws_security_group" "my-new-security-group" {
  name        = "web_server_inbound"
  description = "Allow inbound traffic on tcp/443 and tcp/22"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "Allow 443 from the Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name    = "web_server_inbound"
    Purpose = "Intro to Resource Blocks Lab"
  }
}
#Create EC2 instance
# Terraform Data Block - To Lookup Latest Ubuntu 20.04 AMI Image
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    #    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-24.04-amd64-server-*"]
    #values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"]
}

# Terraform Resource Block - To Build EC2 instance in Public Subnet
#resource "aws_instance" "ubuntu_server" {
#  ami                         = data.aws_ami.ubuntu.id
#  instance_type               = "t3.micro"
#  subnet_id                   = aws_subnet.public_subnets["public_subnet_1"].id
#  vpc_security_group_ids      = [aws_security_group.vpc-ping.id, aws_security_group.ingress-ssh.id, aws_security_group.vpc-web.id]
#  associate_public_ip_address = true
#  key_name                    = aws_key_pair.generated.key_name
#  connection {
#    user        = "ubuntu"
#    private_key = tls_private_key.generated.private_key_pem
#    host        = self.public_ip
#  }
#
#  # Leave the first part of the block unchanged and create our `local-exec` provisioner
#  provisioner "local-exec" {
#    command = "chmod 600 ${local_file.private_key_pem.filename}"
#  }
#
#provisioner "remote-exec" {
#  inline = [
#    "sudo rm -rf /tmp",
#    "sudo git clone https://github.com/hashicorp/demo-terraform-101 /tmp",
#    "sudo sh /tmp/assets/setup-web.sh",
#  ]
#}

#  tags = {
#    #Name      = "Ubuntu Noble Numbat EC2 Server"
#    #Name      = "Ubuntu Jammy EC2 Server"
#    #Terraform = "HoL 7.15"
#    Name  = local.server_name
#    Owner = local.team
#    App   = local.application
#  }
#
#  lifecycle {
#    ignore_changes = [security_groups]
#  }
#}


#resource "aws_s3_bucket" "my-new-S3-bucket" {
#  bucket = "tf-test-bucket-piet-${random_id.randomness.hex}"
#
#  tags = {
#    Name    = "My S3 Bucket"
#    Purpose = "Intro to Resource Blocks Lab"
#  }
#}
#
#resource "aws_s3_bucket_ownership_controls" "my_new_bucket_ownership" {
#  bucket = aws_s3_bucket.my-new-S3-bucket.id

#  rule {
#    object_ownership = "BucketOwnerPreferred"
#  }
#}
#
#resource "aws_s3_bucket_acl" "my_new_bucket_acl" {
#  depends_on = [aws_s3_bucket_ownership_controls.my_new_bucket_ownership]
#
#  bucket = aws_s3_bucket.my-new-S3-bucket.id
#  acl    = "private"
#} 
#

data "aws_s3_bucket" "data_bucket" {
  bucket = "datalookup-bucket-pch2"
}

resource "aws_iam_policy" "policy" {
  name        = "data_bucket_policy"
  description = "Allow access to my bucket"
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*"
            ],
            "Resource": "${data.aws_s3_bucket.data_bucket.arn}"
        }
    ]
  })
}

resource "random_id" "randomness" {
  byte_length = 16
}

resource "aws_subnet" "variables-subnet" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = var.variables_sub_cidr
  availability_zone       = var.variables_sub_az
  map_public_ip_on_launch = var.variables_sub_auto_ip

  tags = {
    Name      = "sub-variables-${var.variables_sub_az}"
    Terraform = "true"
  }
}

resource "tls_private_key" "generated" {
  algorithm = "RSA"
}

/*resource "local_file" "private_key_pem" {
  content  = tls_private_key.generated.private_key_pem
  filename = "MyAWSKey.pem"
}*/

resource "aws_key_pair" "generated" {
  key_name   = "MyAWSKey"
  public_key = tls_private_key.generated.public_key_openssh

  lifecycle {
    ignore_changes = [key_name]
  }
}

# Security Groups

resource "aws_security_group" "ingress-ssh" {
  name   = "allow-all-ssh"
  vpc_id = aws_vpc.vpc.id
  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }
  // Terraform removes the default rule
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Security Group - Web Traffic
resource "aws_security_group" "vpc-web" {
  name        = "vpc-web-${terraform.workspace}"
  vpc_id      = aws_vpc.vpc.id
  description = "Web Traffic"
  ingress {
    description = "Allow Port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow Port 443"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all ip and ports outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "vpc-ping" {
  name        = "vpc-ping"
  vpc_id      = aws_vpc.vpc.id
  description = "ICMP for Ping Access"
  ingress {
    description = "Allow ICMP Traffic"
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow all ip and ports outboun"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Terraform Resource Block - To Build Web Server in Public Subnet
resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnets["public_subnet_1"].id
  security_groups             = [aws_security_group.vpc-ping.id, aws_security_group.ingress-ssh.id, aws_security_group.vpc-web.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.generated.key_name
  tags                        = local.common_tags
  connection {
    user        = "ubuntu"
    private_key = tls_private_key.generated.private_key_pem
    host        = self.public_ip
    #timeout     = "5m"
  }

  # Leave the first part of the block unchanged and create our `local-exec` provisioner
  /*provisioner "local-exec" {
    command = "chmod 600 ${local_file.private_key_pem.filename}"
  } */

  # provisioner "remote-exec" {
  #   inline = [
  #     "sudo rm -rf /tmp",
  #     "sudo git clone https://github.com/hashicorp/demo-terraform-101 /tmp",
  #     "sudo sh /tmp/assets/setup-web.sh",
  #   ]
  # }

  #tags = {
  #  Name        = local.server_name
  #  Owner       = local.team
  #  App         = local.application
  #  "Service"   = local.service_name
  #  "AppTeam"   = local.app_team
  #  "CreatedBy" = local.createdby


  lifecycle {
    ignore_changes = [security_groups]
  }

}

#resource "aws_instance" "aws_linux" {
#  instance_type = "t2.micro"
#
#ami = "ami-053a45fff0a704a47"
#
#}

#module "server" {
#  source    = "./modules/server"
#  ami       = data.aws_ami.ubuntu.id
#  size      = "t2.micro"
#  subnet_id = aws_subnet.public_subnets["public_subnet_3"].id
#  security_groups = [
#    aws_security_group.vpc-ping.id,
#    aws_security_group.ingress-ssh.id,
#    aws_security_group.vpc-web.id
#  ]
#}
#
#module "server_subnet_1" {
#  source      = "./modules/web_server"
#  ami         = data.aws_ami.ubuntu.id
#  key_name    = aws_key_pair.generated.key_name
#  user        = "ubuntu"
#  private_key = tls_private_key.generated.private_key_pem
#  subnet_id   = aws_subnet.public_subnets["public_subnet_1"].id
#  security_groups = [
#    aws_security_group.vpc-ping.id,
#    aws_security_group.ingress-ssh.id,
#    aws_security_group.vpc-web.id
#  ]
#}
#
resource "aws_subnet" "list_subnet" {
  for_each          = var.env
  vpc_id            = aws_vpc.vpc.id
  #cidr_block       = var.ip[var.environment]
  cidr_block        = each.value.ip
  #availability_zone = var.us-east-1-azs[0]
  availability_zone = each.value.az
}
#output "public_ip" {
#  value = module.server.public_ip
#}
#
#output "public_dns" {
#  value = module.server.public_dns
#}
#
#output "size" {
#  value = module.server.size
#}
#
#output "public_ip_subnet_1" {
#  value = module.server_subnet_1.public_ip
#}
#
#output "public_dns_subnet_1" {
#  value = module.server_subnet_1.public_dns
#}
#
#module "autoscaling" {
#  source = "terraform-aws-modules/autoscaling/aws"
#  #source = "github.com/terraform-aws-modules/terraform-aws-autoscaling"
#  version = "4.9.0"
#
#  # Autoscaling group
#  name = "mijn_asg"
#
#  vpc_zone_identifier = [aws_subnet.private_subnets["private_subnet_1"].id,
#    aws_subnet.private_subnets["private_subnet_2"].id,
#  aws_subnet.private_subnets["private_subnet_3"].id]
#  min_size         = 0
#  max_size         = 1
#  desired_capacity = 1
#
#  # Launch template
#  #launch_template_name = "mijn-launch-template"
#  use_lt    = true
#  create_lt = true
#  #launch_template_description = "Launch template for ASG"
#  #update_default_version      = true
#
#  image_id      = data.aws_ami.ubuntu.id
#  instance_type = "t3.micro"
#
#tags_as_map = {
#   Name = "Web EC2 Server 2"
# }

#tags = [
#  {
#    key                 = "Name"
#    value               = "Web EC2 Server 2"
#    propagate_at_launch = true
#  }
#]
#tags = {
# Name                    = "Web EC2 Server 2"
# propagate_at_launch     = true
# }
#}
#output "asg_group_size" {
#  value = module.autoscaling.autoscaling_group_max_size
#}

#module "s3-bucket" {
#  source = "terraform-aws-modules/s3-bucket/aws"
#  #version = "4.6.0"
#  version = "2.11.1"
#}
#
#output "s3_bucket_name" {
#  value = module.s3-bucket.s3_bucket_bucket_domain_name
#}

#module "vpc" {
#  source = "terraform-aws-modules/vpc/aws"
#  #version = "3.11.0"
#  version = ">4.0.0"
#  name    = "my-vpc-terraform"
#  cidr    = "10.0.0.0/16"
#
#  azs             = ["us-east-1a", "us-east-1b", "us-east-1c"]
#  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
#  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
#
#  enable_nat_gateway = true
#  enable_vpn_gateway = true
#
#  tags = {
#    Name        = "VPC From Module"
#    Terraform   = "true"
#    Environment = "dev"
#  }
#}

output "data-bucket-arn" {
  value = data.aws_s3_bucket.data_bucket.arn
}

output "max_value" {
  value = local.maximum
}

output "min_value" {
  value = local.minimum
}
