check_deps() {
  which jq > /dev/null || { echo "Need to install jq" && exit 1; }
  which curl > /dev/null || { echo "Need to install curl" && exit 1; }
}

await_zk() {  
  EXHIBITOR_URL=$1
  EXHIBITOR_STATUS_URL="${EXHIBITOR_URL}exhibitor/v1/cluster/status"

  echo "Waiting for ZooKeeper"
  printf "Polling Exhibitor ($EXHIBITOR_STATUS_URL) ..."
  
  until $(curl --output /dev/null --silent --head --fail ${EXHIBITOR_STATUS_URL}); do
    printf '.'
    sleep 2
  done
  
  ZK_HOST_CMD="curl --silent --fail ${EXHIBITOR_STATUS_URL} | jq '.[] | select(.code == 3) | .hostname' -r"
  ZK_HOST=$(eval $ZK_HOST_CMD)
  if [ -z "$ZK_HOST" ]; then
    printf "\nZooKeeper is launched.\nWaiting for ZooKeeper to be initialized..."
  fi
  until [ -n "$ZK_HOST" ]; do
    printf '.'
    sleep 2
    ZK_HOST=$(eval $ZK_HOST_CMD)
  done
  
  printf "\nZooKeeper with Exhibitor is ready\n"
}

await_kafka() {
  EXHIBITOR_URL=$1
  MIN_BROKERS=$2
  EXHIBITOR_KAFKA_BROKERS_URL="${EXHIBITOR_URL}exhibitor/v1/explorer/node?key=%2Fbrokers%2Fids"

  echo "Waiting for at least ${MIN_BROKERS} Kafka brokers"
  
  ACTIVE_BROKERS_CMD="curl --silent "${EXHIBITOR_KAFKA_BROKERS_URL}" | jq 'length'"
  ACTIVE_BROKERS=$(eval $ACTIVE_BROKERS_CMD)
  
  until [ "$ACTIVE_BROKERS" -ge "$MIN_BROKERS" ]; do
    echo "Active Kafka brokers: $ACTIVE_BROKERS"
    sleep 2
    ACTIVE_BROKERS=$(eval $ACTIVE_BROKERS_CMD)
  done
  
  echo "Kafka is ready"
}

check_deps