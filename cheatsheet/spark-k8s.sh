#!/bin/bash

SPARK_DRIVER_NAME=$(whoami)-driver
export SPARK_DRIVER_NAME

export SPARK_DRIVER_PORT=7078
export SPARK_DRIVER_BM_PORT=7079
export SERVICE_ACCOUNT=spark-custom-runs
export SPARK_NAMESPACE=data-custom-runs
export DOCKER_IMAGE=some.docker.repo/spark:3.5.5

export ICEBERG_INVENTORY_CATALOG=icebergInventory
export DELTA_INVENTORY_CATALOG=spark_catalog

export K8S_master=k8s://k8s.url.here:443

ICEBERG_WAREHOUSE_PATH=s3a:/my-bucket/iceberg
export ICEBERG_WAREHOUSE_PATH
DELTA_WAREHOUSE_PATH=s3a://my-bucket/delta
export DELTA_WAREHOUSE_PATH

JAR_PATH=s3a://myjar.jar
export JAR_PATH

export FULL_COMMAND="/opt/spark/bin/spark-shell --name $SPARK_DRIVER_NAME \
                                                --master  \
                                                --deploy-mode client \
                                                --jars $JAR_PATH \
                                                --conf spark.kubernetes.driver.pod.name=$SPARK_DRIVER_NAME  \
                                                --conf spark.kubernetes.authenticate.driver.serviceAccountName=$SERVICE_ACCOUNT  \
                                                --conf spark.kubernetes.namespace=$SPARK_NAMESPACE  \
                                                --conf spark.hadoop.fs.s3a.impl=org.apache.hadoop.fs.s3a.S3AFileSystem \
                                                --conf spark.hadoop.fs.s3a.path.style.access=true \
                                                --conf spark.hadoop.fs.s3a.connection.ssl.enabled=true \
                                                --conf spark.hadoop.fs.s3a.aws.credentials.provider=com.amazonaws.auth.WebIdentityTokenCredentialsProvider \
                                                --conf spark.hadoop.fs.s3a.connection.maximum=500 \
                                                --conf spark.hadoop.fs.s3a.threads.max=256 \
                                                --conf spark.hadoop.fs.s3a.connection.timeout=600000 \
                                                --conf spark.hadoop.fs.s3a.endpoint=s3-eu-west-1.amazonaws.com \
                                                --conf spark.executor.instances=2  \
                                                --conf spark.executor.cores=15  \
                                                --conf spark.executor.memory=48g  \
                                                --conf spark.driver.cores=8  \
                                                --conf spark.driver.memory=16g  \
                                                --conf spark.kubernetes.container.image=$DOCKER_IMAGE  \
                                                --conf spark.driver.port=$SPARK_DRIVER_PORT \
                                                --conf spark.driver.blockManager.port=$SPARK_DRIVER_BM_PORT \
                                                --conf spark.kubernetes.container.image.pullPolicy=Always \
                                                --conf spark.sql.catalog.$ICEBERG_INVENTORY_CATALOG=org.apache.iceberg.spark.SparkCatalog \
                                                --conf spark.sql.catalog.$ICEBERG_INVENTORY_CATALOG.type=hadoop \
                                                --conf spark.sql.catalog.$ICEBERG_INVENTORY_CATALOG.warehouse=$ICEBERG_WAREHOUSE_PATH \
                                                --conf spark.sql.extensions=org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions,io.delta.sql.DeltaSparkSessionExtension \
                                                --conf spark.sql.catalog.$DELTA_INVENTORY_CATALOG=org.apache.spark.sql.delta.catalog.DeltaCatalog \
                                                --conf spark.sql.warehouse.dir=$DELTA_WAREHOUSE_PATH \
                                                --conf spark.driver.extraJavaOptions=-Dfile.encoding=utf-8"

export JSON_OVERRIDE='{"spec":{"serviceAccount":'\"$SERVICE_ACCOUNT\"'}}'

kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: $SPARK_DRIVER_NAME
  namespace: $SPARK_NAMESPACE
  labels:
    run: $SPARK_DRIVER_NAME
spec:
  clusterIP: None   # This makes it a headless service
  ports:
  - name: driver-rpc-port
    port: $SPARK_DRIVER_PORT
    targetPort: $SPARK_DRIVER_PORT
  - name: blockmanager
    port: $SPARK_DRIVER_BM_PORT
    targetPort: $SPARK_DRIVER_BM_PORT
  - name: spark-ui
    port: 4040
    targetPort: 4040
  selector:
    run: $SPARK_DRIVER_NAME
  type: ClusterIP
EOF

kubectl run $SPARK_DRIVER_NAME -it --rm=true \
  --namespace $SPARK_NAMESPACE \
  --overrides=$JSON_OVERRIDE \
  --image=$DOCKER_IMAGE \
  --command -- $FULL_COMMAND

kubectl delete svc $SPARK_DRIVER_NAME -n $SPARK_NAMESPACE