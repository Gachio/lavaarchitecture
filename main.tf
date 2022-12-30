
provider "aws" {
	region = "us-east-2"
}

/*
resource "aws_instance" "lava" {
	ami = "ami-0c55b159cbfafe1f0"
	instance_type = "t2.micro"
	vpc_security_group_ids = [aws_security_group.instance.id]

	user_data = <<-EOF
				#!/bin/bash
				echo "Hello, World" > index.html
				nohup busybox httpd-f -p ${var.server_port} &
				EOF

	tags = {
		Name = "lava-identity"
	}
}


resource "aws_security_group" "instance" {
	name = "lava-identity-instance"

	ingress {
		from_port = var.server_port
		to_port = var.server_port
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

variable "server_port" {
	description = "The port the server will use for HTTP requests"
	type = number
}

output "public_ip" {
	value = aws_instance.lava.public_ip
	description = "The public IP address of the web server"
}

*/

resource "aws_security_group" "instance" {
	name = "lava-identity-instance"

	ingress {
		from_port = 8080
		to_port = 8080
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
}

resource "aws_launch_template" "lava" {
	image_id = "ami-0c55b159cbfafe1f0"
	instance_type = "t2.micro"
	#security_groups = [aws_security_group.alb.id]
	vpc_security_group_ids = [aws_security_group.instance.id]

	user_data = <<-EOF
				#!/bin/bash -ex
				echo "Hello, World" > index.html
				nohup busybox httpd-f -p ${8080} &
				EOF

# Required when using a launch configuration with an auto scaling group.
# https://www.terraform.io/docs/providers/aws/r/launch_configuration.html

	lifecycle {
		create_before_destroy = true
	}

}


data "aws_vpc" "lava" {
	default = true
}

data "aws_subnet_ids" "lava" {
	vpc_id = data.aws_vpc.lava.id
}


resource "aws_autoscaling_group" "lava" {
	#launch_configuration = aws_launch_configuration.lava.name
	vpc_zone_identifier = data.aws_subnet_ids.lava.ids

	target_group_arns = [aws_lb_target_group.asg.arn]
	health_check_type = "ELB"

	min_size = 2
	max_size = 5

	tag {
		key = "Name"
		value = "terraform-asg-lava"
		propagate_at_launch = true
	}

	launch_template {
		id = aws_launch_template.lava.id
	}
}

resource "aws_lb" "lava" {
	name = "terraform-asg-lava"
	load_balancer_type = "application"
	subnets = data.aws_subnet_ids.lava.ids
	security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
	load_balancer_arn = aws_lb.lava.arn
	port = 80
	protocol = "HTTP"

	default_action {
		type = "fixed-response"

		fixed_response {
			content_type = "text/plain"
			message_body = "404: page not found"
			status_code = 404
		}
	}
}

resource "aws_lb_listener_rule" "asg" {
	listener_arn = aws_lb_listener.http.arn
	priority = 100

	action {
    	type = "forward"
    	target_group_arn = aws_lb_target_group.asg.arn
  }

  condition {
    path_pattern {
      values = ["/static/*"]
    }
  }
}

resource "aws_security_group" "alb" {
	name = "lava-identity-alb"

	# Allow inbound HTTP requests
	ingress {
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}

	# Allow all outbound requests
	egress {
		from_port = 0
		to_port = 0
		protocol = "-1"
		cidr_blocks = ["0.0.0.0/0"]
	}

}


resource "aws_lb_target_group" "asg" {
	name = "lava-identity-asg"
	port = 8080
	protocol = "HTTP"
	vpc_id = data.aws_vpc.lava.id

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


output "alb_dns_name" {
	value = aws_lb.lava.dns_name
	description = "The domain name of the load balancer"
}