#!/bin/bash

kubectl create namespace plex
helm upgrade --namespace plex --install plex ./services/plex
