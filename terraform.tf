terraform {
  required_version = ">= 0.13"
  required_providers {
    twc = {
      source  = "tf.timeweb.cloud/timeweb-cloud/timeweb-cloud"
      version = "~> 1.6"
    }
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 1.53.0"
    }
    # beget = { # https://github.com/LTD-Beget/terraform-provider-beget/tree/master?tab=readme-ov-file
    #   source = "tf.beget.com/beget/beget"
    # }
  }
}

provider "openstack" {
  auth_url         = "https://os-api.hostvds.com/identity/v3"
  user_domain_name = "Default"
}
provider "beget" {
  # https://developer.beget.com/#post-/v1/auth
  token = ""
}
