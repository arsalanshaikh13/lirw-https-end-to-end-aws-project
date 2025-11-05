# upload the modified files to s3 bucket

# resource "local_file" "DbConfig" {
#   filename = "${path.root}/application-code/nginx.conf"  # This overwrites existing file
#   content  = templatefile("${path.root}/application-code/nginx.conf", {
#     internal_alb_dns_name = var.internal_alb_dns_name
#   })
# }
# resource "aws_s3_object" "nginx_conf" {
#   bucket = var.bucket_name
#   key    = "application-code/nginx.conf"
#   source = "${path.root}/application-code"
#   acl    = "private"
# }


# resource "local_file" "DbConfig" {
#   filename = "${path.root}/application-code/application-code/app-tier/DbConfig.js"  # This overwrites existing file
#   content  = templatefile("${path.root}/application-code/application-code/app-tier/DbConfig.js", {
#     db_host = var.db_dns_address
#     db_username = var.db_username
#     db_password = var.db_password
#     db_name     = var.db_name
#     db_secret_name = var.db_secret_name
#   })
# }
# resource "local_file" "DbConfig" {
#   filename = "${path.root}/application-code/application-code/app-tier/DbConfig.js"  # This overwrites existing file
#   content  = templatefile("${path.root}/application-code/application-code/app-tier/DbConfig.js", {
#     db_secret_name = var.db_secret_name
#   })
# }
# resource "aws_s3_object" "DbConfig" {
#   bucket = var.bucket_name
#   key    = "application-code/app-tier/DbConfig.js"
#   source = "${path.root}/application-code/application-code/app-tier/DbConfig.js"
#   acl    = "private"
#   depends_on = [ local_file.DbConfig ]
# }




# Fetch the latest ARM64 Amazon Linux 2023 AMI
# data "aws_ami" "latest_amazon_linux" {
#     most_recent = true

#     filter {
#         name   = "name"
#         values = ["al2023-ami-2023.*-arm64"] # Using ARM for cost optimization
#     }

#     filter {
#         name   = "virtualization-type"
#         values = ["hvm"]
#     }

#     owners = ["amazon"]
# }

# Creating VPC Endpoints
resource "aws_security_group" "vpc_endpoint_sg" {
  name        = "cloudwatch-logs-endpoint-sg"
  description = "Security group for CloudWatch Logs VPC endpoint"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# CloudWatch Logs
resource "aws_vpc_endpoint" "logs" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.logs"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.pri_sub_5a_id, var.pri_sub_6b_id]
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
}

# # CloudWatch Metrics
# resource "aws_vpc_endpoint" "monitoring" {
#   vpc_id              = aws_vpc.vpc.id
#   service_name        = "com.amazonaws.${var.region}.monitoring"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = aws_subnet.private[*].id
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true
# }

# SSM (for Parameter Store & Session Manager)
resource "aws_vpc_endpoint" "ssm" {
  vpc_id      = var.vpc_id
  service_name        = "com.amazonaws.${var.region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [var.pri_sub_5a_id, var.pri_sub_6b_id]
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  private_dns_enabled = true
}

# # SSM Messages (for Session Manager)
# resource "aws_vpc_endpoint" "ssmmessages" {
#   vpc_id              = aws_vpc.vpc.id
#   service_name        = "com.amazonaws.${var.region}.ssmmessages"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = aws_subnet.private[*].id
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true
# }

# # EC2 Messages (for SSM Agent)
# resource "aws_vpc_endpoint" "ec2messages" {
#   vpc_id              = aws_vpc.vpc.id
#   service_name        = "com.amazonaws.${var.region}.ec2messages"
#   vpc_endpoint_type   = "Interface"
#   subnet_ids          = aws_subnet.private[*].id
#   security_group_ids  = [aws_security_group.vpc_endpoints.id]
#   private_dns_enabled = true
# }

resource "aws_vpc_endpoint" "s3_gateway_vpc_flow_logs" {
  vpc_id       = var.vpc_id
  service_name = "com.amazonaws.${var.region}.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    var.pri_rt_a_id,
    var.pri_rt_b_id
  ]

  tags = {
    Name = "${var.project_name}-s3-endpoint"
  }
}



# ## Quick Decision Tree
# ```
# Do you need custom metrics (memory, disk usage)?
# ├─ NO → No VPC endpoints needed (basic metrics work automatically)
# └─ YES → Need VPC endpoints for:
#     ├─ logs (if sending logs)
#     ├─ monitoring (if sending custom metrics)
#     └─ ssm* (if using Parameter Store or Session Manager)






