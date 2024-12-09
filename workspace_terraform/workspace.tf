provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "tfmyec2" {
  ami = lookup(var.myami, terraform.workspace)
  instance_type = "${terraform.workspace == "dev" ? "t3a.medium" : "t2.micro"}"
  count = "${terraform.workspace == "prod" ? 3 : 1}"
  key_name = "test_002"
  tags = {
    Name = "${terraform.workspace}-server"
  }
}

variable "myami" {
  type = map(string)
  default = {
    default = "ami-01b799c439fd5516a"
    dev     = "ami-0583d8c7a9c35822c"
    prod    = "ami-04b70fa74e45c3917"
  }

  description = "in order of an Amazon Linux 2023 ami, Red Hat Enterprise Linux 9 ami, and Ubuntu Server 22.04 LTS ami's"
}