locals {
  patterns = {
    vpc = {
      pattern = {
        event_source = "ec2.amazonaws.com"
        event_name = [
          "DeleteVpc",
          "DeleteSubnet",
          "DeleteSecurityGroup",
          "DeleteInternetGateway",
          "DeleteNatGateway",
          "DeleteRouteTable",
          "DeleteFlowLogs",
          "DeleteVpcEndpoints"
        ]
      }
      namespace   = "TrailWatch"
      metric_name = "VPC"
    }
    sg = {
      pattern = {
        event_source = "ec2.amazonaws.com"
        event_name = [
          "DeleteSecurityGroup",
          "RevokeSecurityGroupIngress",
          "RevokeSecurityGroupEgress",
          "AuthorizeSecurityGroupIngress",
          "AuthorizeSecurityGroupEgress"
        ]
      }
      namespace   = "TrailWatch/EC2"
      metric_name = "SecurityGroups"
    }
    elbv2 = {
      pattern = {
        event_source = "elasticloadbalancing.amazonaws.com"
        event_name = [
          "DeleteListener",
          "DeleteLoadBalancer",
          "DeleteRule",
          "DeleteTargetGroup",
          "DeregisterTargets",
          "ModifyListener",
          "SetSubnets"
        ]
      }
      namespace   = "TrailWatch"
      metric_name = "ELB"
    }
    wafv2 = {
      pattern = {
        event_source = "wafv2.amazonaws.com"
        event_name = [
          "DeleteFirewallManagerRuleGroups",
          "DeleteIPSet",
          "DeleteRuleGroup",
          "DeleteWebACL",
          "DisassociateWebACL",
          "UpdateRuleGroup",
        ]
      }
      namespace   = "TrailWatch"
      metric_name = "WAFv2"
    }
    ecs = {
      pattern = {
        event_source = "ecs.amazonaws.com"
        event_name = [
          "DeleteCluster",
          "DeleteService",
          "DeleteTaskDefinitions",
          "DeleteTaskSet",
          "DeregisterContainerInstance"
        ]
      }
      namespace   = "TrailWatch"
      metric_name = "ECS"
    }
    ecr = {
      pattern = {
        event_source = "ecr.amazonaws.com"
        event_name = [
          "DeleteRepository",
          "DeleteLifecyclePolicy",
          "DeleteRegistryPolicy",
          "DeleteRepositoryPolicy"
        ]
      }
      namespace   = "TrailWatch"
      metric_name = "ECR"
    }
    rds = {
      pattern = {
        event_source = "rds.amazonaws.com"
        event_name = [
          "StopDBInstance",
          "DeleteDBInstance",
          "RebootDBInstance",
          "DeleteDBSnapshot",
          "DeleteDBCluster",
          "DeleteDBClusterSnapshot",
          "FailoverDBCluster",
          "StopDBCluster",
          "RebootDBCluster"
        ]
      }
      namespace   = "TrailWatch"
      metric_name = "RDS"
    }
    elasticache = {
      pattern = {
        event_source = "elasticache.amazonaws.com"
        event_name = [
          "DeleteCacheCluster",
          "RebootCacheCluster",
          "ModifyCacheCluster",
          "DeleteReplicationGroup",
          "FailoverGlobalReplicationGroup"
        ]
      }
      namespace   = "TrailWatch"
      metric_name = "ElastiCache"
    }
    s3 = {
      pattern = {
        event_source = "s3.amazonaws.com"
        event_name = [
          "DeleteBucket",
          "DeleteObject",
          "PutBucketPolicy",
          "DeleteBucketPolicy",
          "PutBucketAcl",
          "DeleteAccessPoint"
        ]
      }
      namespace   = "TrailWatch"
      metric_name = "S3"
    },
    cloudtrail = {
      pattern = {
        event_source = "cloudtrail.amazonaws.com"
        event_name = [
          "DeleteTrail",
          "StopLogging",
          "UpdateTrail"
        ]
      }
      namespace   = "TrailWatch"
      metric_name = "CloudTrail"
    }

  }
}


resource "aws_cloudwatch_log_metric_filter" "filters" {
  for_each       = local.patterns
  log_group_name = data.aws_cloudwatch_log_group.cloudtrail.name
  name           = "${var.id}-${each.key}-trailwatch-metric-filter"
  pattern        = "{($.eventSource = ${each.value.pattern.event_source}) && (${join(" || ", [for e in each.value.pattern.event_name : "($.eventName = ${e})"])})}"
  metric_transformation {
    name          = each.value.metric_name
    namespace     = each.value.namespace
    value         = 1
    default_value = 0
    unit          = "Count"
  }
}

resource "aws_cloudwatch_metric_alarm" "trailwatch" {
  for_each            = local.patterns
  alarm_name          = "${var.id}-${each.key}-trailwatch-metric-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = var.cw_alarm_evaluation_periods
  treat_missing_data  = "ignore"
  alarm_description   = "Alarm that is raised whenever potentially disruptive API actions have been performed."
  threshold           = 1
  tags = merge(
    {
      Name = "${var.id}-${each.key}-trailwatch-metric-alarm"
      TFID = var.id
    },
    var.aws_tags
  )

  metric_query {
    id = "m1"
    metric {
      metric_name = each.value.metric_name
      namespace   = each.value.namespace
      period      = var.cw_alarm_period
      stat        = "Sum"
      unit        = "Count"
    }
    return_data = true
  }
}

resource "aws_cloudwatch_composite_alarm" "trailwatch" {
  alarm_name        = "${var.id}-trailwatch-alarm"
  alarm_rule        = join(" OR ", [for alarm in aws_cloudwatch_metric_alarm.trailwatch : "ALARM(\"${alarm.alarm_name}\")"])
  alarm_description = "Alarm that is raised whenever potentially disruptive API actions have been performed."
  actions_enabled   = true
  alarm_actions     = var.cw_alarm_actions
  ok_actions        = var.cw_alarm_actions
  tags = merge(
    {
      Name = "${var.id}-trailwatch-alarm"
      TFID = var.id
    },
    var.aws_tags
  )
  lifecycle {
    replace_triggered_by = [aws_cloudwatch_metric_alarm.trailwatch]
  }
}
