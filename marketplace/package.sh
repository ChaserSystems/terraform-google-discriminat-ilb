#!/bin/bash

set -e
set -o pipefail
set -x

version=$(echo 'var.image_version' | terraform console | tr -d '"')
build=$(date +%Y-%m-%d-%H-%M-%S)

mkdir /tmp/gcp-discriminat-ilb_${version}_${build}

cp discriminat.tf README.md /tmp/gcp-discriminat-ilb_${version}_${build}/
cp marketplace/*.tf marketplace/*.tfvars marketplace/*.yaml /tmp/gcp-discriminat-ilb_${version}_${build}/

zip -j /tmp/gcp-discriminat-ilb_${version}_${build}.zip /tmp/gcp-discriminat-ilb_${version}_${build}/*
