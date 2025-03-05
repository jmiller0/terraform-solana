# GCP Service Account for Validator
resource "google_service_account" "validator" {
  account_id   = "validator-sa"
  display_name = "Validator Service Account"
}

# Grant Storage Access
resource "google_project_iam_member" "validator_storage" {
  project = var.gcp_project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.validator.email}"
} 