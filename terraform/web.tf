provider "aws" {
  region = "us-east-1"
}

# webserver
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

resource "aws_key_pair" "ops" {
  key_name   = "ops"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCoQJU40y0SSKPqOdrcLbIkMXC6fnPEwmmjcKs+AjSc4vAU5ZkSILFJvXIV+UvAqZhEVviqVi3tpB5TWpraFNHiHtneITcZQy3JK71H0Jw9bA5PL9gf7w/Lq4YYDIHEEPU0wseAD3wKU+4HT4wWnaw55i6CMq3ERYfze8c1HD5NOITncZ4jaHMMjTgx8hlNhwYIHRWll7xWA0ExVbr16b/iq7MCX8hPrMg7xzc+Z6k73LTV4WIwfd7ApiGtztqNHdXpLbRcxNDeE24pZ588L8eS6VfFJUeLrxxmxa6BNbEiRtUotbEUyZhTkOq1CA5n6uVaSyMcBvL0DqkbpCqrruuD ops"
}

resource "aws_instance" "web" {
  ami           = "${data.aws_ami.ubuntu_img.id}"
  availability_zone = "us-east-1a"
  instance_type = "t2.micro"
  # user_data = "${file("init/userdata")}"
  key_name = "${aws_key_pair.ops.id}"
  security_groups = ["${aws_security_group.allow-ssh.name}", "${aws_security_group.allow-lb-sg.name}"]

  tags = {
    Name = "webserver"
  }

  provisioner "file" {
    source      = "../src"
    destination = "/tmp"
  
    connection {
      type     = "ssh"
      agent    = true
      user     = "ubuntu"
    }
  }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/src/run.sh",
      "/tmp/src/run.sh",
    ]
  
    connection {
      type     = "ssh"
      agent    = true
      user     = "ubuntu"
    }
  }
}

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

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:5000/"
    interval            = 10
  }

  instances = ["${aws_instance.web.id}"]

  tags = {
    Name = "web-lb"
  }
}

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
    from_port   = 5000
    to_port     = 5000
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
