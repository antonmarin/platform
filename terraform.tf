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
    beget = { # https://github.com/LTD-Beget/terraform-provider-beget/tree/master?tab=readme-ov-file
      source = "tf.beget.com/beget/beget"
    }
  }
}

provider "openstack" {
  auth_url         = "https://os-api.hostvds.com/identity/v3"
  user_domain_name = "Default"
}
provider "beget" {
  # https://developer.beget.com/#post-/v1/auth
  token = "eyJhbGciOiJSUzUxMiIsInR5cCI6IkpXVCJ9.eyJjdXN0b21lcklkIjoiMjU0NjU5MyIsImN1c3RvbWVyTG9naW4iOiJhbnRvbmF0diIsImVudiI6IndlYiIsImV4cCI6MTc3MTg2MzcwNywiaWF0IjoxNzcxNjA0NDQ3LCJpcCI6Ijk0LjE0My40Mi44NSIsImlzcyI6ImF1dGguYmVnZXQuY29tIiwianRpIjoiMjBiOTc1ZTUwYzBmZDc5MDFmOTNlYjQwMjU4N2Q1NGUiLCJwYXJlbnRMb2dpbiI6IiIsInN1YiI6ImN1c3RvbWVyIn0.xbYvdyxTW3A3kq3qUGSt4F8T07pjN9m23Lf81JuT9UIUB8-y1VxB6EFwWdltC4R59L61FeMlP2jQjp03KXE-yPgW2SSoMvdcBdIT24pU3zpdLW8k5n3DSJue81NbSasyqB4dILVeTbCYIYIz2OcVwrXCVecdGKcGq2SQJL3Z2Z0j8-ACZ121jLOkYwpLJ3dEwpCD7TG_ZCeXTq2IjvxosIrRL88QOAYwQYZ_OkjtXgdV5uVhYwi5gC848c6GdFEgYWh8ayuauNo5G9scrCD8K2I-GRSvLvLI04FXNETifysUy0GHOC9gOGT5K41q_i7kHXCHgsDcmWzTccA_TCdaXA"
}
