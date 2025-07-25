terraform {
  backend "remote" {
    organization = "DevopsRun"

    workspaces {
      name = "strapi-ecs"
    }
  }
}