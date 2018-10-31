output "function_arn" {
  value = "${aws_lambda_function.func.arn}"
}

output "function_name" {
  value = "${aws_lambda_function.func.function_name}"
}
