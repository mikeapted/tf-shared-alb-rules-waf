provider "aws" {
  region = var.region
}

provider "external" {}

data "aws_vpc" "default" {
  default = true
} 

data "aws_subnet_ids" "default" {
  vpc_id = data.aws_vpc.default.id
}

resource "aws_security_group" "tf_alb_sg" {
  name        = "tf-alb-sg"
  description = "Allow HTTP inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from anywhere"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "tf-alb-sg"
  }
}

resource "aws_lb" "tf_alb_lb" {
  name               = "tf-alb-lb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.tf_alb_sg.id]
  subnets            = data.aws_subnet_ids.default.ids
}

resource "aws_lb_listener" "tf_alb_lb_http" {
  load_balancer_arn = aws_lb.tf_alb_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "tf_alb_lb_https" {
  load_balancer_arn = aws_lb.tf_alb_lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:493833316326:certificate/a72e042a-0c15-4a66-8c74-d8f399f811c4"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Fixed response content"
      status_code  = "200"
    }
  }
}

resource "aws_elastic_beanstalk_application" "tf_alb_app" {
  name = "tf-alb-app"
}

module "eb_env_alpha" {
  source   = "./modules/eb-env"

  env_name = "alpha"
  env_type = "dev"
  application = aws_elastic_beanstalk_application.tf_alb_app.name
  load_balancer_id = aws_lb.tf_alb_lb.arn
  security_group_id = aws_security_group.tf_alb_sg.id
}

module "eb_env_beta" {
  source   = "./modules/eb-env"

  env_name = "beta"
  env_type = "dev"
  application = aws_elastic_beanstalk_application.tf_alb_app.name
  load_balancer_id = aws_lb.tf_alb_lb.arn
  security_group_id = aws_security_group.tf_alb_sg.id

  depends_on = [module.eb_env_alpha]
}

data "external" "tg_arn_alpha" {
  program = ["sh", "${path.module}/get_target_groups.sh"]
  query = {
    eb_name = module.eb_env_alpha.name
    lb_arn = aws_lb.tf_alb_lb.arn
  }
}

data "external" "tg_arn_beta" {
  program = ["sh", "${path.module}/get_target_groups.sh"]
  query = {
    eb_name = module.eb_env_beta.name
    lb_arn = aws_lb.tf_alb_lb.arn
  }
}

resource "aws_lb_listener_rule" "alpha_auth_admin_allow" {
  listener_arn = aws_lb_listener.tf_alb_lb_https.arn
  priority = 10
  depends_on = [module.eb_env_beta]

  action {
    type             = "forward"
    target_group_arn = data.external.tg_arn_alpha.result.arn
  }

  condition {
    host_header {
      values = [var.domain_name]
    }
  }  

  condition {
    path_pattern {
      values = ["/auth/admin/*"]
    }
  }

  condition {
    source_ip {
      values = var.admin_cidrs
    }
  }
}

resource "aws_lb_listener_rule" "alpha_auth_admin_deny" {
  listener_arn = aws_lb_listener.tf_alb_lb_https.arn
  priority = 15
  depends_on = [module.eb_env_beta]

  action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Access Denied"
      status_code  = "403"
    }
  }

  condition {
    host_header {
      values = [var.domain_name]
    }
  }  

  condition {
    path_pattern {
      values = ["/auth/admin/*"]
    }
  }

  condition {
    source_ip {
      values = ["0.0.0.0/0"]
    }
  }
}

resource "aws_lb_listener_rule" "alpha_auth_allow" {
  listener_arn = aws_lb_listener.tf_alb_lb_https.arn
  priority = 20
  depends_on = [module.eb_env_beta]

  action {
    type             = "forward"
    target_group_arn = data.external.tg_arn_alpha.result.arn
  }

  condition {
    host_header {
      values = [var.domain_name]
    }
  }  

  condition {
    path_pattern {
      values = ["/auth/*"]
    }
  }
}

resource "aws_lb_listener_rule" "beta_allow" {
  listener_arn = aws_lb_listener.tf_alb_lb_https.arn
  priority = 25
  depends_on = [module.eb_env_beta]

  action {
    type             = "forward"
    target_group_arn = data.external.tg_arn_beta.result.arn
  }

  condition {
    host_header {
      values = [var.domain_name]
    }
  }  

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}