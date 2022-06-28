#!/usr/bin/env bash

kapp deploy -a network -f namespace.yaml -f ../../../secrets/ddclient-secret.yaml -f ddclient.yaml
