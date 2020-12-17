resource "aws_elastic_beanstalk_environment" "tf_alb_env" {
  name = "tf-alb-${var.env_name}-${var.env_type}"
  cname_prefix = "tf-alb-${var.env_name}-${var.env_type}"
  application = var.application
  solution_stack_name = "64bit Amazon Linux 2 v5.2.3 running Node.js 12"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "IamInstanceProfile"
    value = "aws-elasticbeanstalk-ec2-role"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "InstanceType"
    value = var.instance_type
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name = "LoadBalancerType"
    value = "application"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name = "LoadBalancerIsShared"
    value = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name = "Port"
    value = "80"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment:process:default"
    name = "Protocol"
    value = "HTTP"
  }

  setting {
    namespace = "aws:elbv2:listener:443"
    name = "Rules"
    value = "default"
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name = "SharedLoadBalancer"
    value = var.load_balancer_id
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name = "ManagedSecurityGroup"
    value = var.security_group_id
  }

  setting {
    namespace = "aws:elbv2:loadbalancer"
    name = "SecurityGroups"
    value = var.security_group_id
  }
}
