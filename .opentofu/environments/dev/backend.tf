# KING TODO map
# .opentofu/environments/dev/backend.tf — soft-coded
# TODO:
# [ ] backend "s3"|"gcs"|"azurerm" per RICE_CLOUD_PROVIDER
#     bucket = RICE_TF_STATE_BUCKET, key = rice/dev/terraform.tfstate
#     encrypt = true, dynamodb_table = RICE_TF_LOCK_TABLE (AWS)
# [ ] backend "local" when RICE_TF_BACKEND=local

