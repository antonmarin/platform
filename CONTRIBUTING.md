# Contributing

## Troubleshooting

### force recreate vm

- download the latest state
  from [terraform cloud](https://app.terraform.io/app/antonmarin/workspaces/platform/states) to ./terraform.tfstate
- `terraform taint google_compute_instance.vm_instance`
- queue run manually from terraform cloud
