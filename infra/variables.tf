variable "cloud_id" {
  description = "Yandex Cloud Cloud ID"
  type        = string
  sensitive   = true
}

variable "folder_id" {
  description = "Yandex Cloud Folder ID"
  type        = string
  sensitive   = true
}

variable "new_user" {
  type    = string
  default = "meta.txt"
}