resource "aws_cloudwatch_dashboard" "strapi_dashboard" {
  dashboard_name = "StrapiMonitoring"

  dashboard_body = jsonencode({
    widgets = [
      {
        type = "metric",
        x = 0,
        y = 0,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            [ "AWS/ECS", "CPUUtilization", "ClusterName", aws_ecs_cluster.strapi_cluster.name, "ServiceName", aws_ecs_service.strapi_service.name ]
          ],
          period      = 300,
          stat        = "Average",
          title       = "ECS CPU Utilization",
          region      = var.region,
          annotations = {}
        }
      },
      {
        type = "metric",
        x = 0,
        y = 6,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            [ "AWS/ECS", "MemoryUtilization", "ClusterName", aws_ecs_cluster.strapi_cluster.name, "ServiceName", aws_ecs_service.strapi_service.name ]
          ],
          period      = 300,
          stat        = "Average",
          title       = "ECS Memory Utilization",
          region      = var.region,
          annotations = {}
        }
      },
      {
        type = "metric",
        x = 0,
        y = 12,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            [ "ECS/ContainerInsights", "RunningTaskCount", "ClusterName", aws_ecs_cluster.strapi_cluster.name, "ServiceName", aws_ecs_service.strapi_service.name ]
          ],
          period      = 300,
          stat        = "Average",
          title       = "ECS Running Task Count",
          region      = var.region,
          annotations = {}
        }
      },
      {
        type = "metric",
        x = 0,
        y = 18,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            [ "ECS/ContainerInsights", "NetworkRxBytes", "ClusterName", aws_ecs_cluster.strapi_cluster.name, "ServiceName", aws_ecs_service.strapi_service.name ]
          ],
          period      = 300,
          stat        = "Sum",
          title       = "Network In (Bytes)",
          region      = var.region,
          annotations = {}
        }
      },
      {
        type = "metric",
        x = 0,
        y = 24,
        width = 12,
        height = 6,
        properties = {
          metrics = [
            [ "ECS/ContainerInsights", "NetworkTxBytes", "ClusterName", aws_ecs_cluster.strapi_cluster.name, "ServiceName", aws_ecs_service.strapi_service.name ]
          ],
          period      = 300,
          stat        = "Sum",
          title       = "Network Out (Bytes)",
          region      = var.region,
          annotations = {}
        }
      }
    ]
  })
}
