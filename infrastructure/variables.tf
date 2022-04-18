
variable "message_collection_name" {}
variable "docdb_admin_name" {
  sensitive = true
}
variable "twilio_token" {
  sensitive = true
}
variable "twilio_sid" {
  sensitive = true
}
variable "twilio_from_number" {
  sensitive = true
}

variable "backend_bucket" {
  sensitive = true
}


