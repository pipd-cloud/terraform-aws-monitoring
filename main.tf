module "rockstar" {
  source         = "./modules/rockstar"
  id             = var.id
  aws_tags       = var.aws_tags
  slack_team     = var.rockstar_team
  slack_channels = var.rockstar_channels
  events         = var.rockstar_events
  vpc_id         = var.vpc_id
  vpc_subnet_ids = var.vpc_subnet_ids
  clean_up = var.clean_up
}

module "trailwatch" {
  count                       = var.trailwatch ? 1 : 0
  source                      = "./modules/trailwatch"
  id                          = var.id
  aws_tags                    = var.aws_tags
  cloudtrail_log_group_name   = var.trailwatch_cloudtrail_log_group_name
  cw_alarm_actions            = concat([module.rockstar.rockstar_sns_topic.arn], var.trailwatch_alarm_actions)
  cw_alarm_evaluation_periods = var.trailwatch_alarm_evaluation_periods
  cw_alarm_period             = var.trailwatch_alarm_period
}

module "pagebird" {
  count                       = var.pagebird ? 1 : 0
  source                      = "./modules/pagebird"
  id                          = var.id
  aws_tags                    = var.aws_tags
  website_urls                = var.pagebird_website_urls
  vpc_id                      = var.vpc_id
  vpc_subnet_ids              = var.vpc_subnet_ids
  s3_access_logs_bucket       = var.pagebird_s3_access_logs_bucket != null ? var.pagebird_s3_access_logs_bucket : var.s3_access_logs_bucket
  cw_alarm_actions            = concat([module.rockstar.rockstar_sns_topic.arn], var.pagebird_alarm_actions)
  cw_alarm_evaluation_periods = var.pagebird_alarm_evaluation_periods
  cw_alarm_period             = var.pagebird_alarm_period
  clean_up = var.clean_up
}
