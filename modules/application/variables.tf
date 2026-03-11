variable "db_name" {
  type        = string
  default     = ""
  description = "Database name"
}

variable "db_user" {
  type        = string
  default     = ""
  description = "Database user"
}

variable "db_pass" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Database password"
}

variable "db_host" {
  type        = string
  default     = ""
  description = "Database host"
}

variable "db_port" {
  type        = number
  default     = 0
  description = "Database port"
}

variable "back_port" {
  type        = number
  default     = 0
  description = "Backend application port"
}

variable "admin_password" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Admin user password"
}

variable "back_path" {
  type        = string
  default     = ""
  description = "Path to the backend application"
}

variable "front_path" {
  type        = string
  default     = ""
  description = "Path to the frontend application"
}