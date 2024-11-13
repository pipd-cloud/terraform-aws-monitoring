module "slackbot" {
  source         = "./modules/slackbot"
  id             = var.id
  aws_tags       = var.aws_tags
  slack_team     = var.slackbot_team
  slack_channels = var.slackbot_channels
  events         = var.slackbot_events
  vpc_id         = var.vpc_id
  vpc_subnet_ids = var.vpc_subnet_ids
}

module "trailwatch" {
  count                       = var.trailwatch ? 1 : 0
  source                      = "./modules/trailwatch"
  id                          = var.id
  aws_tags                    = var.aws_tags
  cloudtrail_log_group_name   = var.trailwatch_cloudtrail_log_group_name
  cw_alarm_actions            = concat([module.slackbot.slackbot_sns_topic.arn], var.trailwatch_alarm_actions)
  cw_alarm_evaluation_periods = var.trailwatch_alarm_evaluation_periods
  cw_alarm_period             = var.trailwatch_alarm_period
}

module "pagebird" {
  count                 = var.pagebird ? 1 : 0
  source                = "./modules/pagebird"
  id                    = var.id
  aws_tags              = var.aws_tags
  website_urls          = var.pagebird_website_urls
  vpc_id                = var.vpc_id
  vpc_subnet_ids        = var.vpc_subnet_ids
  s3_access_logs_bucket = var.s3_access_logs_bucket
}
