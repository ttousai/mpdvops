provider "aws" {
  region = "us-east-1"
}

# Choose AMI
data "aws_ami" "ubuntu_img" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Generate keys for SSH and SSL certificates
resource "tls_private_key" "cert" {
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "cert" {
  key_algorithm   = "RSA"
  private_key_pem = "${tls_private_key.cert.private_key_pem}"

  subject {
    common_name  = "acme.com"
    organization = "ACME Examples, Inc"
  }

  validity_period_hours = 12

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

# SSH public key
resource "aws_key_pair" "ops" {
  key_name   = "ops"
  public_key = "${tls_private_key.cert.public_key_openssh}"
}

# Self signed certificate
resource "aws_acm_certificate" "cert" {
  private_key      = "${tls_private_key.cert.private_key_pem}"
  certificate_body = "${tls_self_signed_cert.cert.cert_pem}"
}

# The web server
resource "aws_instance" "web" {
  ami           = "${data.aws_ami.ubuntu_img.id}"
  availability_zone = "us-east-1a"
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.ops.id}"
  security_groups = ["${aws_security_group.allow-ssh.name}", "${aws_security_group.allow-lb-sg.name}"]

  tags = {
    Name = "webserver"
  }

  # Run application setup scripts
  provisioner "file" {
    source      = "../src"
    destination = "/tmp"
  
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key   = "${tls_private_key.cert.private_key_pem}"
    }
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/src/run.sh",
      "/tmp/src/run.sh",
    ]
  
    connection {
      type     = "ssh"
      user     = "ubuntu"
      private_key   = "${tls_private_key.cert.private_key_pem}"
    }
  }
}

# Setup ELB http(s) load balancer
resource "aws_elb" "web-lb" {
  name               = "web-lb"
  availability_zones = ["us-east-1a"]
  security_groups  = ["${aws_security_group.lb-sg.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  listener {
    instance_port      = 80
    instance_protocol  = "http"
    lb_port            = 443
    lb_protocol        = "https"
    ssl_certificate_id = "${aws_acm_certificate.cert.id}"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 10
  }

  instances = ["${aws_instance.web.id}"]

  tags = {
    Name = "web-lb"
  }
}

# Setup security groups
resource "aws_security_group" "allow-ssh" {
  name        = "allow-ssh"
  description = "Allow all inbound SSH traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "lb-sg" {
  name        = "allow-public-http"
  description = "Allow public HTTP"

  ingress {
    from_port   = 80 
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "allow-lb-sg" {
  name        = "allow-lb-sg"
  description = "Allow LB SG"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = ["${aws_security_group.lb-sg.id}"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

output "lb_address" {
  value = "${aws_elb.web-lb.dns_name}"
}
