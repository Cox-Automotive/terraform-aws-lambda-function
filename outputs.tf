output "function_arn" {
  value = "${element(concat(aws_lambda_function.func.*.arn, list("")), 0)}"
}

output "function_name" {
  value = "${element(concat(aws_lambda_function.func.*.function_name, list("")), 0)}"
}

output "vpc_function_arn" {
  value = "${element(concat(aws_lambda_function.vpc_func.*.arn, list("")), 0)}"
}

output "vpc_function_name" {
  value = "${element(concat(aws_lambda_function.vpc_func.*.function_name, list("")), 0)}"
}