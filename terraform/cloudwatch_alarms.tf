resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "StrapiHighCPU"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 75
  alarm_description   = "Alarm when CPU exceeds 75%"
  dimensions = {
    ClusterName = aws_ecs_cluster.strapi_cluster.name
    ServiceName = aws_ecs_service.strapi_service.name
  }
  treat_missing_data = "missing"
}

resource "aws_cloudwatch_metric_alarm" "high_memory" {
  alarm_name          = "StrapiHighMemory"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/ECS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm when Memory exceeds 80%"
  dimensions = {
    ClusterName = aws_ecs_cluster.strapi_cluster.name
    ServiceName = aws_ecs_service.strapi_service.name
  }
  treat_missing_data = "missing"
}

resource "aws_cloudwatch_metric_alarm" "unhealthy_tasks" {
  alarm_name          = "Strapi-Unhealthy-Targets"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "UnHealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 0
  alarm_description   = "Triggered when ALB reports unhealthy ECS targets"
  dimensions = {
    LoadBalancer = "app/srs-strapi-alb/716eef04c36663b1"
    TargetGroup  = "targetgroup/srs-strapi-tg/6ec957a10683f96d"
  }
  treat_missing_data = "notBreaching"
}

resource "aws_cloudwatch_metric_alarm" "alb_latency_high" {
  alarm_name          = "Strapi-ALB-High-Latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "TargetResponseTime"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Average"
  threshold           = 1.5 # seconds
  alarm_description   = "ALB Target response time > 1.5 seconds"
  dimensions = {
    LoadBalancer = "app/srs-strapi-alb/716eef04c36663b1"
    TargetGroup  = "targetgroup/srs-strapi-tg/6ec957a10683f96d"
  }
  treat_missing_data = "notBreaching"
}