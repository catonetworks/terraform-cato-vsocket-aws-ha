terraform {
  required_providers {
    cato = {
      source  = "catonetworks/cato"
      version = ">= 0.0.38"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.98.0"
    }
  }
  required_version = ">= 1.5"
}