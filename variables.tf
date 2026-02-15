variable "ssh_public_key_provision" {
  description = "SSH public key to access provisioner"
  type        = string
}
variable "ssh_public_key_tunnel" {
  description = "SSH public key to access tunnel host to docker-machine"
  type        = string
}
