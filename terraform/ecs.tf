module "vpc" {
  source                  = "cloudposse/vpc/aws"
  version                 = "2.1.1"
  name = "elixir_cluster_vpc"
  ipv4_primary_cidr_block = "10.0.0.0/16"
  dns_support_enabled = true # allows to resolve VPC hostnames via DNS
  dns_hostnames_enabled = true # all resources in vpc get hostnames assigned eg. `ip-172-31-0-1.eu-central-1.compute.internal`
}

module "subnets" {
  source  = "cloudposse/dynamic-subnets/aws"
  version = "2.4.2"

  name                  = "elixir_cluster_subnets"
  vpc_id               = module.vpc.vpc_id
  igw_id               = [module.vpc.igw_id]
  availability_zones   = var.availability_zones
  ipv4_cidr_block      = [module.vpc.vpc_cidr_block]
  nat_gateway_enabled  = true
  nat_instance_enabled = false # its ec2 with nat role, works like router with port forwarding
  map_public_ip_on_launch = true # instances launched into a public subnet will be assigned a public IPv4 address
  max_subnet_count = 3 # reserve 3 subnets for each az
}

resource "aws_service_discovery_private_dns_namespace" "namespace" {
  name        = var.dns_namespace_name
  description = "Private namespace for ECS service discovery"
  vpc         = module.vpc.vpc_id
}

resource "aws_service_discovery_service" "discovery_service" {
    name = "elixir_cluster"

  dns_config {
    namespace_id = aws_service_discovery_private_dns_namespace.namespace.id

    dns_records {
      ttl  = 10
      type = "A"
    }

    routing_policy = "MULTIVALUE"
  }

  health_check_custom_config {
    failure_threshold = 1
  }
}

module "alb" {
  source                = "cloudposse/alb/aws"
  version               = "2.3.0"
  name                  = "elixir_cluster_alb"
  
  vpc_id                = module.vpc.vpc_id
  ip_address_type       = "ipv4"
  subnet_ids            = module.subnets.public_subnet_ids

  http_enabled          = true
  https_enabled         = false
  http_redirect         = false

  health_check_interval = 300
  health_check_healthy_threshold = 10
  health_check_unhealthy_threshold = 10

  access_logs_enabled = false
  alb_access_logs_s3_bucket_force_destroy = true
}

resource "aws_ecs_cluster" "default" {
  count = 1
  name  = "elixir_cluster"

  setting {
    name  = "containerInsights"
    value = "enhanced"
  }
}

resource "aws_security_group" "erlang_distribution" {
  name        = "erlang-distribution"
  description = "Communication between Elixir nodes in the cluster"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "Allow distributed Erlang cluster communication"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }
}

resource "aws_security_group" "elixir_cluster" {
  name        = "elixir-cluster"
  description = "Allow distributed Erlang clustering"
  vpc_id      = module.vpc.vpc_id

  tags = {
    Name = "elixir-cluster"
  }
}

resource "aws_security_group_rule" "epmd" {
  type              = "ingress"
  from_port         = 4369
  to_port           = 4369
  protocol          = "tcp"
  security_group_id = aws_security_group.elixir_cluster.id
  source_security_group_id = aws_security_group.elixir_cluster.id
  description       = "Allow EPMD (epmd) between ECS tasks"
}

resource "aws_security_group_rule" "erpc" {
  type              = "ingress"
  from_port         = 9090
  to_port           = 9090
  protocol          = "tcp"
  security_group_id = aws_security_group.elixir_cluster.id
  source_security_group_id = aws_security_group.elixir_cluster.id
  description       = "Allow erpc (RPC) between ECS tasks"
}

resource "aws_security_group_rule" "erlang_dist" {
  type              = "ingress"
  from_port         = 9000
  to_port           = 9010
  protocol          = "tcp"
  security_group_id = aws_security_group.elixir_cluster.id
  source_security_group_id = aws_security_group.elixir_cluster.id
  description       = "Allow Erlang distributed ports"
}


module "web" {
  # source  = "cloudposse/ecs-web-app/aws"
  # version = "2.4.0"
  # source = "git::https://github.com/olafbado/terraform-aws-ecs-web-app.git//modules/web-app?ref=fix/service-registries-validation"
    source     = "git::git@github.com:olafbado/terraform-aws-ecs-web-app?ref=fix/service-registries-validation"

