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

output "validator_service_account_email" {
  description = "Email of the GCP service account for validator instances"
  value       = google_service_account.validator.email
}

output "workload_identity_provider" {
  description = "The Workload Identity Provider resource name"
  value       = "${google_iam_workload_identity_pool.github_actions.name}/providers/${google_iam_workload_identity_pool_provider.github_actions.workload_identity_pool_provider_id}"
}

output "github_actions_service_account_email" {
  description = "The email of the GitHub Actions service account"
  value       = google_service_account.github_actions.email
} 