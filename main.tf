terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.54.1"
    }
  }
}

locals {
  db_container_environment = [
    {
      name  = "MYSQL_USER"
      value = "user"
    },
    {
      name  = "MYSQL_PASSWORD"
      value = "12u9024u9"
    },
    {
      name  = "MYSQL_DATABASE"
      value = "point-service-db"
    }
  ]
  app_container_enviroment = [
    {
      name  = "POINT_MYSQL_DATABASE"
      value = "point-service-db"
    },
    {
      name  = "POINT_MYSQL_HOST"
      value = "mysql.pointservice.internal"
    },
    {
      name  = "POINT_MYSQL_MAX_IDLE_CONNECTIONS"
      value = "2"
    },
    {
      name  = "POINT_MYSQL_MAX_OPEN_CONNECTIONS"
      value = "5"
    },
    {
      name  = "POINT_MYSQL_PASSWORD"
      value = "Password1"
    },
    {
      name  = "POINT_MYSQL_PORT"
      value = "3306"
    },
    {
      name = "POINT_MYSQL_USER"
    value = "root" }
  ]
}

provider "aws" {
  region     = "ap-northeast-1"
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

module "network" {
  source                = "github.com/GitEngHar/TfSnsAuthenticationApp//modules/network?ref=master"
  vpc_cider_block       = "10.0.0.0/16"
  public-a_cider_block  = "10.0.1.0/24"
  public-c_cider_block  = "10.0.2.0/24"
  private-a_cider_block = "10.0.128.0/24"
}

module "security_group" {
  source        = "github.com/GitEngHar/TfSnsAuthenticationApp//modules/security_group?ref=master"
  vpc_id        = module.network.vpc_id
  app-to-port   = "1323"
  app-from-port = "1323"
}

module "alb" {
  source        = "github.com/GitEngHar/TfSnsAuthenticationApp//modules/alb?ref=master"
  sg_id_for_alb = module.security_group.sg_id_for_alb
  vpc_id        = module.network.vpc_id
  app-to-port   = "1323"
  app-from-port = "1323"
  public-a_id   = module.network.public-a_id
  public-c_id   = module.network.public-c_id
}

module "cluster" {
  source                      = "github.com/GitEngHar/TfSnsAuthenticationApp//modules/cluster?ref=master"
  name_of_cluster             = "PointServiceCluster"
  vpc_id                      = module.network.vpc_id
  name_of_discovery_namespace = "pointservice.internal"
}

module "db" {
  source                     = "github.com/GitEngHar/TfSnsAuthenticationApp//modules/service-db?ref=master"
  task_def_family_name       = "PointServiceDBDef"
  id-ecs-cluster             = module.cluster.cluster_id
  id-private                 = module.network.public-a_id
  sg_id_for_connect_to_mysql = module.security_group.sg_id_for_connect_to_mysql
  name_of_container_image    = "${var.aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/point-service/db:latest"
  container_environment      = local.db_container_environment
  aws_account_id             = var.aws_account_id
  id_of_service_discovery    = module.cluster.id_of_service_discovery
}

module "log" {
  source            = "github.com/GitEngHar/TfSnsAuthenticationApp//modules/log?ref=master"
  log_save_duration = 1
}

module "ecs" {
  source                = "github.com/GitEngHar/TfSnsAuthenticationApp//modules/service-app?ref=master"
  task_def_family_name  = "PointServiceAppDef"
  ecs_log_group_name    = module.log.log_name
  container_environment = local.app_container_enviroment
  arn_ecs_app_listener  = module.alb.arn_ecs_app_listener
  id_of_ecs_cluster     = module.cluster.cluster_id
  name_of_service       = "PointService"
  name_of_container     = "point-service"
  public-a_id           = module.network.public-a_id
  app-to-port           = "1323"
  aws_account_id        = var.aws_account_id
  sg_id_for_ecs         = module.security_group.sg_id_for_ecs
  container_image_name  = "point-service/app:latest"
  arn_lb_target_group   = module.alb.arn_lb_target_group
  depends_on            = [module.db]
}




