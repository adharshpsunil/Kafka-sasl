FROM openjdk:11-jre-slim

ARG kafka_version=3.1.0
ARG scala_version=2.13

LABEL org.label-schema.name="kafka" \
      org.label-schema.description="Apache Kafka" \
      org.label-schema.version="${scala_version}_${kafka_version}" \
      org.label-schema.schema-version="1.0" 


ENV KAFKA_VERSION=$kafka_version \
    SCALA_VERSION=$scala_version \
    KAFKA_HOME=/opt/kafka

ENV PATH=${PATH}:${KAFKA_HOME}/bin

RUN set -eux && \
    apt-get update && \
    apt-get install -y --no-install-recommends jq net-tools curl wget

RUN cd /tmp && \
    wget https://archive.apache.org/dist/kafka/$KAFKA_VERSION/kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz && \
    tar xzf kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz && \
    rm kafka_$SCALA_VERSION-$KAFKA_VERSION.tgz && \
    mv kafka_$SCALA_VERSION-$KAFKA_VERSION $KAFKA_HOME

ENV  ZK_DATADIR="/tmp/zookeeper"
ENV  KAFKA_DATADIR="/tmp/kafka"
ENV  ZK_PORT="2181"
ENV  KAFKA_BROKER_ID=1
# ENV  KAFKA_PORT="9093"   
ENV  KAFKA_LISTENERS="PLAINTEXT://localhost:9092,SASL_PLAINTEXT://$HOSTNAME:9093"
ENV  KAFKA_ADVERTISED_LISTENERS="SASL_PLAINTEXT://$HOSTNAME:9093"
ENV  KAFKA_ZK_CONNECT="$HOSTNAME:$ZK_PORT"
ENV  KAFKA_ADMIN_USER="admin"
ENV  KAFKA_ADMIN_PASSWORD="6dAdmin6D"


COPY ./scripts/start-kafka-server.sh $KAFKA_HOME/bin/start-kafka-server.sh
COPY ./configs/kafka-server.properties $KAFKA_HOME/config/kafka-server.properties
COPY ./configs/zookeeper.properties $KAFKA_HOME/config/zookeeper.properties
COPY ./configs/kafka_server_jaas.conf $KAFKA_HOME/config/kafka_server_jaas.conf
COPY ./configs/zookeeper_jaas.conf $KAFKA_HOME/config/zookeeper_jaas.conf
COPY ./configs/ssl-user-config.properties $KAFKA_HOME/config/ssl-user-config.properties
RUN sed -i 's/\r$//' $KAFKA_HOME/bin/start-kafka-server.sh
RUN  chmod +x $KAFKA_HOME/bin/start-kafka-server.sh
# EXPOSE 2181 9092 9093


CMD [ "sh","-c", "$KAFKA_HOME/bin/start-kafka-server.sh"]
# CMD ["bash"]