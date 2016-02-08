#!/bin/bash

sr_cfg_file="/etc/schema-registry/schema-registry.properties"

: ${SCHEMA_REGISTRY_PORT:=8081}
: ${SCHEMA_REGISTRY_KAFKASTORE_TOPIC:=_schemas}
: ${SCHEMA_REGISTRY_KAFKASTORE_CONNECTION_URL:=$ZOOKEEPER_PORT_2181_TCP_ADDR:$ZOOKEEPER_PORT_2181_TCP_PORT}
: ${SCHEMA_REGISTRY_DEBUG:=false}
: ${KAFKA_PORT:=tcp://$KAFKA_PORT_9092_TCP_ADDR:$KAFKA_PORT_9092_TCP_PORT}
: ${ZOOKEEPER_PORT:=tcp://$SCHEMA_REGISTRY_KAFKASTORE_CONNECTION_URL}

export SCHEMA_REGISTRY_PORT
export SCHEMA_REGISTRY_KAFKASTORE_TOPIC
export SCHEMA_REGISTRY_KAFKASTORE_CONNECTION_URL
export SCHEMA_REGISTRY_DEBUG

# Download the config file, if given a URL
if [ ! -z "$SR_CFG_URL" ]; then
  echo "[SR] Downloading SR config file from ${SR_CFG_URL}"
  curl --location --silent --insecure --output ${sr_cfg_file} ${SR_CFG_URL}
  if [ $? -ne 0 ]; then
    echo "[SR] Failed to download ${SR_CFG_URL} exiting."
    exit 1
  fi
fi

echo '# Generated by schema_registry-docker.sh' > ${sr_cfg_file}
for var in $(env | grep '^SCHEMA_REGISTRY_' | sort); do
  key=$(echo $var | sed -r 's/SCHEMA_REGISTRY_(.*)=.*/\1/g' | tr A-Z a-z | tr _ .)
  value=$(echo $var | sed -r 's/.*=(.*)/\1/g')
  echo "${key}=${value}" >> ${sr_cfg_file}
done

dockerize -wait $ZOOKEEPER_PORT -wait $KAFKA_PORT

exec /usr/bin/schema-registry-start ${sr_cfg_file}
