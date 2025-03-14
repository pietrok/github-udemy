output "public_ip" {
  description = "This is the public IP of my web server"
  value = aws_instance.web.public_ip
}

output "public_dns" {
  value = aws_instance.web.public_dns
}

output "size" {
  description = "Size of server built with Server Module"
  value	      = aws_instance.web.instance_type
}
