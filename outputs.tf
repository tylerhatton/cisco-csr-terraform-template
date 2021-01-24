output "csr_1_mgmt" {
  value = aws_eip.csr_1_mgmt.public_ip
}

output "csr_2_mgmt" {
  value = aws_eip.csr_2_mgmt.public_ip
}

output "csr_3_mgmt" {
  value = aws_eip.csr_3_mgmt.public_ip
}

output "admin_password" {
  value = random_password.admin_password.result
}
