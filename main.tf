
# Define a VPC (Virtual Private Cloud)
resource "aws_vpc" "prod-vpc" {
  cidr_block = "10.0.0.0/16"
  #enable_dns_support = true
  #enable_dns_hostnames = true
  tags = {
    Name = "production"
  }
}

# Define a Subnet within the VPC
resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = var.subnet_prefix[0].cidr_block
  availability_zone = "us-east-1a" # Bölgeyi ihtiyaca göre değiştirin
  #map_public_ip_on_launch = true
  tags = {
    Name = var.subnet_prefix[0].name
  }
}
resource "aws_subnet" "subnet-2" {
  vpc_id            = aws_vpc.prod-vpc.id
  cidr_block        = var.subnet_prefix[1].cidr_block
  availability_zone = "us-east-1a" # Bölgeyi ihtiyaca göre değiştirin
  #map_public_ip_on_launch = true
  tags = {
    Name = var.subnet_prefix[1].name
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-route-table.id
}
# Create an Internet Gateway to allow traffic to/from the internet
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.prod-vpc.id
  tags = {
    Name = "main-gateway"
  }
}
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.prod-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Prod"
  }
}


# Create an EC2 instance (web server)
resource "aws_instance" "web_server-instance" {
  ami           = "ami-0453ec754f44f9a4a" # Ubuntu 18.04 AMI ID'si (bunu kendi bölgenize uygun olarak değiştirebilirsiniz)
  instance_type = "t2.micro"
  #subnet_id         = aws_subnet.subnet-1.id
  availability_zone = "us-east-1a"
  key_name          = "test_002" # SSH anahtarınızın ismi

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }
  user_data = <<-EOF
                #!/bin/bash
                sudo dnf update -y
                sudo dnf install httpd -y
                sudo systemctl start httpd
                sudo bash -c 'echo your very first web server > /var/www/html/index.html'
                EOF
  tags = {
    Name = "web-server"
  }

  # Optionally, assign a public IP address to the instance
  #associate_public_ip_address = true
}

# Create a security group for the EC2 instance
resource "aws_security_group" "web_sg" {
  name        = "web-sg"
  description = "Allow inbound HTTP and SSH"
  vpc_id      = aws_vpc.prod-vpc.id

  # Allow SSH access (port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow HTTPS access (port 443)
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow HTTP access (port 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.web_sg.id]


}
resource "aws_eip" "one" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on                = [aws_instance.web_server-instance]
}
# Output the public IP address of the EC2 instance
output "web_server_public_ip" {
  value = aws_eip.one.public_ip
}
