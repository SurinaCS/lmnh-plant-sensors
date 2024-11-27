provider "aws" {
    region      = var.AWS_REGION
    access_key  = var.AWS_ACCESS_KEY
    secret_key  = var.AWS_SECRET_KEY
}

data "aws_vpc" "c14-vpc" {
    id = var.C14_VPC
}

data "aws_subnet" "c14-subnet-1" {
  id = var.C14_SUBNET_1
}

data "aws_subnet" "c14-subnet-2" {
  id = var.C14_SUBNET_2
}

data "aws_subnet" "c14-subnet-3" {
  id = var.C14_SUBNET_3
}



# --------------- PLANTS ETL: LAMBDA & EVENT BRIDGE

# IAM Role for Lambda execution
resource "aws_iam_role" "c14-runtime-terrors-plants-etl-lambda_execution_role-tf" {
  name = "c14-runtime-terrors-plants-etl-lambda_execution_role-tf"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Lambda execution role
resource "aws_iam_role_policy" "c14-runtime-terrors-plants-etl-lambda_execution_policy-tf" {
  name = "c14-runtime-terrors-plants-etl-lambda_execution_policy-tf"
  role = aws_iam_role.c14-runtime-terrors-plants-etl-lambda_execution_role-tf.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
      {
        Action   = "dynamodb:Query"
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/c14-runtime-terrors-plants-etl-lambda-function-tf"
  retention_in_days = 7
}


resource "aws_lambda_function" "c14-runtime-terrors-plants-etl-lambda-function-tf" {
  role          = aws_iam_role.c14-runtime-terrors-plants-etl-lambda_execution_role-tf.arn
  function_name = "c14-runtime-terrors-plants--etl-lambda-function-new-tf"
  package_type  = "Image"
  architectures = ["x86_64"]
  image_uri     = var.ETL_ECR_URI

  timeout       = 720
  depends_on    = [aws_cloudwatch_log_group.lambda_log_group]

  environment {
    variables = {
      ACCESS_KEY_ID     = var.AWS_ACCESS_KEY,
      SECRET_ACCESS_KEY = var.AWS_SECRET_KEY,
      DB_HOST           = var.DB_HOST,
      DB_NAME           = var.DB_NAME,
      DB_USER           = var.DB_USER,
      DB_PASSWORD       = var.DB_PASSWORD,
      DB_PORT           = var.DB_PORT,
      SCHEMA_NAME       = var.SCHEMA_NAME
    }
  }
    logging_config {
    log_format = "Text"
    log_group  = "/aws/lambda/c14-runtime-terrors-plants-etl-lambda-function-tf"
  }

  tracing_config {
    mode = "PassThrough"
  }
}

# Event bridge schedule: 
# IAM Role for AWS Scheduler
resource "aws_iam_role" "c14-runtime-terrors-plants-etl-scheduler_execution_role-tf" {
  name = "c14-runtime-terrors-plants-etl-scheduler_execution_role-tf"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "c14-runtime-terrors-plants-etl-scheduler_execution_policy-tf" {
  name = "c14-runtime-terrors-plants-etl-scheduler_execution_policy-tf"
  role = aws_iam_role.c14-runtime-terrors-plants-etl-scheduler_execution_role-tf.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action   = "lambda:InvokeFunction"
        Effect   = "Allow"
        Resource = aws_lambda_function.c14-runtime-terrors-plants-etl-lambda-function-tf.arn
      }
    ]
  })
}

# AWS Scheduler Schedule: every minute
resource "aws_scheduler_schedule" "c14-runtime-terrors-plants-etl-schedule-tf" {
  name                         = "c14-runtime-terrors-plants-etl-schedule-tf"
  schedule_expression          =  "cron(* * * * ? *)"
  schedule_expression_timezone = "Europe/London"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.c14-runtime-terrors-plants-etl-lambda-function-tf.arn
    role_arn = aws_iam_role.c14-runtime-terrors-plants-etl-scheduler_execution_role-tf.arn
  }
}



# # --------------- PLANTS ARCHIVE: LAMBDA & EVENT BRIDGE

