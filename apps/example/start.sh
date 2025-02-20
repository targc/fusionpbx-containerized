#!/bin/bash

docker build -t local/fusionpbx:0.1.0 .

cd "$(dirname "$0")"

docker compose -f docker-compose.yml down -v
rm -rf ./volumes

docker compose -f docker-compose.yml up -d --build --wait

