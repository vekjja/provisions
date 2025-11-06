#!/bin/bash

helm upgrade --install plex ./helm/plex \
  --namespace "plex" \
  --create-namespace

