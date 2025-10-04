#!/bin/bash
set -e

add-apt-repository -y ppa:deadsnakes/ppa
apt-get update
apt-get -y install python3.8 python3.8-venv \
python3.9 python3.9-venv \
python3.10-venv \
python3.11 python3.11-venv \
build-essential

### Install Python versions in virtual environments in the agent's tool cache
mkdir -p /azp/_work/_tool/

versions=('3.8' '3.9' '3.10' '3.11')
for version in ${versions[@]}; do
    full_version=$(eval "python${version} -V"| cut -d ' ' -f 2)
    mkdir -p /azp/_work/_tool/Python/${full_version}
    ln -s /azp/_work/_tool/Python/${full_version} /azp/_work/_tool/Python/$version
    eval "python${version} -m venv /azp/_work/_tool/Python/${full_version}/x64"
    touch /azp/_work/_tool/Python/${full_version}/x64.complete
done