#!/bin/bash

docker compose -f docker-compose.example.yml down -v
rm -rf ./volumes

docker build -t local/fusionpbx:0.1.0 .
docker compose -f docker-compose.example.yml up -d --build --wait

