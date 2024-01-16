#!/bin/bash

#-Dzookeeper.sasl.client=true  -Djava.security.auth.login.config=$KAFKA_HOME/config/zookeeper_jaas.conf
KAFKA_SCRAM_LOGIN_AUTH=org.apache.kafka.common.security.scram.ScramLoginModule
export KAFKA_OPTS="-Djava.security.auth.login.config=$KAFKA_HOME/config/kafka_server_jaas.conf"
mkdir -p $ZK_DATADIR && echo $KAFKA_BROKER_ID > $ZK_DATADIR/myid

cp $KAFKA_HOME/config/kafka-server.properties $KAFKA_HOME/config/kafka-server.properties.bkp
sed -i "s|admin-secret|$KAFKA_ADMIN_PASSWORD|g" $KAFKA_HOME/config/kafka-server.properties
sed -i "s|admin|$KAFKA_ADMIN_USER|g" $KAFKA_HOME/config/kafka-server.properties
sed -i "s|log.dirs=/tmp/kafka-logs|log.dirs=$KAFKA_DATADIR|g" $KAFKA_HOME/config/kafka-server.properties


cp $KAFKA_HOME/config/zookeeper.properties $KAFKA_HOME/config/zookeeper.properties.bkp
sed -i "s|dataDir=/tmp/zookeeper|dataDir=$ZK_DATADIR|g" $KAFKA_HOME/config/zookeeper.properties
sed -i "s|clientPort=2181|clientPort=$ZK_PORT|g" $KAFKA_HOME/config/zookeeper.properties

readarray -d , -t strarr <<< "$KAFKA_ZK_CONNECT"
export KAFKA_BROKER_COUNT=1
if [ "${#strarr[*]}" -gt "0" ]; then
    KAFKA_BROKER_COUNT=${#strarr[*]}
fi

echo "KAFKA_BROKER_COUNT = $KAFKA_BROKER_COUNT"

sed -i "s|default.replication.factor=1|default.replication.factor=$KAFKA_BROKER_COUNT|g" $KAFKA_HOME/config/kafka-server.properties
echo "updating zookeeper configuration 1"
for (( n=1; n <= $KAFKA_BROKER_COUNT; n++))
do
  readarray -d : -t hostarr <<< "${strarr[n-1]}"
  if [ -z "${hostarr[0]##*( )}" ]
  then
      echo "Ignoring configuration as hostname is empty"
  else
     echo "s|server.$n=localhost:2888:3888|server.$n=${hostarr[0]##*( )}:2888:3888|g"
     sed -i "s|server.$n=localhost:2888:3888|server.$n=${hostarr[0]##*( )}:2888:3888|g" $KAFKA_HOME/config/zookeeper.properties
  fi
  
done
echo "updating zookeeper configuration 2"
for (( n=2; n <= 11; n++))
do
  sed -i "s|server.$n=localhost:2888:3888| |g" $KAFKA_HOME/config/zookeeper.properties
  sed -i "s|authProvider.$n=org.apache.zookeeper.server.auth.SASLAuthenticationProvider| |g" $KAFKA_HOME/config/zookeeper.properties
done

echo "Zookeeper Properties"
echo "--------------------------------------"
cat $KAFKA_HOME/config/zookeeper.properties
echo "======================================"

cp $KAFKA_HOME/config/kafka_server_jaas.conf $KAFKA_HOME/config/kafka_server_jaas.conf.bkp
sed -i "s|admin-secret|$KAFKA_ADMIN_PASSWORD|g" $KAFKA_HOME/config/kafka_server_jaas.conf
sed -i "s|admin|$KAFKA_ADMIN_USER|g" $KAFKA_HOME/config/kafka_server_jaas.conf

cp $KAFKA_HOME/config/zookeeper_jaas.conf $KAFKA_HOME/config/zookeeper_jaas.conf.bkp
sed -i "s|admin-secret|$KAFKA_ADMIN_PASSWORD|g" $KAFKA_HOME/config/zookeeper_jaas.conf
sed -i "s|admin|$KAFKA_ADMIN_USER|g" $KAFKA_HOME/config/zookeeper_jaas.conf

cp $KAFKA_HOME/config/ssl-user-config.properties $KAFKA_HOME/config/ssl-user-config.properties.bkp
sed -i "s|admin-secret|$KAFKA_ADMIN_PASSWORD|g" $KAFKA_HOME/config/ssl-user-config.properties
sed -i "s|admin|$KAFKA_ADMIN_USER|g" $KAFKA_HOME/config/ssl-user-config.properties

$KAFKA_HOME/bin/zookeeper-server-start.sh $KAFKA_HOME/config/zookeeper.properties  &
$KAFKA_HOME/bin/kafka-configs.sh --zookeeper $KAFKA_ZK_CONNECT --alter --add-config 'SCRAM-SHA-512=[password='$KAFKA_ADMIN_PASSWORD']' --entity-type users --entity-name $KAFKA_ADMIN_USER &&
# $KAFKA_HOME/bin/kafka-configs.sh --zookeeper $KAFKA_ZK_CONNECT --alter --add-config 'SCRAM-SHA-512=[password='secret']' --entity-type users --entity-name demouser &&
$KAFKA_HOME/bin/kafka-server-start.sh $KAFKA_HOME/config/kafka-server.properties \
     --override broker.id=$KAFKA_BROKER_ID \
     --override listeners=$KAFKA_LISTENERS \
     --override zookeeper.connect=$KAFKA_ZK_CONNECT \
     --override advertised.listeners=$KAFKA_ADVERTISED_LISTENERS 