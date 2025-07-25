terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "DevopsRun"

    workspaces {
      name = "strapi-ecs"
    }
  }
}
