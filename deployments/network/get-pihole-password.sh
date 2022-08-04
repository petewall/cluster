#!/bin/bash

kubectl get secret -n network pihole-password -o yaml | yq -r .data.WEBPASSWORD | base64 -d
