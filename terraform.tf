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
  }
}

provider "openstack" {
  auth_url         = "https://os-api.hostvds.com/identity/v3"
  user_domain_name = "Default"
}
