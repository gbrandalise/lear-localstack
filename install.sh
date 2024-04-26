#!/bin/bash

docker compose build && \
docker compose up -d && \
docker exec -it localstack-main /bin/bash;