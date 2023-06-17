provider "aws" {
  region = "us-east-2"

}

resource "aws_security_group" "instance" {
  ingress {
    description      = "Allow Port 8080"
    from_port        = var.server_port
    to_port          = var.server_port
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]

  }
  ingress {
    description      = "Allow Port 22 from my ip"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["81.107.12.13/32"]

  }
}

data "template_file" "init" {

  template = "${file("${path.module}/scripts/webserver.sh")}"
  vars = {
    server_port = var.server_port
  }
}

// cluster of web servers. aws_launch_config
resource "aws_launch_template" "example" {
  image_id               = "ami-0fb653ca2d3203ac1"
  instance_type          = "t2.micro"
  key_name               = "web_server"
  vpc_security_group_ids = [ aws_security_group.instance.id ]
  user_data =  base64encode(data.template_file.init.rendered)
  lifecycle {
    create_before_destroy = true
  }
}

data "aws_vpc" "default" {
  default = true
}

data aws_subnets "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}


// Auto scaling group.
resource "aws_autoscaling_group" "example" {

  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  launch_template {
    id = aws_launch_template.example.id
    version = "$Latest"
  }
  min_size = 2
  max_size = 10

  tag {
    key = "Name"
    value = "terraform-asg-example"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

}

// Load Balancer security group.
resource "aws_security_group" "lb_sg" {

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
}

// Load Balancer.

resource "aws_lb" "example" {
  name = "terraform-asg-example"
  load_balancer_type = "application"
  subnets = data.aws_subnets.default.ids
  security_groups = [aws_security_group.lb_sg.id]
}

// Load Balancer listener.

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "404: Page not found"
      status_code = 404
    }
  }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.asg.arn
  }

  condition {
    path_pattern {
      values = ["*"]
    }
  }
}

// Load Balancer Target group.
resource "aws_lb_target_group" "asg" {
  name = "terraform-asg-example"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200"
    interval = 15
    timeout = 3
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

// Load Balancer Listener rule.

// seucrity group for the load balancer



// Load Balancer DNS Name.


/*

resource "aws_instance" "example" {
  ami = "ami-0fb653ca2d3203ac1"
  instance_type = "ami-0fb653ca2d3203ac1"
  key_name = "web_server"
  vpc_security_group_ids = [aws_security_group.instance.id]
  user_data = <<-EOF
  #!/bin/bash
    exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
    echo "Hello World" > index.html
    nohup busybox httpd -f -p ${var.server_port} &
  EOF
  user_data_replace_on_change = true
  tags = {
    "Name" = "terraform-example"
  }
}
*/