# # IAM Role for Lambda execution
# resource "aws_iam_role" "c14-runtime-terrors-plants-archive-lambda_execution_role-tf" {
#   name = "c14-runtime-terrors-plants-archive-lambda_execution_role-tf"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action    = "sts:AssumeRole"
#         Effect    = "Allow"
#         Principal = {
#           Service = "lambda.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# # IAM Policy for Lambda execution role
# resource "aws_iam_role_policy" "c14-runtime-terrors-plants-archive-lambda_execution_policy-tf" {
#   name = "c14-runtime-terrors-plants-archive-lambda_execution_policy-tf"
#   role = aws_iam_role.c14-runtime-terrors-plants-archive-lambda_execution_role-tf.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = [
#           "logs:CreateLogGroup",
#           "logs:CreateLogStream",
#           "logs:PutLogEvents"
#         ]
#         Effect   = "Allow"
#         Resource = "*"
#       },
#       {
#         Action   = "dynamodb:Query"
#         Effect   = "Allow"
#         Resource = "*"
#       }
#     ]
#   })
# }

# resource "aws_lambda_function" "c14-runtime-terrors-plants-archive-lambda-function-tf" {
#   role          = aws_iam_role.c14-runtime-terrors-plants-archive-lambda_execution_role-tf.arn
#   function_name = "c14-runtime-terrors-plants-archive-archive-lambda-function-new-tf"
#   package_type  = "Image"
#   architectures = ["x86_64"]
#   image_uri     = var.ARCHIVE_ECR_URI

#   timeout       = 720
#   depends_on    = [aws_cloudwatch_log_group.lambda_log_group]

#   environment {
#     variables = {
#       ACCESS_KEY_ID     = var.AWS_ACCESS_KEY,
#       SECRET_ACCESS_KEY = var.AWS_SECRET_KEY,
#       DB_HOST           = var.DB_HOST,
#       DB_NAME           = var.DB_NAME,
#       DB_USER           = var.DB_USER,
#       DB_PASSWORD       = var.DB_PASSWORD,
#       DB_PORT           = var.DB_PORT,
#       SCHEMA_NAME       = var.SCHEMA_NAME
#     }
#   }
#     logging_config {
#     log_format = "Text"
#     log_group  = "/aws/lambda/c14-runtime-terrors-plants-archive-lambda-function-tf"
#   }

#   tracing_config {
#     mode = "PassThrough"
#   }
# }

# # Event bridge schedule: 
# # IAM Role for AWS Scheduler
# resource "aws_iam_role" "c14-runtime-terrors-plants-archive-scheduler_execution_role-tf" {
#   name = "c14-runtime-terrors-plants-archive-scheduler_execution_role-tf"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action    = "sts:AssumeRole"
#         Effect    = "Allow"
#         Principal = {
#           Service = "scheduler.amazonaws.com"
#         }
#       }
#     ]
#   })
# }

# resource "aws_iam_role_policy" "c14-runtime-terrors-plants-archive-scheduler_execution_policy-tf" {
#   name = "c14-runtime-terrors-plants-archive-scheduler_execution_policy-tf"
#   role = aws_iam_role.c14-runtime-terrors-plants-archive-scheduler_execution_role-tf.id

#   policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action   = "lambda:InvokeFunction"
#         Effect   = "Allow"
#         Resource = aws_lambda_function.c14-runtime-terrors-plants-archive-lambda-function-tf.arn
#       }
#     ]
#   })
# }

# # AWS Scheduler Schedule: everyday 12am
# resource "aws_scheduler_schedule" "c14-runtime-terrors-plants-archive-schedule-tf" {
#   name                         = "c14-runtime-terrors-plants-archive-schedule-tf"
#   schedule_expression          =  "cron(0 0 * * ? *)"
#   schedule_expression_timezone = "Europe/London"

#   flexible_time_window {
#     mode = "OFF"
#   }

#   target {
#     arn      = aws_lambda_function.c14-runtime-terrors-plants-archive-lambda-function-tf.arn
#     role_arn = aws_iam_role.c14-runtime-terrors-plants-archive-scheduler_execution_role-tf.arn
#   }
# }



