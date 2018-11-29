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
