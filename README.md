# GRPC Guide for APICast (Red Hat API Management - 3scale)

> * Forked: https://github.com/3scale-demos/apicast-demo-apps

> * If you want to create the certificates read [this](README-certificates.md)

This guide explain how to setup GRPC calls on APICast server on Openshift

If you want to view the **<u>logs</u>** created check the folder [logs](./logs/)

> We tested it using:
>
> * Openshift `4.10.x`
>
> * APICast version: [2.12](https://catalog.redhat.com/software/containers/3scale-amp2/apicast-gateway-rhel8/5df398c85a13466876712703?tag=1.21.0-74.1666687674&push_date=1666737470000)



## Project Folder Structure

```shell
├── README-certificates.md
├── README.md
├── certs/
│   ├── ca.key
│   ├── ca.pem
│   ├── server.key
│   └── server.pem
├── k8s/
│   ├── apicast.yaml
│   ├── client.yaml
│   ├── endpoint.yaml
│   └── kustomization.yaml
├── logs/
└── source/
    └── grpc-helloworld/
        ├── .dockerignore
        ├── README.md
        ├── mvnw*
        ├── mvnw.cmd*
        ├── pom.xml
        └── src/
            └── main/
                ├── docker/
                │   ├── Dockerfile.jvm
                │   ├── Dockerfile.legacy-jar
                │   ├── Dockerfile.native
                │   └── Dockerfile.native-micro
                ├── java/
                │   └── com/
                │       └── redhat/
                │           └── example/
                │               └── HelloService.java
                ├── proto/
                │   └── helloworld.proto
                └── resources/
                    └── application.properties
```



# Installation

Openshift is needed to run this example:

```shell
# create a project to deploy this example
❯ oc new-project grpc-guide-with-3scale-problem

# deploy the resources on cluster
❯ oc kustomize k8s | oc apply -f -
```

> If you want to see all artifacts created

```shell
# check that ALL pods are Running!
❯ oc get cm,all -l app=grpc-guide

# check that GRPC Service is UP and RUNNING
❯ oc logs -f pod/grpc-endpoint --tail=5
2023-01-19 18:49:20,825 INFO  [io.qua.grp.run.GrpcSslUtils] (vert.x-eventloop-thread-0) Disabling gRPC plain-text as the SSL certificate is configured
2023-01-19 18:49:21,429 INFO  [io.qua.grp.run.GrpcServerRecorder] (vert.x-eventloop-thread-2) gRPC Server started on 0.0.0.0:9000 [SSL enabled: true]
2023-01-19 18:49:21,482 INFO  [io.quarkus] (main) grpc-helloworld 1.0.0 on JVM (powered by Quarkus 2.14.2.Final) started in 1.803s. 
2023-01-19 18:49:21,483 INFO  [io.quarkus] (main) Profile prod activated. 
2023-01-19 18:49:21,483 INFO  [io.quarkus] (main) Installed features: [cdi, grpc-server, smallrye-context-propagation, vertx]
```

## Change the Service to Route URL

```shell
# get the ROUTE url
❯ GRPC_ROUTE=$(oc get route -o jsonpath='{.spec.host}' grpc-route)

❯ grep 'api_backend' k8s/apicast.yaml
            "api_backend": "https://grpc-service:443",

❯ sed "s|https://grpc-service:443|https://$GRPC_ROUTE|g" k8s/apicast.yaml > k8s/apicast-with_route.yaml

❯ grep 'api_backend' k8s/apicast-with_route.yaml
            "api_backend": "https://grpc-route-grpc-guide-with-3scale-problem.apps.xxx",

❯ diff k8s/apicast.yaml k8s/apicast-with_route.yaml
26c26
<             "api_backend": "https://grpc-service:443",
---
>             "api_backend": "https://grpc-route-grpc-guide-with-3scale-problem.apps.xxx",
```

#### Deploy the APICast using the Route

```shell
❯ oc apply -f k8s/apicast-with_route.yaml
configmap/apicast-config created
deployment.apps/apicast created
service/apicast-service created
route.route.openshift.io/apicast-route created
pod/apicast-api-server created
service/server-service created
```



## Testing Connectivity

### TARGET=`apicast-service`

```shell
TARGET=apicast-service
TARGET_PORT=8043
```


1. **list** grpc services

   ```shell
   ❯ oc exec -ti client -- grpcurl -import-path . -proto /config/helloworld.proto -insecure $TARGET:$TARGET_PORT list
   helloworld.Greeter
   ```

2. **describe** the services listed

   ```shell
   ❯ oc exec -ti client -- grpcurl -import-path . -proto /config/helloworld.proto -insecure $TARGET:$TARGET_PORT describe helloworld.Greeter
   helloworld.Greeter is a service:
   // The greeting service definition.
   service Greeter {
     // Sends a greeting
     rpc SayHello ( .helloworld.HelloRequest ) returns ( .helloworld.HelloReply );
   }
   ```

3. **Call** the service **without** parameters

   > Expect to get `401 (Unauthorized)`

   ```shell
   ❯ oc exec -ti client -- grpcurl -import-path . -proto /config/helloworld.proto -insecure $TARGET:$TARGET_PORT helloworld.Greeter/SayHello
   ERROR:
     Code: Unauthenticated
     Message: unexpected HTTP status code received from server: 401 (Unauthorized); transport: received unexpected content-type "text/plain; charset=utf-8"
   command terminated with exit code 80
   ```

4. **Call** the service **without** parameters and **with** the `user_key=anything`

   ```shell
   ❯ oc exec -ti client -- grpcurl -H "user_key: test" -import-path . -proto /config/helloworld.proto -insecure $TARGET:$TARGET_PORT helloworld.Greeter/SayHello
   {
     "message": "Hello  have a great day!"
   }
   ```

5. Call the service **with** parameters and **with** the `user_key=anything`

   ```shell
   ❯ oc exec -ti client -- grpcurl -vv -H "user_key: test" -d '{"name": "Bob"}' -import-path . -proto /config/helloworld.proto -insecure $TARGET:$TARGET_PORT helloworld.Greeter/SayHello
   
   Resolved method descriptor:
   // Sends a greeting
   rpc SayHello ( .helloworld.HelloRequest ) returns ( .helloworld.HelloReply );
   
   Request metadata to send:
   user_key: test
   
   Response headers received:
   (empty)
   
   Response trailers received:
   (empty)
   Sent 1 request and received 0 responses
   ERROR:
     Code: Unavailable
     Message: unexpected HTTP status code received from server: 503 (Service Unavailable); transport: received unexpected content-type "text/html"
   command terminated with exit code 78
   ```

   **At log folder you have**:

   * [apicast-error_using_route.log](logs/apicast-error_using_route.log)
   * [apicast-sucess_using_service.log](logs/apicast-sucess_using_service.log)



# Cleanup

> Delete the project created with all configuration

```shell
❯ oc delete project grpc-guide-with-3scale
```