# data "local_file" "frontend_ami" {
#   filename = "${path.module}/ami_ids/frontend_ami.txt"
# }

# data "local_file" "backend_ami" {
#   filename = "${path.module}/ami_ids/backend_ami.txt"
# }
# locals {
#   frontend_ami_id = trimspace(data.local_file.frontend_ami.content)
#   backend_ami_id  = trimspace(data.local_file.backend_ami.content)
# }

resource "aws_launch_template" "lt_name" {
  name          = "${var.project_name}-tpl"
  # image_id      = data.aws_ami.latest_amazon_linux.id
  # image_id      = local.frontend_ami_id
  image_id      = "ami-0edf51c51a61dfff5"
  # image_id      = var.frontend_ami_id
  instance_type = var.cpu
  key_name      = var.client_key_name
  # user_data     = filebase64("../modules/asg/client.sh")

  # using packer
  # user_data = base64encode(templatefile("${path.module}/client.sh", {
  #   internal_alb_dns_name = var.internal_alb_dns_name
  #   bucket_name = var.bucket_name
  # }))
    # backend_alb_dns = var.internal_alb_dns_name


  # vpc_security_group_ids = [var.client_sg_id]

   network_interfaces {
    associate_public_ip_address = false
    security_groups            = [var.client_sg_id]
  }
  iam_instance_profile {
    # name = var.s3_ssm_instance_profile_name
    name = var.s3_ssm_cw_instance_profile_name
  }

  lifecycle {
    # ignore_changes = [image_id]
    create_before_destroy = false
  }
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_type = "standard"
      delete_on_termination = true
      volume_size = 8
      encrypted   = true
    }
  }
  # propagate tag on the instance launched from this template
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-client"
    }
  }
  tags = {
    Name = "${var.project_name}-tpl"
  }
}
# terraform apply -target=module.asg.aws_launch_template.server_lt_name
resource "aws_launch_template" "server_lt_name" {
  name          = "${var.project_name}-server_tpl"
  # image_id      = data.aws_ami.latest_amazon_linux.id
  # image_id      = local.backend_ami_id
  image_id      = "ami-019bd69da8b7f13a8"
  # image_id      = var.backend_ami_id
  instance_type = var.cpu
  key_name      = var.server_key_name
  # user_data     = filebase64("../modules/asg/server.sh")
  # depends_on = [ aws_s3_object.DbConfig ]

  # vpc_security_group_ids = [var.server_sg_id]

  network_interfaces {
    associate_public_ip_address = false
    security_groups            = [var.server_sg_id]
  }

  # using packer
#  user_data = base64encode(templatefile("${path.module}/server.sh", {
#     db_host     = var.db_dns_address
#     db_username = var.db_username
#     db_password = var.db_password
#     db_name     = var.db_name
#     db_secret_name     = var.db_secret_name
#     bucket_name = var.bucket_name
#     aws_region = var.region
#   }))
  iam_instance_profile {
    # name = var.s3_ssm_instance_profile_name
    name = var.s3_ssm_cw_instance_profile_name
  }

  lifecycle {
    # ignore_changes = [image_id]
    create_before_destroy = false
  }
  block_device_mappings {
    device_name = "/dev/xvda"

    ebs {
      volume_type = "standard"
      delete_on_termination = true
      volume_size = 8
      encrypted   = true
    }
  }

  # propagate tag on the instance launched from this template
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.project_name}-server"
    }
  }
  tags = {
    Name = "${var.project_name}-server_tpl"
  }
}

