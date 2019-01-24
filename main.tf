locals {
  src            = "${var.src}"
  main_go        = "${local.src}/main.go"
  func_sha       = "${base64sha256(file("${local.main_go}"))}"
  build_work_dir = "${var.build_command_working_dir == "" ? local.src : var.build_command_working_dir}"
  mode           = "${length(var.vpc_subnet_ids) > 0 ? "-vpc" : ""}"
  name           = "${var.name}${local.mode}"
  has_vpc_config = "${length(var.vpc_subnet_ids) > 0}"
  files          = "${path.module}/files"
}

data "archive_file" "func_sha" {
  type        = "zip"
  source_dir  = "${local.src}"
  output_path = "${var.tmp_dir}/${uuid()}-aws-lambda-function.sha"
}

resource "aws_iam_role_policy_attachment" "base" {
  role       = "${var.iam_role_name}"
  policy_arn = "${local.has_vpc_config ? "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole" : "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"}"
}

resource "aws_iam_role_policy_attachment" "vpc_supplemental" {
  count  = "${local.has_vpc_config ? 1 : 0}" // If has_vpc_config, 1 vpc_supplemental policy attachment; otherwise none
  role   = "${var.iam_role_name}"
  policy = "${file("${local.files}/vpc-supplement-policy.json")}"
}

resource "aws_iam_role_policy_attachment" "xray" {
  role       = "${var.iam_role_name}"
  policy_arn = "arn:aws:iam::aws:policy/AWSXrayWriteOnlyAccess"
}

resource "random_id" "zip" {
  keepers {
    local_src            = "${local.src}"
    lambda_function_name = "${local.name}"
    source_code_sha      = "${data.archive_file.func_sha.output_base64sha256}"
  }

  byte_length = 16
}

#-------------------------------------------------------------------------------
# BUILD
# ==========
# This null_resource will run the build_command which is expected to result in
# a zip archive with lambda.zip as the filename suffix. The triggers on this
# resource are what tells Terraform whether or not to recreate this resource. If
# the value of any of the triggers is different than what is # in the statefile,
# then make will be recreated. The triggers need to be the same values of the
# properties on the aws_lambda_function that would lead to it being recreated.
# Whenever the Lambda function is going to be recreated, we want the
# build_command to be run again so that the zipfile will be made available to
# the aws_lambda_function.
#-------------------------------------------------------------------------------
resource "null_resource" "build" {
  triggers {
    local_src            = "${random_id.zip.keepers.local_src}"
    lambda_function_name = "${random_id.zip.keepers.lambda_function_name}"
    source_code_sha      = "${random_id.zip.keepers.source_code_sha}"
  }

  provisioner "local-exec" {
    working_dir = "${local.build_work_dir}"
    command     = "${var.build_command}"

    environment {
      ZIPNAME = "${random_id.zip.dec}-lambda.zip"
    }
  }
}

resource "aws_lambda_function" "func" {
  count         = "${length(var.vpc_subnet_ids) > 0 ? 0 : 1}"                          // If more than 0 subnet_ids provided, 0 func, otherwise 1
  filename      = "${random_id.zip.keepers.local_src}/${random_id.zip.dec}-lambda.zip"
  function_name = "${random_id.zip.keepers.lambda_function_name}"
  role          = "${var.iam_role_arn}"
  handler       = "main"
  runtime       = "go1.x"
  timeout       = "${var.lambda_timeout}"
  memory_size   = "${var.lambda_memory_size}"

  environment {
    variables = "${var.env_vars}"
  }

  tracing_config {
    mode = "Active"
  }

  depends_on = ["null_resource.build"]
}

resource "aws_lambda_function" "vpc_func" {
  count         = "${length(var.vpc_subnet_ids) > 0 ? 1 : 0}"                          // If more than 0 subnet_ids provided, 1 vpc_func, otherwise 0
  filename      = "${random_id.zip.keepers.local_src}/${random_id.zip.dec}-lambda.zip"
  function_name = "${random_id.zip.keepers.lambda_function_name}"
  role          = "${var.iam_role_arn}"
  handler       = "main"
  runtime       = "go1.x"
  timeout       = "${var.lambda_timeout}"
  memory_size   = "${var.lambda_memory_size}"

  environment {
    variables = "${var.env_vars}"
  }

  tracing_config {
    mode = "Active"
  }

  vpc_config {
    subnet_ids         = ["${var.vpc_subnet_ids}"]
    security_group_ids = ["${var.vpc_security_group_ids}"]
  }

  depends_on = ["null_resource.build"]
}

resource "null_resource" "clean" {
  triggers {
    local_src            = "${random_id.zip.keepers.local_src}"
    lambda_function_name = "${random_id.zip.keepers.lambda_function_name}"
    source_code_sha      = "${random_id.zip.keepers.source_code_sha}"
  }

  provisioner "local-exec" {
    working_dir = "${local.build_work_dir}"
    command     = "${var.clean_command}"
  }

  depends_on = [
    "aws_lambda_function.func",
    "aws_lambda_function.vpc_func",
  ]
}
