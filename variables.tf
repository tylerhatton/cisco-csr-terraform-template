variable "csr_ami_id" {
  type    = string
  default = ""
}

variable "csr_instance_size" {
  type    = string
  default = "t2.medium"
}

variable "default_tags" {
  type    = map(any)
  default = {}
}

variable "name_prefix" {
  type    = string
  default = "csr-demo"
}

variable "key_pair" {
  type = string
  default = "hattont-desk-key-02"
}