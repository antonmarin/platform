#!/usr/bin/env bash
set -eu

brew install pulumi/tap/pulumi
export PULUMI_BACKEND_URL=file://~/.pulumi
pulumi login $PULUMI_BACKEND_URL


## 1. Login locally (no cloud)
#pulumi login s3://my-pulumi-state-bucket
## 2. Initialize stack
#pulumi stack init fornex
## 3. Set configuration
#cat ~/.ssh/id_rsa | pulumi config set --secret sshPrivateKey
# 3.1. set key password if required
#pulumi config set --secret sshPrivateKeyPass
## 4. Preview
#pulumi preview
## 5. Deploy
#pulumi up

# Remove from state (doesn't touch server)
#pulumi state delete 'command:remote:Command::provisionServer'

# Or destroy stack
#pulumi stack rm dev

# Components https://www.pulumi.com/docs/iac/languages-sdks/yaml/yaml-component-reference/
