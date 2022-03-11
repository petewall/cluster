#!/usr/bin/env bash

kubectl apply -f namespace.yaml
kubectl apply -f ../../../secrets/ddclient-secret.yaml
kubectl apply -f ddclient.yaml
