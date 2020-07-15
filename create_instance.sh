#!/usr/bin/env bash

gcloud compute instances create manual-name \
    --zone us-central1-c \
    --machine-type f1-micro \
    --image-family cos-stable \
    --image-project cos-cloud \
    --metadata-from-file user-data=cloudinit.yml
