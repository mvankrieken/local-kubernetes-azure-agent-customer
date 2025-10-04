#!/bin/bash
set -e

docker build --tag "local/az-local-agent-customer:v1.0.1" --file "image/azure-agent.dockerfile" --platform linux/x86_64 image

echo "Image build locally as local/az-local-agent-customer:v1.0.1"