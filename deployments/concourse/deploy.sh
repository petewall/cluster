#!/usr/bin/env bash

kubectl apply -f namespace.yaml
kubectl apply -f ../../../secrets/concourse-db.yaml
kubectl apply -f db.yaml
