terraform {
  backend "s3" {
    bucket       = "bedrock-infra-state"
    key          = "terraform.tfstate"
    use_lockfile = true
    encrypt      = true
    region       = "us-east-1"
  }
}