resource "aws_autoscaling_group" "asg_name" {
  name                      = "${var.project_name}-asg"
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_cap
  health_check_grace_period = 300
  health_check_type         = var.asg_health_check_type #"ELB" or default EC2
  vpc_zone_identifier = [var.pri_sub_3a_id,var.pri_sub_4b_id]
  target_group_arns   = [var.tg_arn] #var.target_group_arns

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  launch_template {
    id      = aws_launch_template.lt_name.id
    version = "$Latest" 
    # version = aws_launch_template.lt_name.latest_version 
  }
  tag {
    key                 = "Name"
    value              = "${var.project_name}-client-ec2"
    propagate_at_launch = true
  }

}
resource "aws_autoscaling_group" "server_asg_name" {

  name                      = "${var.project_name}-server-asg"
  max_size                  = var.max_size
  min_size                  = var.min_size
  desired_capacity          = var.desired_cap
  health_check_grace_period = 300
  health_check_type         = var.asg_health_check_type #"ELB" or default EC2
  vpc_zone_identifier = [var.pri_sub_5a_id,var.pri_sub_6b_id]
  target_group_arns   = [var.internal_tg_arn] #var.target_group_arns

  enabled_metrics = [
    "GroupMinSize",
    "GroupMaxSize",
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupTotalInstances"
  ]

  metrics_granularity = "1Minute"

  launch_template {
    id      = aws_launch_template.server_lt_name.id
    version = "$Latest" 
 
    # version = aws_launch_template.server_lt_name.latest_version 
  }
  tag {
    key                 = "Name"
    value              = "${var.project_name}-server-ec2"
    propagate_at_launch = true
  }

}
# https://github.com/chinmayto/terraform-aws-linux-webserver-cloudwatch-sns/blob/main/main.tf
# https://dev.to/chinmay13/getting-started-with-aws-and-terraform-setting-up-cloudwatch-alarms-for-cpu-utilization-on-aws-ec2-instances-with-terraform-14l2
####################################################
# Create an SNS topic with a email subscription
####################################################
resource "aws_sns_topic" "topic" {
  name = "WebServer-CPU_Utilization_alert"
}

resource "aws_sns_topic_subscription" "topic_email_subscription" {
  count     = length(var.email_address)
  topic_arn = aws_sns_topic.topic.arn
  protocol  = "email"
  endpoint  = var.email_address[count.index]
}

# scale up policy
resource "aws_autoscaling_policy" "scale_up" {
  name                   = "${var.project_name}-asg-scale-up"
  autoscaling_group_name = aws_autoscaling_group.asg_name.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1" #increasing instance by 1 
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

# scale up alarm
# alarm will trigger the ASG policy (scale/down) based on the metric (CPUUtilization), comparison_operator, threshold
resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_name          = "${var.project_name}-asg-scale-up-alarm"
  alarm_description   = "asg-scale-up-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "50" # New instance will be created once CPU utilization is higher than 50 %
  insufficient_data_actions = []
  treat_missing_data        = "notBreaching"

  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.asg_name.name
  }
  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.scale_up.arn, aws_sns_topic.topic.arn]
}

# scale down policy
resource "aws_autoscaling_policy" "scale_down" {
  name                   = "${var.project_name}-asg-scale-down"
  autoscaling_group_name = aws_autoscaling_group.asg_name.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1" # decreasing instance by 1 
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

# scale down alarm
resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_name          = "${var.project_name}-asg-scale-down-alarm"
  alarm_description   = "asg-scale-down-cpu-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "5" # Instance will scale down when CPU utilization is lower than 5 %
  insufficient_data_actions = []
  treat_missing_data        = "notBreaching"

  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.asg_name.name
  }
  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.scale_down.arn, aws_sns_topic.topic.arn]
}

resource "aws_autoscaling_policy" "server_scale_up" {
  name                   = "${var.project_name}-server-asg-scale-up"
  autoscaling_group_name = aws_autoscaling_group.server_asg_name.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "1" #increasing instance by 1 
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

# scale up alarm
# alarm will trigger the ASG policy (scale/down) based on the metric (CPUUtilization), comparison_operator, threshold
resource "aws_cloudwatch_metric_alarm" "server_scale_up_alarm" {
  alarm_name          = "${var.project_name}-server-asg-scale-up-alarm"
  alarm_description   = "asg-scale-up-cpu-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "50" # New instance will be created once CPU utilization is higher than 50 %
  insufficient_data_actions = []
  treat_missing_data        = "notBreaching"

  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.server_asg_name.name
  }
  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.server_scale_up.arn, aws_sns_topic.topic.arn]
}

# scale down policy
resource "aws_autoscaling_policy" "server_scale_down" {
  name                   = "${var.project_name}-server-asg-scale-down"
  autoscaling_group_name = aws_autoscaling_group.server_asg_name.name
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = "-1" # decreasing instance by 1 
  cooldown               = "300"
  policy_type            = "SimpleScaling"
}

# scale down alarm
resource "aws_cloudwatch_metric_alarm" "server_scale_down_alarm" {
  alarm_name          = "${var.project_name}-server-asg-scale-down-alarm"
  alarm_description   = "asg-scale-down-cpu-alarm"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "5" # Instance will scale down when CPU utilization is lower than 5 %
  insufficient_data_actions = []
  treat_missing_data        = "notBreaching"
  dimensions = {
    "AutoScalingGroupName" = aws_autoscaling_group.server_asg_name.name
  }
  actions_enabled = true
  alarm_actions   = [aws_autoscaling_policy.server_scale_down.arn, aws_sns_topic.topic.arn]
}