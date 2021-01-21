variable "csr_ami_id" {
  type    = string
  default = ""
}

variable "instance_size" {
  type    = string
  default = "t2.medium"
}

variable "default_tags" {
  type    = map(any)
  default = {}
}

variable "name_prefix" {
  type    = string
  default = ""
}

variable "key_pair" {
  type = string
  default = ""
}