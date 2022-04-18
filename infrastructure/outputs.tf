output "url" {
  sensitive = true
  value = "mongodb://${aws_docdb_cluster.service.master_username}:${aws_docdb_cluster.service.master_password}@${aws_docdb_cluster.service.endpoint}:${aws_docdb_cluster.service.port}"
}

output "instanceUrl" {
  sensitive = false
  value = module.ec2_instance.public_dns
}
