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

  tags = merge(map("Name", "${var.name_prefix}csr"), var.default_tags)
}
