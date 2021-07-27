#!/bin/bash

export K3S_URL=https://cluster-node-0:6443
export K3S_TOKEN=$(ssh pi@cluster-node-0 sudo cat /var/lib/rancher/k3s/server/node-token)
curl -sfL https://get.k3s.io | sh -
