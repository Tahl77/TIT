output "dev_machine_public_ip" {
  description = "Public IP of the development machine"
  value       = aws_instance.dev_machine.public_ip
}

output "dev_machine_ssh_command" {
  description = "SSH command to connect to the development machine"
  value       = "ssh -i ~/.ssh/tit-dev-machine ec2-user@${aws_instance.dev_machine.public_ip}"
}

output "dev_machine_public_dns" {
  description = "Public DNS of the development machine"
  value       = aws_instance.dev_machine.public_dns
}