# # --------------- ECS FARGATE SERVICE: DASHBOARD

# data "aws_ecs_cluster" "c14-cluster" {
#     cluster_name = var.C14_CLUSTER
# }

# data "aws_iam_role" "execution-role" {
#     name = "ecsTaskExecutionRole"
# }

# resource "aws_ecs_task_definition" "c14-runtime-terrors-plants-dashboard-ECS-task-def-tf" {
#   family                   = "c14-runtime-terrors-plants-dashboard-ECS-task-def-tf"
#   requires_compatibilities = ["FARGATE"]
#   network_mode             = "awsvpc"
#   execution_role_arn       = data.aws_iam_role.execution-role.arn
#   cpu                      = 1024
#   memory                   = 2048
#   container_definitions    = jsonencode([
#     {
#       name         = "c14-runtime-terrors-plants-dashboard-ECS-task-def-tf"
#       image        = var.DASHBOARD_ECR_URI
#       cpu          = 10
#       memory       = 512
#       essential    = true
#       portMappings = [
#         {
#             containerPort = 80
#             hostPort      = 80
#         },
#         {
#             containerPort = 8501
#             hostPort      = 8501       
#         }
#       ]
#       environment= [
#                 {
#                     "name": "ACCESS_KEY",
#                     "value": var.AWS_ACCESS_KEY
#                 },
#                 {
#                     "name": "SECRET_ACCESS_KEY",
#                     "value": var.AWS_SECRET_KEY
#                 },
#                 {
#                     "name": "DB_NAME",
#                     "value": var.DB_NAME
#                 },
#                 {
#                     "name": "DB_USER",
#                     "value": var.DB_USER
#                 },
#                 {
#                     "name": "DB_PASSWORD",
#                     "value": var.DB_PASSWORD
#                 },
#                 {
#                     "name": "DB_HOST",
#                     "value": var.DB_HOST
#                 },
#                 {
#                     "name": "DB_PORT",
#                     "value": var.DB_PORT
#                 },
#                 {
#                     "name": "SCHEMA_NAME",
#                     "value": var.SCHEMA_NAME
#                 }
#             ]
#             logConfiguration = {
#                 logDriver = "awslogs"
#                 options = {
#                     "awslogs-create-group"  = "true"
#                     "awslogs-group"         = "/ecs/c14-runtime-terrors-plants-ECS-task-def-tf"
#                     "awslogs-region"        = "eu-west-2"
#                     "awslogs-stream-prefix" = "ecs"
#                 }
#             }
#     },
#   ])
# }

# resource "aws_security_group" "c14-runtime-terrors-plants-dashboard-sg-tf" {
#     name        = "c14-runtime-terrors-plants-dashboard-sg-tf"
#     description = "Security group for connecting to dashboard"
#     vpc_id      = data.aws_vpc.c14-vpc.id

#     egress {
#         from_port   = 0
#         to_port     = 0
#         protocol    = "-1"
#         cidr_blocks = ["0.0.0.0/0"]
#     }
#     ingress {
#         from_port   = 8501
#         to_port     = 8501
#         protocol    = "tcp"
#         cidr_blocks = ["0.0.0.0/0"]
#     }


# }

# resource "aws_ecs_service" "c14-runtime-terrors-plants-dashboard-service-tf" {
#     name            = "c14-runtime-terrors-plants-dashboard-service-tf"
#     cluster         = data.aws_ecs_cluster.c14-cluster.id
#     task_definition = aws_ecs_task_definition.c14-runtime-terrors-plants-dashboard-ECS-task-def-tf.arn
#     desired_count   = 1
#     launch_type     = "FARGATE" 
    
#     network_configuration {
#         subnets          = [data.aws_subnet.c14-subnet-1, data.aws_subnet.c14-subnet-2, data.aws_subnet.c14-subnet-3] 
#         security_groups  = [aws_security_group.c14-runtime-terrors-plants-dashboard-sg-tf.id] 
#         assign_public_ip = true
#     }
# }