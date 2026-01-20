provider "aws" {
    region = var.region

    default_tags {
        tags = {
            Project = "scoutflow"
            Environment = "dev"
            ManagedBy = "terraform"
            Owner = "omerbeithalahmy"
        }
    }
}