FROM localstack/localstack
WORKDIR /opt/code/localstack
RUN apt-get update && apt-get install jq zip curl -y
RUN git clone https://github.com/localstack-samples/sample-serverless-image-resizer-s3-lambda.git
RUN cd sample-serverless-image-resizer-s3-lambda && \
    python -m venv .venv && \
    source .venv/bin/activate && \
    pip install -r requirements-dev.txt
