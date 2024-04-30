# Instalando o LocalStack
Neste exemplo o LocalStack estará rodando em um container Docker dentro do WSL
```
./install.sh
```

# Rodando o exemplo do QuickStart (Aplicacao de redimensionamento de imagens usando Lambda Functions)
## Depoy usando tflocal (Wrapper do Terraform para usar o LocalStack)
1. Acessa a pasta terraform
```sh
cd ./terraform
```
2. Remover os arquivos do estado do terraform
```sh
rm -rf *terraform* && \
rm -rf .terraform*
```
3. Executa o comando init
```sh
tflocal init
```
4. Executa o comando plan
```sh
tflocal plan
```
5. Executa o comando apply
```sh
tflocal apply
```

## Deploy automatizado usando script
1. Acessa a pasta do repositório do exemplo
```sh
cd sample-serverless-image-resizer-s3-lambda
```
2. Executa script de deploy
```sh
./bin/deploy.sh
```
## Depoy manual de cada servico
1. Acessa a pasta do repositório do exemplo
```sh
cd sample-serverless-image-resizer-s3-lambda
```
2. Cria os buckets S3
```sh
awslocal s3 mb s3://localstack-thumbnails-app-images
awslocal s3 mb s3://localstack-thumbnails-app-resized
```
3. Adiciona o nome dos buckets ao Parameter Store para uso futuro
```sh
awslocal ssm put-parameter \
    --name /localstack-thumbnail-app/buckets/images \
    --type "String" \
    --value "localstack-thumbnails-app-images"
awslocal ssm put-parameter \
    --name /localstack-thumbnail-app/buckets/resized \
    --type "String" \
    --value "localstack-thumbnails-app-resized"
```
4. Cria Topico do SNS para as falhas nas chamadas dos Lambdas
```sh
awslocal sns create-topic --name failed-resize-topic
awslocal sns subscribe \
    --topic-arn arn:aws:sns:us-east-1:000000000000:failed-resize-topic \
    --protocol email \
    --notification-endpoint my-email@example.com
```
5. Cria o Lambda do presign
```sh
(cd lambdas/presign; rm -f lambda.zip; zip lambda.zip handler.py)
awslocal lambda create-function \
    --function-name presign \
    --runtime python3.11 \
    --timeout 10 \
    --zip-file fileb://lambdas/presign/lambda.zip \
    --handler handler.handler \
    --role arn:aws:iam::000000000000:role/lambda-role \
    --environment Variables="{STAGE=local}"
awslocal lambda wait function-active-v2 --function-name presign
awslocal lambda create-function-url-config \
    --function-name presign \
    --auth-type NONE
```
6. Cria o Lambda da lista de imagens
```sh
(cd lambdas/list; rm -f lambda.zip; zip lambda.zip handler.py)
awslocal lambda create-function \
    --function-name list \
    --handler handler.handler \
    --zip-file fileb://lambdas/list/lambda.zip \
    --runtime python3.11 \
    --timeout 10 \
    --role arn:aws:iam::000000000000:role/lambda-role \
    --environment Variables="{STAGE=local}"
awslocal lambda wait function-active-v2 --function-name list
awslocal lambda create-function-url-config \
    --function-name list \
    --auth-type NONE
```
7. Cria o Lambda resizer
```sh
(cd lambdas/resize; rm -f lambda.zip; zip lambda.zip handler.py;zip -r lambda.zip package/)
awslocal lambda create-function \
    --function-name resize \
    --runtime python3.11 \
    --timeout 10 \
    --zip-file fileb://lambdas/resize/lambda.zip \
    --handler handler.handler \
    --dead-letter-config TargetArn=arn:aws:sns:us-east-1:000000000000:failed-resize-topic \
    --role arn:aws:iam::000000000000:role/lambda-role \
    --environment Variables="{STAGE=local}"
awslocal lambda wait function-active-v2 --function-name resize
awslocal lambda put-function-event-invoke-config \
    --function-name resize \
    --maximum-event-age-in-seconds 3600 \
    --maximum-retry-attempts 0
```
8. Conecta o bucket S3 ao Lambda resizer
```sh
awslocal s3api put-bucket-notification-configuration \
    --bucket localstack-thumbnails-app-images \
    --notification-configuration "{\"LambdaFunctionConfigurations\": [{\"LambdaFunctionArn\": \"$(awslocal lambda get-function --function-name resize | jq -r .Configuration.FunctionArn)\", \"Events\": [\"s3:ObjectCreated:*\"]}]}"
```
9. Cria o website estático no S3
```sh
awslocal s3 mb s3://webapp
awslocal s3 sync --delete ./website s3://webapp
awslocal s3 website s3://webapp --index-document index.html
```
10. Recupera as URLs dos Lambdas
```sh
awslocal lambda list-function-url-configs --function-name presign | jq -r '.FunctionUrlConfigs[0].FunctionUrl'
awslocal lambda list-function-url-configs --function-name list | jq -r '.FunctionUrlConfigs[0].FunctionUrl'
```

# Testar a aplicação
1. Abrir a URL https://webapp.s3-website.localhost.localstack.cloud:4566/
2. Clica no botão "Load from API" e depois clica em "Aplly"
3. Seleciona um arquivo de imagem e clica em "Upload"
4. Visualiza a lista de imagens exibida abaixo com o tamanho original e o tamanho redimensionado
5. Acessa LocalStack Web Application em https://app.localstack.cloud/inst/default/status
6. Clica em cada servico e ve os recursos criados (S3, Lambda, etc)