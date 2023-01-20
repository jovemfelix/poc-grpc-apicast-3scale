#!/bin/sh

# APICAST
APICAST_ROUTE=$1

## Generate self signed root CA cert
openssl req -nodes -x509 -newkey rsa:2048 -keyout apicast-ca.key -out apicast-ca.crt -subj "/C=AU/ST=NSW/L=Sydney/O=MongoDB/OU=root/CN=${APICAST_ROUTE}/emailAddress=test@t.com"

## Generate server cert to be signed
openssl req -nodes -newkey rsa:2048 -keyout apicast-server.key -out apicast-server.csr -subj "/C=AU/ST=NSW/L=Sydney/O=MongoDB/OU=server/CN=${APICAST_ROUTE}/emailAddress=test@t.com"

## Sign the server cert
openssl x509 -req -in apicast-server.csr -CA apicast-ca.crt -CAkey apicast-ca.key -CAcreateserial -out apicast-server.crt

## Create server PEM file
cat apicast-server.key apicast-server.crt > apicast-server.pem


## Generate client cert to be signed
openssl req -nodes -newkey rsa:2048 -keyout apicast-client.key -out apicast-client.csr -subj "/C=AU/ST=NSW/L=Sydney/O=MongoDB/OU=client/CN=${APICAST_ROUTE}/emailAddress=test@t.com"

## Sign the client cert
openssl x509 -req -in apicast-client.csr -CA apicast-ca.crt -CAkey apicast-ca.key -CAserial apicast-ca.srl -out apicast-client.crt

## Create client PEM file
cat apicast-client.key apicast-client.crt > apicast-client.pem

########

# GRPC
GRPC_ROUTE=$2

## Generate self signed root CA cert
openssl req -nodes -x509 -newkey rsa:2048 -keyout grpc-ca.key -out grpc-ca.crt -subj "/C=AU/ST=NSW/L=Sydney/O=MongoDB/OU=root/CN=${GRPC_ROUTE}/emailAddress=test@t.com"

## Generate server cert to be signed
openssl req -nodes -newkey rsa:2048 -keyout grpc-server.key -out grpc-server.csr -subj "/C=AU/ST=NSW/L=Sydney/O=MongoDB/OU=server/CN=${GRPC_ROUTE}/emailAddress=test@t.com"

## Sign the server cert
openssl x509 -req -in grpc-server.csr -CA grpc-ca.crt -CAkey grpc-ca.key -CAcreateserial -out grpc-server.crt

## Create server PEM file
cat grpc-server.key grpc-server.crt > grpc-server.pem


## Generate client cert to be signed
openssl req -nodes -newkey rsa:2048 -keyout grpc-client.key -out grpc-client.csr -subj "/C=AU/ST=NSW/L=Sydney/O=MongoDB/OU=client/CN=${APICAST_ROUTE}/emailAddress=test@t.com"

## Sign the client cert
openssl x509 -req -in grpc-client.csr -CA grpc-ca.crt -CAkey grpc-ca.key -CAserial grpc-ca.srl -out grpc-client.crt

## Create client PEM file
cat grpc-client.key grpc-client.crt > grpc-client.pem



