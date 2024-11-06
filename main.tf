module "slackbot" {
  count          = var.slackbot ? 1 : 0
  source         = "./slackbot"
  id             = var.id
  aws_tags       = var.aws_tags
  slack_team     = var.slackbot_team
  slack_channels = var.slackbot_channels
  events         = var.slackbot_events
}

module "trailwatch" {
  count                       = var.trailwatch ? 1 : 0
  source                      = "./trailwatch"
  id                          = var.id
  aws_tags                    = var.aws_tags
  cloudtrail_log_group_name   = var.trailwatch_cloudtrail_log_group_name
  cw_alarm_actions            = var.slackbot ? concat([module.slackbot[0].slackbot_sns_topic.arn], var.trailwatch_alarm_actions) : var.trailwatch_alarm_actions
  cw_alarm_evaluation_periods = var.trailwatch_alarm_evaluation_periods
  cw_alarm_period             = var.trailwatch_alarm_period
}

module "pagebird" {
  count        = var.pagebird ? 1 : 0
  source       = "./pagebird"
  id           = var.id
  aws_tags     = var.aws_tags
  website_urls = var.pagebird_website_urls
}

data "aws_db_subnet_group" "aurora_test" {
  name = "dataeng-private-subnetgroup"
}

data "aws_db_snapshot" "aurora_test" {
  count                  = var.db_snapshot_identifier != null ? 1 : 0
  db_snapshot_identifier = var.db_snapshot_identifier
}

resource "aws_rds_cluster" "aurora_test" {
  cluster_identifier          = "${var.id}-aurora-db"
  engine                      = "aurora-postgresql"
  db_subnet_group_name        = data.aws_db_subnet_group.aurora_test.name
  engine_version              = var.db_snapshot_identifier != null ? data.aws_db_snapshot.aurora_test[0].engine_version : var.db_engine_version
  final_snapshot_identifier   = "${var.id}-aurora-db-final-${timestamp()}"
  master_username             = "prudence"
  manage_master_user_password = true
  snapshot_identifier         = var.db_snapshot_identifier != null ? data.aws_db_snapshot.aurora_test[0].db_snapshot_arn : null
  allow_major_version_upgrade = true
  storage_encrypted           = true
  copy_tags_to_snapshot       = true


  tags = var.aws_tags
  serverlessv2_scaling_configuration {
    min_capacity = 0.5
    max_capacity = 2.0
  }
  lifecycle {
    ignore_changes = [snapshot_identifier, engine_version]
  }
}

resource "aws_rds_cluster_instance" "aurora_test" {
  count              = var.db_cluster_instance_count
  identifier         = "${aws_rds_cluster.aurora_test.id}-${count.index}"
  cluster_identifier = aws_rds_cluster.aurora_test.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.aurora_test.engine
  engine_version     = aws_rds_cluster.aurora_test.engine_version
}

# resource "aws_elasticache_cluster" "redis" {

# }
