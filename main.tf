provider "aws" {
  region = "${var.aws_region}"
}

resource "aws_vpc" "default" {
  cidr_block	= "${var.default_vpc_cidr}"
  
  tags = {
    Name = "Default VPC"
    env = "PROD"
  }
}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.default.id}"

  tags = {
    Name = "Default GW"
    env = "PROD"
  }
}

resource "aws_route" "internet_access" {
  route_table_id         = "${aws_vpc.default.main_route_table_id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.default.id}"
}

resource "aws_subnet" "default" {
  vpc_id                  = "${aws_vpc.default.id}"
  cidr_block              = "${var.default_subnet_cidr}"
  map_public_ip_on_launch = true


  tags = {
    Name = "Default Subnet"
    env = "PROD"
  }
}

resource "aws_security_group" "basic" {
  name        = "basic"
  description = "Basic Security Group"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port	= 8
    to_port	= 0
    protocol	= "icmp"
    cidr_blocks	= ["0.0.0.0/0"]
  }

  ingress {
    from_port	= 22
    to_port	= 22
    protocol	= "tcp"
    security_groups	= [
			"${aws_security_group.bastionhost.id}"
			]
  }

  ingress {
    from_port	= 8080
    to_port	= 8080
    protocol	= "tcp"
    cidr_blocks	= ["0.0.0.0/0"]
  }

  egress {
    from_port	= 80
    to_port	= 80
    protocol	= "tcp"
    cidr_blocks	= ["0.0.0.0/0"]
  }    

  egress {
    from_port	= 443
    to_port	= 443
    protocol	= "tcp"
    cidr_blocks	= ["0.0.0.0/0"]
  }    


  tags = {
    Name	= "basic"
    env		= "PROD"
  }
}

resource "aws_security_group" "bastionhost" {
  name		= "bastion"
  description	= "bastion host"
  vpc_id	= "${aws_vpc.default.id}"
  
  ingress {
    from_port	= 22
    to_port	= 22
    protocol 	= "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port	= 8
    to_port	= 0
    protocol	= "icmp"
    cidr_blocks	= ["0.0.0.0/0"]
  }
  
  egress {
    from_port		= 0
    to_port		= 0
    protocol		= -1
    cidr_blocks		=["0.0.0.0/0"]
  }

  tags = {
    Name	= "BastionHost"
    env		= "PROD"
  }
} 
resource "aws_key_pair" "jlowry" {
  key_name   = "John Lowry"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCc9cC2xs+EU8awpCf6eAY7S9IGqL6/r1LpV3r5Lo1NCE9gTPofk+ACMKhxnLRxUdqGs0aMA9k1HngJ5oE5PKp9DkE9ZIjryG7UhPfrvsTnU0Ak+Ltx0cXy/1NoWmMDSckCBdeqONRaxdi9kz6H3DCMeQD8Xu5KafWTlbLgdJveEaEDbWlKF0smpvKieeCW+iBjcqA2ZusDvaBKHQRa4CpcSWiI+fsoJXYItZXZFmNYmDiNL9P1bzwa7MSnHN7gRU2yJy6J3Mil69p3bKI347pxbBVUMBT2bSbj/OP6nr6yP85JF8jlJl7XekabqtRNnDW6rOGApufh/4etCh2yBOQ9"
}

resource "aws_instance" "bastion" {
  connection {
    user = "centos"
  }

  instance_type			= "t2.micro"
  ami				= "ami-0c2aba6c"
  key_name			= "${aws_key_pair.jlowry.id}"
  vpc_security_group_ids	= ["${aws_security_group.bastionhost.id}"]
  subnet_id			= "${aws_subnet.default.id}"


  tags	= {
    Name	= "bastion"
    env		= "PROD"
  }
}

resource "aws_instance" "jenkins" {
  connection {
    user = "centos"
  }

  instance_type			= "t2.micro"
  ami				= "ami-0c2aba6c"
  key_name			= "${aws_key_pair.jlowry.id}"
  vpc_security_group_ids	= ["${aws_security_group.basic.id}"]
  subnet_id			= "${aws_subnet.default.id}"


  tags	= {
    Name	= "jenkins"
    env		= "PROD"
  }
}
