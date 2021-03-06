#-------------------------------------------------------------------------------
# REQUIRED VARIABLES
#-------------------------------------------------------------------------------
variable "src" {
  description = "Absolute path to the src directory of the function code."
}

variable "name" {
  description = "The name given to the Lambda function."
}

variable "iam_role_name" {
  description = "The name of the IAM role that will be assumed by Lambda."
}

variable "iam_role_arn" {
  description = "The ARN of the IAM role that will be assumed by Lambda."
}

#-------------------------------------------------------------------------------
# OPTIONAL VARIABLES
#-------------------------------------------------------------------------------
variable "lambda_memory_size" {
  type        = "string"
  default     = "128"
  description = "(Optional) Amount of memory in MB your Lambda Function can use at runtime. Defaults to '128'."
}

variable "lambda_timeout" {
  default     = "300"
  description = "The how many seconds before the Lambda function will timeout. Defaults to 300."
}

variable "lambda_runtime" {
  type        = "string"
  default     = "go1.x"
  description = "(Optional) The runtime used by the Lambda function. When setting this be sure to check that the handler variables matches. Defaults to 'go1.x'."
}

variable "lambda_handler" {
  type        = "string"
  default     = "main"
  description = "(Optional) The handler that will be called by Lambda. Make sure this mathes the runtime set. Defaults to 'main'."
}

variable "env_vars" {
  type        = "map"
  default     = {}
  description = "Environment variables that will be made available in the Lambda runtime environment. Defaults to {}"
}

variable "build_command" {
  type        = "string"
  default     = "make"
  description = "The command that builds the zip file used as the src for the Lambda function. Defaults to 'make'. The command must read the variable ZIPNAME from the environment and use it as the zip file name."
}

variable "build_command_working_dir" {
  type        = "string"
  default     = ""
  description = "The directory in which the build command will be run. If not explicitly set, the src directory will be used."
}

variable "clean_command" {
  type        = "string"
  default     = "make clean"
  description = "The command that cleans up the build working dir. Defaults to 'make clean'."
}

variable "tmp_dir" {
  type        = "string"
  default     = "/tmp"
  description = "The temp directory where a temporary archive of the src dir will be created to determin the directory sha. Defaults to '/tmp'."
}

variable "vpc_subnet_ids" {
  type        = "list"
  description = "(Optional) A list of VPC Subnet IDs. Required when using Lambda within a VPC. Defaults to empty list."
  default     = []
}

variable "vpc_security_group_ids" {
  type        = "list"
  description = "(Optional) A list of VPC Security Group IDs. Required when using Lambda within a VPC. Defaults to empty list."
  default     = []
}
