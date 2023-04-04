//**************************************************
// DB DYNAMODB
//**************************************************

module "dynamodb_table" {
  source   = "terraform-aws-modules/dynamodb-table/aws"

  billing_mode = "PROVISIONED"
  name     = var.db-name
  hash_key = "id"
  read_capacity = 1
  write_capacity = 1

  attributes = [
    {
      name = "id"
      type = "S"
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = "Test"
  }
}

//**************************************************
// LAMBDA FUNCTION
//**************************************************

module "lambda_function" {
  source = "terraform-aws-modules/lambda/aws"

  function_name = "http-crud-tutorial-function"
  description   = "My awesome CRUD lambda function"
  handler       = "index.handler"
  runtime       = "nodejs14.x"

  source_path = "src/index.js"


  publish = true

  allowed_triggers = {
    AllowExecutionFromAPIGateway = {
      service    = "apigateway"
      source_arn = "${module.api_gateway.apigatewayv2_api_execution_arn}/*/*"
    }
  }


  role_name = "http-crud-tutorial-role"
  create_role = true
  
  attach_policy = true
  policy = "arn:aws:iam::aws:policy/service-role/AWSLambdaDynamoDBExecutionRole"

  attach_policy_json = true
  policy_json =  jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:DeleteItem",
                "dynamodb:GetItem",
                "dynamodb:PutItem",
                "dynamodb:Scan",
                "dynamodb:UpdateItem"
            ],
            "Resource": module.dynamodb_table.dynamodb_table_arn
        }
    ]
})

#"arn:aws:dynamodb:us-east-1:761828390262:table/*"

  tags = {
    Name = "my-lambda-crud"
  }
}

//**************************************************
//API GATEWAY - HTTP API
//**************************************************


module "api_gateway" {
  source = "terraform-aws-modules/apigateway-v2/aws"

  name          = "http-crud-tutorial-api"
  description   = "My awesome HTTP API Gateway"
  protocol_type = "HTTP"


create_api_domain_name        = false
create_vpc_link               = false

default_stage_access_log_destination_arn = aws_cloudwatch_log_group.logs.arn
  default_stage_access_log_format          = "$context.identity.sourceIp - - [$context.requestTime] \"$context.httpMethod $context.routeKey $context.protocol\" $context.status $context.responseLength $context.requestId $context.integrationErrorMessage"


  # Routes and integrations
  integrations = {
    "GET /items/{id}" = {
        lambda_arn = module.lambda_function.lambda_function_arn
        payload_format_version = "2.0"
      }

    "GET /items" = {
        lambda_arn = module.lambda_function.lambda_function_arn
        payload_format_version = "2.0"
      }

    "PUT /items" = {
        lambda_arn = module.lambda_function.lambda_function_arn
        payload_format_version = "2.0"
      }

    "DELETE /items/{id}" = {
        lambda_arn = module.lambda_function.lambda_function_arn
        payload_format_version = "2.0"
      }

    "$default" = {
      lambda_arn = "arn:aws:lambda:us-east-1:761828390262:function:http-crud-tutorial-function"
      payload_format_version = "2.0"}
  }


  tags = {
    Name = "http-apigateway"
  }
}


##################
# Extra resources
##################

resource "random_pet" "this" {
  length = 2
}

resource "aws_cloudwatch_log_group" "logs" {
  name = random_pet.this.id
}