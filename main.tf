provider "aws" {
    access_key = "${var.aws_access_key}"
    secret_key = "${var.aws_secret_key}"
    region = "${var.aws_region}"
}


resource "aws_vpc" "default" {
    cidr_block = "${var.vpc_cidr}"
    enable_dns_hostnames = true
    tags = {
        Name = "${var.vpc_name}"
	    Owner = "Deekshith"
	    environment = "${var.environment}"
    }
}

resource "aws_internet_gateway" "default" {
    vpc_id = "${aws_vpc.default.id}"
	tags = {
        Name = "${var.IGW_name}"
    }
}

resource "aws_subnet" "subnet1-public" {
    vpc_id = "${aws_vpc.default.id}"
    cidr_block = "${var.public_subnet1_cidr}"
    availability_zone = "us-east-2a"

    tags = {
        Name = "${var.public_subnet1_name}"
    }
}

resource "aws_subnet" "subnet2-public" {
    vpc_id = "${aws_vpc.default.id}"
    cidr_block = "${var.public_subnet2_cidr}"
    availability_zone = "us-east-2b"

    tags = {
        Name = "${var.public_subnet2_name}"
    }
}

resource "aws_subnet" "subnet3-public" {
    vpc_id = "${aws_vpc.default.id}"
    cidr_block = "${var.public_subnet3_cidr}"
    availability_zone = "us-east-2c"

    tags = {
        Name = "${var.public_subnet3_name}"
    }
	
}


resource "aws_route_table" "terraform-public" {
    vpc_id = "${aws_vpc.default.id}"

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.default.id}"
    }

    tags = {
        Name = "${var.Main_Routing_Table}"
    }
}

resource "aws_route_table_association" "terraform-public-a" {
    subnet_id = "${aws_subnet.subnet1-public.id}"
    route_table_id = "${aws_route_table.terraform-public.id}"
}

resource "aws_route_table_association" "terraform-public-b" {
    subnet_id = "${aws_subnet.subnet2-public.id}"
    route_table_id = "${aws_route_table.terraform-public.id}"
}
resource "aws_route_table_association" "terraform-public-c" {
    subnet_id = "${aws_subnet.subnet3-public.id}"
    route_table_id = "${aws_route_table.terraform-public.id}"
}
resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.default.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    }
  tags = {
    "Name" = "DeekshithSG"
  }
}

resource "aws_lb" "WEBLB" {
  name               = "DeekshithLB"
  internal           = false
  load_balancer_type = "network"
  subnets            = [
    aws_subnet.subnet1-public.id, 
    aws_subnet.subnet2-public.id, 
    aws_subnet.subnet3-public.id
  ]
  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "WEBTG" {
  name     = "DeekshithTG"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.default.id
}

resource "aws_lb_listener" "DeekshithLBListener" {
  load_balancer_arn = aws_lb.WEBLB.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.WEBTG.arn
  }
}


