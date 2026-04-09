variable "aws_region" {
  default = "us-east-1"
}

variable "instance_type" {
  default = "t2.micro"
}

variable "min_size" {
  default = 2
}

variable "desired_capacity" {
  default = 2
}

variable "max_size" {
  default = 3
}

variable "docker_image" {
  default = "nithishkumar111/auto-healing-web:latest"
}