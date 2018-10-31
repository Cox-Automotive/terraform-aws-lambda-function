locals {
  src            = "${var.src}"
  main_go        = "${local.src}/main.go"
  func_sha       = "${base64sha256(file("${local.main_go}"))}"
  build_work_dir = "${var.build_command_working_dir == "" ? local.src : var.build_command_working_dir}"
}

data "archive_file" "func_sha" {
  type        = "zip"
  source_dir  = "${local.src}"
  output_path = "${var.tmp_dir}/${uuid()}-aws-lambda-function.sha"
}

resource "aws_iam_role_policy" "policy" {
  role   = "${var.iam_role_name}"
  policy = "${var.iam_role_policy}"
}

resource "random_id" "zip" {
  keepers {
    local_src            = "${local.src}"
    lambda_function_name = "${var.name}"
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
  filename         = "${random_id.zip.keepers.local_src}/${random_id.zip.dec}-lambda.zip"
  function_name    = "${random_id.zip.keepers.lambda_function_name}"
  role             = "${var.iam_role_arn}"
  handler          = "main"
  runtime          = "go1.x"
  timeout          = "${var.lambda_timeout}"

  environment {
    variables = "${var.env_vars}"
  }

  depends_on = ["null_resource.build"]
}
