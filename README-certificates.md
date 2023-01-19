## Create your own Certificates

> All docker images are located in quay.io/3scale organization, but if you want to build your own, here are the instructions:

GRPC client and server

```shell
cd source
export TARGET=quay.io/3scale/grpc-utils:golang
docker build -t ${TARGET} -f client.dockerfile .
docker push ${TARGET}
```

Certificates:

The certificates are embedded into the yaml files, but if you want to change the
values this is how are generated.

Root CA certificate:

```shell
openssl genrsa -out rootCA.key 2048
openssl req -batch -new -x509 -nodes -key rootCA.key -sha256 -days 3650 -out rootCA.pem
```

Domain certificates for APICast

```shell
export DOMAIN=apicast-service
openssl req -subj "/CN=${DOMAIN}"  -newkey rsa:4096 -nodes \
    -sha256 \
    -days 3650 \
    -keyout ${DOMAIN}.key \
    -out ${DOMAIN}.csr
openssl x509 -req -in ${DOMAIN}.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out ${DOMAIN}.crt -days 3650 -sha256
```

Domain certificates for GRPC endpoint:

```shell
export DOMAIN=grpc-service
openssl req -subj "/CN=${DOMAIN}"  -newkey rsa:4096 -nodes \
    -sha256 \
    -days 3650 \
    -keyout ${DOMAIN}.key \
    -out ${DOMAIN}.csr
openssl x509 -req -in ${DOMAIN}.csr -CA rootCA.pem -CAkey rootCA.key -CAcreateserial -out ${DOMAIN}.crt -days 3650 -sha256
```
