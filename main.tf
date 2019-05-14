provider "aws" {
      region     = "${var.region}"
}

resource "aws_ecs_cluster" "ciarans-cluster" {
  name = "${module.label.name}"
}

module "label" {
  source    = "git::https://github.com/cloudposse/terraform-terraform-label?ref=tags/0.11.0"
  namespace = "ciaran"
  stage     = "dev"
  name      = "container"
}

module "vpc" {
  source     = "git::https://github.com/cloudposse/terraform-aws-vpc.git?ref=tags/0.4.1"
  namespace  = "${module.label.namespace}"
  stage      = "${module.label.stage}"
  name       = "${module.label.name}"
  cidr_block = "10.0.0.0/16"
}

module "dynamic_subnets" {
  source             = "git::https://github.com/cloudposse/terraform-aws-dynamic-subnets.git?ref=master"
  namespace  = "${module.label.namespace}"
  stage      = "${module.label.stage}"
  name       = "${module.label.name}"
  region             = "${var.region}"
  availability_zones = ["${var.region}a","${var.region}b","${var.region}c"]
  vpc_id             = "${module.vpc.vpc_id}"
  igw_id             = "${module.vpc.igw_id}"
  cidr_block         = "10.0.0.0/16"
}


module "container_definition" {
  source          = "git::https://github.com/cloudposse/terraform-aws-ecs-container-definition?ref=tags/0.11.0"
  container_name  = "${module.label.name}"
  container_image = "ciaranevans/aws-parameters-spike:latest"

  environment = [
    {
      name  = "ACTIVE_PROFILE"
      value = "aws"
    }
  ]

  port_mappings = [
    {
      containerPort = 80
      hostPort      = 80
      protocol      = "tcp"
    }
  ]
}

module "alb" {
  source             = "git::https://github.com/cloudposse/terraform-aws-alb?ref=tags/0.2.6"
  namespace          = "${module.label.namespace}"
  name               = "${module.label.name}"
  stage              = "${module.label.stage}"

  vpc_id             = "${module.vpc.vpc_id}"
  ip_address_type    = "ipv4"

  subnet_ids         = ["${module.dynamic_subnets.public_subnet_ids}"]
  access_logs_region = "${var.region}"
}

module "alb_service_task" {
  source                    = "git::https://github.com/cloudposse/terraform-aws-ecs-alb-service-task?ref=tags/0.11.0"
  namespace                 = "${module.label.namespace}"
  stage                     = "${module.label.stage}"
  name                      = "${module.label.name}"
  alb_target_group_arn      = "${module.alb.alb_arn}"
  container_definition_json = "${module.container_definition.json}"
  container_name            = "${module.label.name}"
  ecs_cluster_arn           = "${aws_ecs_cluster.ciarans-cluster.arn}"
  ignore_changes_task_definition = "false"
  launch_type               = "FARGATE"
  vpc_id                    = "${module.vpc.vpc_id}"
  security_group_ids        = ["${module.alb.security_group_id}"]
  subnet_ids        = ["${module.dynamic_subnets.public_subnet_ids}"]
}