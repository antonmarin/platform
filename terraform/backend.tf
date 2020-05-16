terraform {
  backend "remote" {
    organization = "antonmarin"

    workspaces {
      name = "platform"
    }
  }
}
