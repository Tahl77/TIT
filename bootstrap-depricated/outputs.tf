output "dev_machine_ip" {
  value = aws_instance.dev_machine.public_ip
}

output "ssh_command" {
  value = "ssh -i ~/.ssh/tit-dev-key ec2-user@${aws_instance.dev_machine.public_ip}"
}

output "application_url" {
  value = "http://${aws_instance.dev_machine.public_ip}"
}