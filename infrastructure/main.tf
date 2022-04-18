# store tfstate in s3
# locking info not important
terraform {
  backend "s3" {
    encrypt = true
    bucket = var.backend_bucket
    region = "us-west-2"
    # not going to use dynamodb locking
    # dynamodb_table = "example-iac-terraform-state-lock-dynamo"
    key = "telephone/terraform.tfstate"
  }
}

# create an ip address
resource "aws_eip" "nat" {
  count = 1
  vpc = true
}

# generate a mongo password
resource "random_password" "password" {
  length           = 16
  special          = false
}

# our vpc our infrastructure will connect to
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-west-2a", "us-west-2b", "us-west-2c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_vpn_gateway     = true
  enable_nat_gateway     = true
  single_nat_gateway     = true # will appear in first public subnet
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true

  # don't allocate a new eip and instead use the one we created
  reuse_nat_ips       = true
  external_nat_ip_ids = aws_eip.nat.*.id

  public_outbound_acl_rules = [
    {
      "cidr_block": "0.0.0.0/0",
      "from_port": 0,
      "protocol": "-1",
      "rule_action": "allow",
      "rule_number": 100,
      "to_port": 0
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

# python dependencies for our lambdas
module "lambda_layer_local" {
  source = "terraform-aws-modules/lambda/aws"

  create_layer = true

  layer_name          = "dependencies"
  description         = "deps for various message lambdas"
  compatible_runtimes = ["python3.9"]

  create_package = false
  local_existing_package = "../deps.zip"
}

# lambda function plugged into our vpc
module "lambda_function_in_vpc" {
  source = "terraform-aws-modules/lambda/aws"

  environment_variables = {
    ACCOUNT_SID: var.twilio_sid,
    ACCOUNT_TOKEN: var.twilio_token,
    CONNECTION_STRING: "mongodb://${aws_docdb_cluster.service.master_username}:${aws_docdb_cluster.service.master_password}@${aws_docdb_cluster.service.endpoint}:${aws_docdb_cluster.service.port}",
    CURRENT_COLLECTION: var.message_collection_name
    FROM_NUMBER: var.twilio_from_number
  }

  function_name = "sendAllMessages"
  description   = "Sends messages from database"
  handler       = "main.sendMessage_handler"
  runtime       = "python3.9"

  create_package = false
  local_existing_package = "../message.zip"

  vpc_subnet_ids         = module.vpc.private_subnets
  vpc_security_group_ids = [module.vpc.default_security_group_id]
  attach_network_policy  = true

  create_current_version_allowed_triggers = false
  allowed_triggers = {
    OneRule = {
      principal  = "events.amazonaws.com"
      source_arn = module.eventbridge.eventbridge_bus_arn
    }
  }

  layers = [
    module.lambda_layer_local.lambda_layer_arn,
  ]
}

module "eventbridge" {
  source = "terraform-aws-modules/eventbridge/aws"
  create_bus = false

  rules = {
    crons = {
      description         = "Send Message trigger"
      schedule_expression = "rate(1 hour)"
    }
  }

  targets = {
    crons = [
      {
        name  = "my-target-lambda"
        arn   = module.lambda_function_in_vpc.lambda_function_arn
        input = jsonencode({"job": "cron-by-rate"})
      }
    ]
  }
}

resource "aws_docdb_subnet_group" "service" {
  name       = "docdb subnets"
  subnet_ids = module.vpc.private_subnets
}

resource "aws_docdb_cluster_instance" "service" {
  count              = 1
  identifier         = "mongo-cluster"
  cluster_identifier = aws_docdb_cluster.service.id
  instance_class     = "db.t3.medium"
}

resource "aws_docdb_cluster" "service" {
  skip_final_snapshot     = true
  db_subnet_group_name    = aws_docdb_subnet_group.service.name
  cluster_identifier      = "mongo-cluster"
  engine                  = "docdb"
  master_username         = var.docdb_admin_name
  master_password         = random_password.password.result
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.service.name
  vpc_security_group_ids = [aws_security_group.service.id]
}

resource "aws_docdb_cluster_parameter_group" "service" {
  family = "docdb4.0"
  name = "mongo-cluster"

  parameter {
    name  = "tls"
    value = "disabled"
  }
}

