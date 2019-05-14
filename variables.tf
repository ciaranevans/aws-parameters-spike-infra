variable "region" {
    default = "eu-west-2"
}

variable "az_count" {
    description = "Number of AZs to cover in a given AWS region"
    default     = "2"
}

variable "app_port" {
    default = 8080
}

variable "fargate_cpu" {
    default = 256
}

variable "app_image" {
    default = "ciaranevans/aws-parameters-spike:latest"
}

variable "fargate_memory" {
    default = "512"
}

variable "app_count" {
    default = 1
}