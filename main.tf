module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.63.0"

  name = "${var.name_prefix}-vpc"
  cidr = "10.128.0.0/16"

  azs             = ["us-west-1a"]
  private_subnets = ["10.128.10.0/24", "10.128.20.0/24"]
  public_subnets  = [ "10.128.30.0/24"]

  enable_nat_gateway = false
  create_igw = true

  tags = {
    Terraform = "true"
    Lab_ID    = var.name_prefix
  }
}

## Router 1
data "aws_ami" "amazon_linux_image" {
  most_recent = true
  owners      = ["679593333241"]

  filter {
    name   = "name"
    values = ["cisco-CSR-.16.09.02-BYOL*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "csr" {
  ami           = var.csr_ami_id == "" ? data.aws_ami.amazon_linux_image.id : var.csr_ami_id
  instance_type = var.instance_size
  key_name      = var.key_pair != "" ? var.key_pair : null

  network_interface {
    network_interface_id = aws_network_interface.router_1_eth0.id
    device_index         = 0
  }

  tags = merge(map("Name", "${var.name_prefix}csr"), var.default_tags)
}

resource "aws_network_interface" "router_1_eth0" {
  subnet_id   = module.vpc.public_subnets[0]
  security_groups = [aws_security_group.csr_mgmt.id]
  private_ips = ["10.128.30.10"]

  tags = merge(map("Name", "${var.name_prefix}router_1_eth0"), var.default_tags)
}

resource "aws_eip" "f5_mgmt_ip" {
  vpc                       = true
  network_interface         = aws_network_interface.router_1_eth0.id
  associate_with_private_ip = "10.128.30.10"

  tags = merge(map("Name", "${var.name_prefix}router_1_eth0"), var.default_tags)

  depends_on = [aws_instance.csr]
}

resource "aws_security_group" "csr_mgmt" {
  name   = "${var.name_prefix}csr-mgmt"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}