# Jump Server 
resource "aws_security_group" "demo-sg-public" {
  name        = "terraform-demo-public"
  vpc_id      = aws_vpc.demo.id

  # allow all 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # default to denied all ingress traffic 
}

# Add a entry to the security group to allow connection to 22 port from the internet 
resource "aws_security_group_rule" "demo-sgr" {
  cidr_blocks       = ["0.0.0.0/0"]
  from_port         = 22
  protocol          = "tcp"
  security_group_id = aws_security_group.demo-sg-public.id
  to_port           = 22
  type              = "ingress"
}

# Attach the insance to one of the public subnet 
resource "aws_network_interface" "demo-public" {
  subnet_id   = aws_subnet.demo-public[0].id

  security_groups = [aws_security_group.demo-sg-public.id]
}

# Setup this public key into the jump server for ssh service 
resource "aws_key_pair" "devops" {
  key_name   = "devops-key"
  public_key = "ssh-rsa rsa key here email@example.com"
}

# Use this image to boot the jump server 
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Launch the jump server instance 
resource "aws_instance" "demo-public" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"

  network_interface {
    network_interface_id = aws_network_interface.demo-public.id
    device_index         = 0
  }

  key_name               = "devops-key"
}
