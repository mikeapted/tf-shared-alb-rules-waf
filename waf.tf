resource "aws_wafv2_regex_pattern_set" "deny_eb_cname_regex" {
  name        = "eb-cnames"
  description = "EB CNAME regex pattern set"
  scope       = "REGIONAL"

  regular_expression {
    regex_string = "*.elasticbeanstalk.com"
  }

  regular_expression {
    regex_string = "*.elb.amazonaws.com"
  }
}

resource "aws_wafv2_web_acl" "deny_eb_cname_cal" {
  name  = "deny-eb-cname"
  scope = "REGIONAL"

  default_action {
    allow {}
  }

  rule {
    name     = "deny-eb-cname"
    priority = 1

    action {
      block {}
    }

    statement {
      regex_pattern_set_reference_statement {
        arn = aws_wafv2_regex_pattern_set.deny_eb_cname_regex.arn

        field_to_match {
          single_header {
            name = "host"
          }
        }

        text_transformation {
          priority = 0
          type = "NONE"
        }
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "deny-eb-cname-request-rule"
      sampled_requests_enabled   = true
    }
  }

  visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "deny-eb-cname-request-metric"
      sampled_requests_enabled   = true
    }
}

resource "aws_wafv2_web_acl_association" "deny_eb_cname_assoc" {
  resource_arn = aws_lb.tf_alb_lb.arn
  web_acl_arn  = aws_wafv2_web_acl.deny_eb_cname_cal.arn
}
