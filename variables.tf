variable "subnet_prefix" {
  type = list(object({
    cidr_block = string
    name       = string
  }))
}