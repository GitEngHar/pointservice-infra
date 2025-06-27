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
  public_a_cider_block  = "10.0.1.0/24"
  public_c_cider_block  = "10.0.2.0/24"
  private_a_cider_block = "10.0.128.0/24"
}

module "security_group" {
  source                = "github.com/GitEngHar/TfSnsAuthenticationApp//modules/security_group?ref=master"
  vpc_id                = module.network.vpc_id
  app_ingress_to_port   = "1323"
  app_ingress_from_port = "1323"
}

module "alb" {
  source                       = "github.com/GitEngHar/TfSnsAuthenticationApp//modules/alb?ref=master"
  alb_access_security_group_id = module.security_group.alb_access_security_group_id
  vpc_id                       = module.network.vpc_id
  app_ingress_to_port          = "1323"
  app_ingress_from_port        = "1323"
  public_a_subnet_id           = module.network.public_a_id
  public_c_subnet_id           = module.network.public_c_id
}

module "cluster" {
  source                          = "github.com/GitEngHar/TfSnsAuthenticationApp//modules/cluster?ref=master"
  ecs_cluster_name                = "PointServiceCluster"
  vpc_id                          = module.network.vpc_id
  esc_service_discovery_namespace = "pointservice.internal"
}

module "db" {
  source                         = "github.com/GitEngHar/TfSnsAuthenticationApp//modules/service-db?ref=master"
  task_definition_family         = "PointServiceDBDef"
  ecs_cluster_id                 = module.cluster.ecs_cluster_id
  private_subnet_id              = module.network.public_a_id
  mysql_access_security_group_id = module.security_group.mysql_access_security_group_id
  container_image                = "${var.aws_account_id}.dkr.ecr.ap-northeast-1.amazonaws.com/point-service/db:latest"
  container_environment          = local.db_container_environment
  aws_account_id                 = var.aws_account_id
  service_discovery_id           = module.cluster.ecs_service_discovery_id
}

module "log" {
  source            = "github.com/GitEngHar/TfSnsAuthenticationApp//modules/log?ref=master"
  log_save_duration = 1
}

module "ecs" {
  source                       = "github.com/GitEngHar/TfSnsAuthenticationApp//modules/service-app?ref=master"
  task_definition_family       = "PointServiceAppDef"
  ecs_service_log_group_name   = module.log.log_name
  container_environment        = local.app_container_enviroment
  ecs_service_listener         = module.alb.alb_ecs_service_listener_arn
  ecs_cluster_id               = module.cluster.ecs_cluster_id
  ecs_service_name             = "PointService"
  container_name               = "point-service"
  public_a_subnet_id           = module.network.public_a_id
  container_port               = "1323"
  aws_account_id               = var.aws_account_id
  app_access_security_group_id = module.security_group.ecs_service_access_security_group_id
  container_image              = "point-service/app:latest"
  lb_target_group_arn          = module.alb.alb_ecs_service_target_group_id
  depends_on                   = [module.db]
  service_discovery_id         = module.cluster.ecs_service_discovery_id
}

module "batch" {
  source        = "github.com/GitEngHar/TfSnsAuthenticationApp//modules/lambda-run-type-zip?ref=master"
  function-name = "point-service-batch-health-check"
  lambda_environment = {
    APP_ENV                      = "aws"
    REQUEST_TO_SERVER_METHOD     = "GET"
    REQUEST_TO_SERVER_URL_PATH   = "app.pointservice.internal:1323"
    REQUEST_TO_SERVER_URL_SCHEMA = "http"
  }
  lambda_exec_role_arn = var.lambda_exec_role_arn
  lambda_image_uri     = var.lambda_image_uri
  security_group_id    = module.security_group.lambda_access_security_group_id
  subnet_id_a          = module.network.public_a_id
  subnet_id_c          = module.network.public_c_id
  lambda_zip_path      = "${path.root}/build/function.zip"
}
