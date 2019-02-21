provider "aws" {
  "region" = "us-east"
  "availability_zone" = "1a"
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
  instance_type = "t2.micro"
  key_name = "${aws_key_pair.ops.id}"
  tags = {
    Name = "webserver"
  }
}
