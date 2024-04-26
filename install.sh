#!/bin/bash

IFS= read -p "LocalStack AUTH_TOKEN: " -r AUTH_TOKEN; 
docker compose build && \
docker compose up -d && \
docker exec -it localstack-main /bin/bash;
docker compose down