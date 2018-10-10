resource "aws_launch_configuration" "webcluster" {
  image_id= "ami-0ff8a91507f77f867"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.web-sg.id}"]
  key_name = "demo"
  user_data = "${file("user-data.sh")}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "scalegroup" {
  launch_configuration = "${aws_launch_configuration.webcluster.name}"
  vpc_zone_identifier       = [ "${aws_subnet.public-1.id}", "${aws_subnet.public-2.id}" ]
  min_size = 2
  max_size = 4
  desired_capacity = 2
  enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]
  metrics_granularity="1Minute"
  load_balancers= [ "${aws_elb.elb.id}" ]
  health_check_type="ELB"
  tags {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_policy" "autopolicy" {
  name = "terraform-autoplicy"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.scalegroup.name}"
}

resource "aws_cloudwatch_metric_alarm" "cpualarm" {
  alarm_name = "terraform-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "60"

  dimensions {
  AutoScalingGroupName = "${aws_autoscaling_group.scalegroup.name}"
  }

  alarm_description = "This metric monitor EC2 instance cpu utilization"
  alarm_actions = ["${aws_autoscaling_policy.autopolicy.arn}"]
}

#
resource "aws_autoscaling_policy" "autopolicy-down" {
  name = "terraform-autoplicy-down"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.scalegroup.name}"
}

resource "aws_cloudwatch_metric_alarm" "cpualarm-down" {
  alarm_name = "terraform-alarm-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "10"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.scalegroup.name}"
  }

  alarm_description = "This metric monitor EC2 instance cpu utilization"
  alarm_actions = ["${aws_autoscaling_policy.autopolicy-down.arn}"]
}

resource "aws_security_group" "web-sg" {
  name = "security_group_for_web_server"
  vpc_id = "${aws_vpc.vpc.id}"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
lifecycle {
  create_before_destroy = true
  }
}

resource "aws_security_group_rule" "ssh" {
  security_group_id = "${aws_security_group.web-sg.id}"
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
}

resource "aws_security_group" "elbsg" {
  name = "security_group_for_elb"
  vpc_id = "${aws_vpc.vpc.id}"
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_elb" "elb" {
  name = "terraform-elb"
  security_groups = ["${aws_security_group.elbsg.id}"]
  subnets         = [ "${aws_subnet.public-1.id}", "${aws_subnet.public-2.id}" ]
  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }

  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags {
    Name = "terraform-elb"
  }
}

output "elb-dns" {
  value = "${aws_elb.elb.dns_name}"
}