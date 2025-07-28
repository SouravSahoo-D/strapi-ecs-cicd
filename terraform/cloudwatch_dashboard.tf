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
          period = 300,
          stat   = "Average",
          title  = "Strapi ECS CPU"
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
          period = 300,
          stat   = "Average",
          title  = "Strapi ECS Memory"
        }
      }
    ]
  })
}
