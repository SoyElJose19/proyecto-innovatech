variable "aws_region" {
  description = "Región de AWS"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block para la VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR para la subred pública (Frontend)"
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR para la subred privada (Backend y Data)"
  default     = "10.0.2.0/24"
}

variable "instance_type" {
  description = "Tipo de instancia EC2"
  default     = "t2.micro"
}

variable "key_name" {
  description = "Nombre de la llave SSH"
  type        = string
  default     = "vockey"
}