# Contributing

## Updating providers

All providers stored locally. So to update them:

To update for google(example):
- visit https://github.com/hashicorp/terraform-provider-google/tags
  and download expected version zip
- build it by included instructions
- copy result to `${PWD}/terraform.d/plugins/registry.terraform.io/hashicorp/google/{VERSION}/{OS_TYPE}/terraform-provider-google_v3.90.1_x5`.
  It works because of [Implied local mirror](https://www.terraform.io/cli/config/config-file#implied-local-mirror-directories)


## Troubleshooting

### force recreate vm

- download the latest state
  from [terraform cloud](https://app.terraform.io/app/antonmarin/workspaces/platform/states) to ./terraform.tfstate
- `terraform taint google_compute_instance.vm_instance`
- queue run manually from terraform cloud
