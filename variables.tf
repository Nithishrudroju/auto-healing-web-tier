variable "aws_region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "min_size" {
  default = 1
}

variable "desired_capacity" {
  default = 1
}

variable "max_size" {
  default = 1
}

variable "docker_image" {
  default = "your-dockerhub-username/auto-healing-web:latest"
}