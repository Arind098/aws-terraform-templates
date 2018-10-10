resource "aws_security_group" "elb" {
  name        = "PublicLoadBalancerSecurityGroup"
  description = "ELB for the web tier"
  vpc_id      = "${aws_vpc.vpc.id}"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# SSH and HTTP access
resource "aws_security_group" "web-sg" {
  name        = "terraform_example"
  description = "Used in the terraform"
  vpc_id      = "${aws_vpc.vpc.id}"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "web" {
  name = "model1-elb"
  subnets         = [ "${aws_subnet.public-1.id}", "${aws_subnet.public-2.id}" ]
  instances       = [ "${aws_instance.web-1.id}", "${aws_instance.web-2.id}" ]
  security_groups = ["${aws_security_group.elb.id}"]
  cross_zone_load_balancing   = true

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 5
    timeout             = 5
    target              = "HTTP:80/"
    interval            = 30
  }
}

resource "aws_instance" "web-1" {
  connection {
    # The web username for AMI
    user = "ec2-user"
  }

  instance_type = "t2.micro"
  ami = "ami-0ff8a91507f77f867"
  key_name = "demo"
  vpc_security_group_ids = ["${aws_security_group.web-sg.id}"]
  subnet_id = "${aws_subnet.public-1.id}"
  tags { Name= "Webserver 1" }
  user_data = "${file("user-data.sh")}"
  }

  resource "aws_instance" "web-2" {
  connection {
    # The web username for AMI
    user = "ec2-user"
  }

  instance_type = "t2.micro"
  ami = "ami-0ff8a91507f77f867"
  key_name = "demo"
  vpc_security_group_ids = ["${aws_security_group.web-sg.id}"]
  subnet_id = "${aws_subnet.public-2.id}"
  tags { Name= "Webserver 2" }
  user_data = "${file("user-data.sh")}"
  }
