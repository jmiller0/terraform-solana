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

# GCS Bucket
resource "google_storage_bucket" "validator" {
  name          = "gcp-sol-val"
  location      = var.gcp_region
  storage_class = "STANDARD"

  uniform_bucket_level_access = true

  labels = {
    Environment = "Dev"
    Service     = "Storage"
  }

  lifecycle_rule {
    condition {
      age = 90  # days
    }
    action {
      type = "SetStorageClass"
      storage_class = "STANDARD_IA"
    }
  }

  lifecycle_rule {
    condition {
      age = 180  # days
    }
    action {
      type = "SetStorageClass"
      storage_class = "COLDLINE"
    }
  }

  lifecycle_rule {
    condition {
      age = 365  # days
    }
    action {
      type = "Delete"
    }
  }

  versioning {
    enabled = true
  }
}

# IAM policy
resource "google_storage_bucket_iam_binding" "validator" {
  bucket = google_storage_bucket.validator.name
  role   = "roles/storage.objectViewer"
  
  members = [
    "serviceAccount:${var.validator_service_account}",
    "allUsers"  # Will be restricted by VPC Service Controls
  ]
} 