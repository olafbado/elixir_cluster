# NOT NEEDED, "web" module will create

# data "aws_iam_role" "ecs_execution" {
#   name = "ecsTaskExecutionRole"
# }

# module "ecr" {
#   source                 = "cloudposse/ecr/aws"
#   version                = "0.42.1"
#   use_fullname           = false
#   name                   = var.ecr_repo_name
#   principals_full_access = [data.aws_iam_role.ecs_execution.arn]
# }

# output "ecr_repo_url" {
#   value = module.ecr.repository_url
# }