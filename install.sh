#!/bin/bash

docker compose up -d && \
docker exec -it localstack-main /bin/bash;
docker compose down