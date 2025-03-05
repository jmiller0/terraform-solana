# # GCS Bucket
# resource "google_storage_bucket" "validator" {
#   name          = "gcp-sol-val"
#   location      = var.gcp_region
#   storage_class = "STANDARD"

#   uniform_bucket_level_access = true
# }

# # IAM policy
# resource "google_storage_bucket_iam_binding" "validator" {
#   bucket = google_storage_bucket.validator.name
#   role   = "roles/storage.objectViewer"
  
#   members = [
#     "serviceAccount:${var.validator_service_account}",
#     "allUsers"  # Will be restricted by VPC Service Controls
#   ]
# } 