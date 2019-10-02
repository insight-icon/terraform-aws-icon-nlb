data "aws_caller_identity" "this" {}
data "aws_region" "current" {}

terraform {
  required_version = ">= 0.12"
}

locals {
  name = var.name
  common_tags = {
    "Terraform" = true
    "Environment" = var.environment
  }

  tags = merge(var.tags, local.common_tags)
}

resource "aws_route53_record" "this" {
  zone_id = var.zone_id

  name = format("%s.%s.", local.name, var.domain_name)
  type = "A"

  # AWS recommends their special "alias" records for NLBs
  alias {
    name = aws_lb.this.dns_name
    zone_id = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}


resource "aws_eip" "this" {}

# Network Load Balancer for apiservers and ingress
resource "aws_lb" "this" {
  name = "${local.name}-nlb"
  load_balancer_type = "network"
  internal = false

  subnets = var.public_subnets

//  subnet_mapping {
//    subnet_id     = var.public_subnets
//    allocation_id = aws_eip.this.id
//  }

  enable_cross_zone_load_balancing = true
}

resource "aws_lb_listener" "prep" {
  load_balancer_arn = aws_lb.this.arn
  protocol = "TCP"
  port = 7100

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.sentries.arn
  }
}

# Forward HTTP ingress traffic to workers
resource "aws_lb_listener" "citizen" {
  load_balancer_arn = aws_lb.this.arn
  protocol = "TCP"
  port = 9000

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.citizen.arn
  }
}

# Target group of sentries
resource "aws_lb_target_group" "sentries" {
  name = "${local.name}-sentries"
  vpc_id = var.vpc_id
  target_type = "instance"

  protocol = "TCP"
  port = 7100

  # TCP health check for apiserver
  health_check {
    protocol = "TCP"
    port = 7100

    # NLBs required to use same healthy and unhealthy thresholds
    healthy_threshold = 3
    unhealthy_threshold = 3

    # Interval between health checks required to be 10 or 30
    interval = 10
  }
}

resource "aws_lb_target_group" "citizen" {
  name = "citizen"
  vpc_id = var.vpc_id
  target_type = "instance"

  protocol = "TCP"
  port = 9000

  # TCP health check for apiserver
  health_check {
    protocol = "TCP"
    port = 9000

    # NLBs required to use same healthy and unhealthy thresholds
    healthy_threshold = 3
    unhealthy_threshold = 3

    # Interval between health checks required to be 10 or 30
    interval = 10
  }
}

resource "aws_autoscaling_attachment" "sentries" {
  autoscaling_group_name = var.sentry_autoscaling_group_id
  alb_target_group_arn = aws_lb_target_group.sentries.arn
}

resource "aws_autoscaling_attachment" "citizen" {
  autoscaling_group_name = var.citizen_autoscaling_group_id
  alb_target_group_arn = aws_lb_target_group.citizen.arn
}
