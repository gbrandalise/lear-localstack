FROM localstack/localstack
WORKDIR /opt/code/localstack
RUN apt update && apt install wget vim jq zip curl lsb-release -y
RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list
RUN apt update && apt install terraform -y
RUN pip install ansible terraform-local
RUN git config --global --add safe.directory /opt/code/localstack/terraform/.terraform/modules/ssm-parameter
RUN git clone https://github.com/localstack-samples/sample-serverless-image-resizer-s3-lambda.git
RUN cd sample-serverless-image-resizer-s3-lambda && \
    python -m venv .venv && \
    source .venv/bin/activate && \
    pip install -r requirements-dev.txt
