output "github_actions_role_arn" {
  description = "ARN of the IAM role for GitHub Actions"
  value       = aws_iam_role.github_actions.arn
}

output "validator_role_arn" {
  description = "ARN of the IAM role for validator instances"
  value       = aws_iam_role.validator.arn
}

output "validator_instance_profile_name" {
  description = "Name of the instance profile for validator instances"
  value       = aws_iam_instance_profile.validator.name
}

output "salt_master_role_arn" {
  description = "ARN of the IAM role for salt master instance"
  value       = aws_iam_role.salt_master.arn
}

output "salt_master_instance_profile_name" {
  description = "Name of the instance profile for salt master instance"
  value       = aws_iam_instance_profile.salt_master.name
} 