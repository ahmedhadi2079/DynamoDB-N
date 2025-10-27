# Global vars
variable "bespoke_account" {
  description = "bespoke account to deploy (sandbox, nfrt, alpha, beta, production)"
  type        = string
}

variable "resource_management_iam_role" {
  description = "Name of the role TF uses to manage resources in AWS accounts."
  type        = string
}

variable "external_id" {
  description = "External identifier to use when assuming the role."
  type        = string
}

variable "aws_account_id" {
  type        = string
  description = "AWS Account ID which may be operated on by this template"
}

variable "project_url" {
  description = "URL of the gitlab project that owns the resources"
  default     = "https://gitlab.com/bb2-bank/data-lake/ddb-integration"
  type        = string
}

variable "region" {
  type        = string
  default     = "eu-west-2"
  description = "AWS Region the S3 bucket should reside in"
}

# Lambda vars
variable "lambda_ddb_to_s3_memory_size" {
  description = "Memory size for the lambda function"
  type        = number
  default     = 512
}

variable "lambda_ddb_rds_memory_size" {
  description = "Memory size for the RDS lambda function"
  type        = number
  default     = 512
}

variable "export_only_tables" {
  description = "List of tables that will be extracted from RDS DB"
  type        = list(string)
  default = [
    "property_finance.public.mortgage_applications",
    "property_finance.public.mortgage_application_customers",
    "property_finance.public.mortgage_application_customer_income_sources",
    "property_finance.public.loan_accounts",
    "property_finance.public.mortgages",
    "property_finance.public.mortgage_application_customer_incomes",
    "property_finance.public.loan_account_installments",
    "property_finance.public.mortgage_application_advisors",
    "property_finance.public.deposit_accounts",
    "property_finance.public.mortgage_application_contacts",
    "property_finance.public.mortgage_application_stages"
  ]
}

variable "dynamo_recon_table_events" {
  description = "List of dynamo_tables that will be recocile"
  default     = {}
}
