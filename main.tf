## Shared
locals {
  csr_instance_tags = {
    ansible_group = "routers"
  }
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.63.0"

  name = "${var.name_prefix}vpc"
  cidr = "10.128.0.0/16"

  azs             = ["us-west-1a"]
  private_subnets = ["10.128.10.0/24", "10.128.20.0/24"]
  public_subnets  = ["10.128.30.0/24"]

  enable_nat_gateway = false
  create_igw         = true

  tags = {
    Terraform = "true"
    Lab_ID    = var.name_prefix
  }
}

resource "random_password" "admin_password" {
  length  = 16
  special = false
}

resource "local_file" "foo" {
  content  = random_password.admin_password.result
  filename = "${path.module}/playbooks/credentials"
}

data "template_file" "user_data" {
  template = file("${path.module}/templates/user_data.tpl")

  vars = {
    admin_password = random_password.admin_password.result
  }
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

resource "aws_security_group" "r_to_r" {
  name   = "${var.name_prefix}r-to-r"
  vpc_id = module.vpc.vpc_id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = module.vpc.private_subnets_cidr_blocks
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

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

## Router 1
resource "aws_instance" "csr_1" {
  ami           = var.csr_ami_id == "" ? data.aws_ami.amazon_linux_image.id : var.csr_ami_id
  instance_type = var.csr_instance_size
  key_name      = var.key_pair != "" ? var.key_pair : null
  user_data     = data.template_file.user_data.rendered

  network_interface {
    network_interface_id = aws_network_interface.csr_1_Ge1.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.csr_1_Ge2.id
    device_index         = 1
  }

  tags = merge(map("Name", "${var.name_prefix}csr1"), local.csr_instance_tags, var.default_tags)
}

resource "aws_network_interface" "csr_1_Ge1" {
  subnet_id       = module.vpc.public_subnets[0]
  security_groups = [aws_security_group.csr_mgmt.id]
  private_ips     = ["10.128.30.10"]

  tags = merge(map("Name", "${var.name_prefix}csr_1_Ge1"), var.default_tags)
}

resource "aws_network_interface" "csr_1_Ge2" {
  subnet_id       = module.vpc.private_subnets[0]
  security_groups = [aws_security_group.r_to_r.id]
  private_ips     = ["10.128.10.10"]

  tags = merge(map("Name", "${var.name_prefix}csr_1_Ge2"), var.default_tags)
}

resource "aws_eip" "csr_1_mgmt" {
  vpc                       = true
  network_interface         = aws_network_interface.csr_1_Ge1.id
  associate_with_private_ip = tolist(aws_network_interface.csr_1_Ge1.private_ips)[0]

  tags = merge(map("Name", "${var.name_prefix}csr_1_mgmt"), var.default_tags)

  depends_on = [aws_instance.csr_1]
}

## Router 2
resource "aws_instance" "csr_2" {
  ami           = var.csr_ami_id == "" ? data.aws_ami.amazon_linux_image.id : var.csr_ami_id
  instance_type = var.csr_instance_size
  key_name      = var.key_pair != "" ? var.key_pair : null
  user_data     = data.template_file.user_data.rendered

  network_interface {
    network_interface_id = aws_network_interface.csr_2_Ge1.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.csr_2_Ge2.id
    device_index         = 1
  }

  network_interface {
    network_interface_id = aws_network_interface.csr_2_Ge3.id
    device_index         = 2
  }

  tags = merge(map("Name", "${var.name_prefix}csr2"), local.csr_instance_tags, var.default_tags)
}

resource "aws_network_interface" "csr_2_Ge1" {
  subnet_id       = module.vpc.public_subnets[0]
  security_groups = [aws_security_group.csr_mgmt.id]
  private_ips     = ["10.128.30.11"]

  tags = merge(map("Name", "${var.name_prefix}csr_2_Ge1"), var.default_tags)
}

resource "aws_network_interface" "csr_2_Ge2" {
  subnet_id       = module.vpc.private_subnets[0]
  security_groups = [aws_security_group.r_to_r.id]
  private_ips     = ["10.128.10.11"]

  tags = merge(map("Name", "${var.name_prefix}csr_2_Ge2"), var.default_tags)
}

resource "aws_network_interface" "csr_2_Ge3" {
  subnet_id       = module.vpc.private_subnets[1]
  security_groups = [aws_security_group.r_to_r.id]
  private_ips     = ["10.128.20.11"]

  tags = merge(map("Name", "${var.name_prefix}csr_2_Ge3"), var.default_tags)
}

resource "aws_eip" "csr_2_mgmt" {
  vpc                       = true
  network_interface         = aws_network_interface.csr_2_Ge1.id
  associate_with_private_ip = tolist(aws_network_interface.csr_2_Ge1.private_ips)[0]

  tags = merge(map("Name", "${var.name_prefix}csr_1_mgmt"), var.default_tags)

  depends_on = [aws_instance.csr_2]
}

## Router 3
resource "aws_instance" "csr_3" {
  ami           = var.csr_ami_id == "" ? data.aws_ami.amazon_linux_image.id : var.csr_ami_id
  instance_type = var.csr_instance_size
  key_name      = var.key_pair != "" ? var.key_pair : null
  user_data     = data.template_file.user_data.rendered

  network_interface {
    network_interface_id = aws_network_interface.csr_3_Ge1.id
    device_index         = 0
  }

  network_interface {
    network_interface_id = aws_network_interface.csr_3_Ge2.id
    device_index         = 1
  }

  tags = merge(map("Name", "${var.name_prefix}csr3"), local.csr_instance_tags, var.default_tags)
}

resource "aws_network_interface" "csr_3_Ge1" {
  subnet_id       = module.vpc.public_subnets[0]
  security_groups = [aws_security_group.csr_mgmt.id]
  private_ips     = ["10.128.30.12"]

  tags = merge(map("Name", "${var.name_prefix}csr_3_Ge1"), var.default_tags)
}

resource "aws_network_interface" "csr_3_Ge2" {
  subnet_id       = module.vpc.private_subnets[1]
  security_groups = [aws_security_group.r_to_r.id]
  private_ips     = ["10.128.20.12"]

  tags = merge(map("Name", "${var.name_prefix}csr_3_Ge2"), var.default_tags)
}

resource "aws_eip" "csr_3_mgmt" {
  vpc                       = true
  network_interface         = aws_network_interface.csr_3_Ge1.id
  associate_with_private_ip = tolist(aws_network_interface.csr_3_Ge1.private_ips)[0]

  tags = merge(map("Name", "${var.name_prefix}csr_3_mgmt"), var.default_tags)

  depends_on = [aws_instance.csr_3]
}
