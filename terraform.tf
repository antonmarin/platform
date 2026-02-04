terraform {
  required_version = ">= 0.13"
  required_providers {
    ruvds = {
      source  = "rustamkulenov/ruvds"
      version = "~> 1.3"
    }
    twc = {
      source = "tf.timeweb.cloud/timeweb-cloud/timeweb-cloud"
      version = "~> 1.6"
    }
  }
}
