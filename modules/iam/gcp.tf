# GCP Service Account for Validator
resource "google_service_account" "validator" {
  account_id   = "validator-sa"
  display_name = "Validator Service Account"
  project      = var.gcp_project_id
}

# Grant Storage Access
resource "google_project_iam_member" "validator_storage" {
  project = var.gcp_project_id
  role    = "roles/storage.objectViewer"
  member  = "serviceAccount:${google_service_account.validator.email}"
}

# Grant Compute Instance Access
resource "google_project_iam_member" "validator_compute" {
  project = var.gcp_project_id
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.validator.email}"
}

# Grant Network Access
resource "google_project_iam_member" "validator_network" {
  project = var.gcp_project_id
  role    = "roles/compute.networkAdmin"
  member  = "serviceAccount:${google_service_account.validator.email}"
} 