  name      = "elixir_cluster"
  region    = var.region
  vpc_id    = module.vpc.vpc_id

    ecs_security_group_ids = [aws_security_group.erlang_distribution.id]
  ecs_cluster_arn         = join("", aws_ecs_cluster.default.*.arn)
  ecs_cluster_name                  = join("", aws_ecs_cluster.default.*.name)
  ecs_private_subnet_ids  = module.subnets.private_subnet_ids
  desired_count = 2
  
  
  use_ecr_image                = true
  ecr_image_tag_mutability = "MUTABLE"
  container_cpu    = 512
  container_memory = 2048

  network_mode = "awsvpc" # required for Fargate launch type

  port_mappings = [{
    containerPort = var.container_port
    hostPort      = var.container_port
    protocol      = "tcp"
  }]

  exec_enabled = true
  
  codepipeline_enabled = false
  webhook_enabled      = false
  badge_enabled        = false
  ecs_alarms_enabled   = false
  autoscaling_enabled  = false
  container_port = var.container_port

  service_registries = [{
    registry_arn   = aws_service_discovery_service.discovery_service.arn
  }
  ]

  # ALB
  alb_ingress_protocol                           = "HTTP"
  use_alb_security_group                          = true
  alb_arn_suffix                                  = module.alb.alb_arn_suffix
  alb_security_group                              = module.alb.security_group_id
  alb_ingress_unauthenticated_listener_arns       = module.alb.listener_arns
  alb_ingress_unauthenticated_listener_arns_count = 2
  alb_ingress_unauthenticated_paths             = ["/*"]
  alb_ingress_listener_unauthenticated_priority = 100
  alb_ingress_healthcheck_path                    = "/healthz"
  alb_ingress_enable_default_target_group = true

  container_environment = [
    {
      name = "RELEASE_COOKIE"
      value = "hlelothere"
    },
  
  ]

  runtime_platform = [
    {
      operating_system_family = "LINUX"
      cpu_architecture        = "ARM64"
    }
  ]

  # healthcheck = []
}





# resource "aws_ecs_service" "mongo" {
#   name            = "mongodb"
#   cluster         = aws_ecs_cluster.default[0].arn
#   # task_definition = aws_ecs_task_definition.mongo.arn
#   desired_count   = 0

#   ordered_placement_strategy {
#     type  = "binpack"
#     field = "cpu"
#   }

#   # load_balancer {
#   #   target_group_arn = module.alb.target_group_arn
#   #   container_name   = "mongo"
#   #   container_port   = 8080
#   # }

#   launch_type = "FARGATE"

#   service_registries  {
#     registry_arn   = aws_service_discovery_service.discovery_service.arn
#     container_name = "mongo" 
#     container_port = 8080
#     port = 8080
#   }
  
#   placement_constraints {
#     type       = "memberOf"
#     expression = "attribute:ecs.availability-zone in [us-west-2a, us-west-2b]"
#   }
# }







# TODO: 
# 1. remove alb helathchecks
# 2. ty for service discovery ONLY WITH port and arn

# 376-384  in /.terraform/modules/web.ecs_alb_service_task/main.tf
  # dynamic "service_registries" {
  #   for_each = var.service_registries
  #   content {
  #     registry_arn   = service_registries.value.registry_arn
  #     container_name = lookup(service_registries.value, "container_name", null)
  #   }
  # }
  # 241-249 in .terraform/modules/web/variables.tf
# variable "service_registries" {
#   type = list(object({
#     registry_arn   = string
#     container_name = string
#     container_port = number
#   }))
#   description = "The service discovery registries for the service. The maximum number of service_registries blocks is 1. The currently supported service registry is Amazon Route 53 Auto Naming Service - `aws_service_discovery_service`; see `service_registries` docs https://www.terraform.io/docs/providers/aws/r/ecs_service.html#service_registries-1"
#   default     = []
# }


# EXEC COMMAND

# aws ecs execute-command --cluster elixir_cluster \
#     --task ee697d679a2e4fb1be6fb69e591c44a9 \
#     --container elixircluster \
#     --interactive \
#     --command "/bin/bash"

#     getent hosts elixir_cluster.elixir_cluster

#     System.get_env("RELEASE_DISTRIBUTION")