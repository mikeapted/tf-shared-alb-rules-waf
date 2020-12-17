# tf-shared-alb-rules-waf

## Quick Start

### Create dependencies

Before running applying the plan you will need:
1. A domain name you plan to use
2. An ACM certificate (validated) ARN for that domain
3. A list of CIDRs that should be allowed to protected routes

### Set your environment variables for required variables

```bash
export TF_VAR_admin_cidrs="['X.X.X.X/X']"
export TF_VAR_domain_name=xxxx.xxx.xxxx.xx
export TF_VAR_certificate_arn=arn:aws:acm:us-east-1:111111111111:certificate/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeeee
```

### Run init/apply

```bash
terraform init
terraform apply
```
