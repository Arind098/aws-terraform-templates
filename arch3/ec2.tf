#######
# Web #
#######

resource "aws_elb" "elb-external" {
  name = "terraform-elb-internet-facing"
  security_groups = ["${aws_security_group.web-elb-sg.id}"]
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
    Name = "Web ELB"
  }
}

resource "aws_launch_configuration" "web-cluster" {
  image_id= "ami-0ff8a91507f77f867"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.web-instance.id}"]
  key_name = "demo"
  user_data = "${data.template_file.web-user-data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web-scale-group" {
  launch_configuration = "${aws_launch_configuration.web-cluster.name}"
  vpc_zone_identifier       = [ "${aws_subnet.public-1.id}", "${aws_subnet.public-2.id}" ]
  min_size = 2
  max_size = 4
  desired_capacity = 2
  enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]
  metrics_granularity="1Minute"
  load_balancers= [ "${aws_elb.elb-external.id}" ]
  health_check_type="ELB"
  tags {
    key = "Name"
    value = "web"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_policy" "web-autopolicy-up" {
  name = "terraform-autoplicy"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.web-scale-group.name}"
}

resource "aws_cloudwatch_metric_alarm" "web-cpualarm-up" {
  alarm_name = "terraform-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "60"

  dimensions {
  AutoScalingGroupName = "${aws_autoscaling_group.web-scale-group.name}"
  }

  alarm_description = "This metric monitor EC2 instance cpu utilization"
  alarm_actions = ["${aws_autoscaling_policy.web-autopolicy-up.arn}"]
}

#
resource "aws_autoscaling_policy" "web-autopolicy-down" {
  name = "terraform-autoplicy-down"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.web-scale-group.name}"
}

resource "aws_cloudwatch_metric_alarm" "web-cpualarm-down" {
  alarm_name = "terraform-alarm-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "10"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.web-scale-group.name}"
  }

  alarm_description = "This metric monitor EC2 instance cpu utilization"
  alarm_actions = ["${aws_autoscaling_policy.web-autopolicy-down.arn}"]
}

#######
# App #
#######

resource "aws_elb" "elb-internal" {
  name = "terraform-elb-internal"
  security_groups = ["${aws_security_group.app-elb-sg.id}"]
  subnets         = [ "${aws_subnet.private-1.id}", "${aws_subnet.private-2.id}" ]
  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }
  listener {
    instance_port = 8080
    instance_protocol = "http"
    lb_port = 8080
    lb_protocol = "http"
  }

  health_check {
    healthy_threshold = 5
    unhealthy_threshold = 3
    timeout = 5
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

resource "aws_launch_configuration" "app-cluster" {
  image_id= "ami-0ff8a91507f77f867"
  instance_type = "t2.micro"
  security_groups = ["${aws_security_group.app-instance.id}"]
  key_name = "demo"
  user_data = "${data.template_file.web-user-data.rendered}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "app-scale-group" {
  launch_configuration = "${aws_launch_configuration.app-cluster.name}"
  vpc_zone_identifier       = [ "${aws_subnet.private-1.id}", "${aws_subnet.private-2.id}" ]
  min_size = 2
  max_size = 4
  desired_capacity = 2
  enabled_metrics = ["GroupMinSize", "GroupMaxSize", "GroupDesiredCapacity", "GroupInServiceInstances", "GroupTotalInstances"]
  metrics_granularity="1Minute"
  load_balancers= [ "${aws_elb.elb-internal.id}" ]
  health_check_type="ELB"
  tags {
    key = "Name"
    value = "app"
    propagate_at_launch = true
  }
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_autoscaling_policy" "app-autopolicy-up" {
  name = "terraform-autoplicy"
  scaling_adjustment = 1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.app-scale-group.name}"
}

resource "aws_cloudwatch_metric_alarm" "app-cpualarm-up" {
  alarm_name = "terraform-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "60"

  dimensions {
  AutoScalingGroupName = "${aws_autoscaling_group.app-scale-group.name}"
  }

  alarm_description = "This metric monitor EC2 instance cpu utilization"
  alarm_actions = ["${aws_autoscaling_policy.app-autopolicy-up.arn}"]
}

#
resource "aws_autoscaling_policy" "app-autopolicy-down" {
  name = "terraform-autoplicy-down"
  scaling_adjustment = -1
  adjustment_type = "ChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.app-scale-group.name}"
}

resource "aws_cloudwatch_metric_alarm" "app-cpualarm-down" {
  alarm_name = "terraform-alarm-down"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "120"
  statistic = "Average"
  threshold = "10"

  dimensions {
    AutoScalingGroupName = "${aws_autoscaling_group.app-scale-group.name}"
  }

  alarm_description = "This metric monitor EC2 instance cpu utilization"
  alarm_actions = ["${aws_autoscaling_policy.app-autopolicy-down.arn}"]
}

data "template_file" "web-user-data" {
  template = "${file("web-user-data.tpl")}"

  vars {
    elb_dns = "${aws_elb.elb-internal.dns_name}"
  }
}

data "template_file" "app-user-data" {
  template = "${file("web-user-data.tpl")}"
}