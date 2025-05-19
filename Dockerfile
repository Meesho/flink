FROM eclipse-temurin:17-jdk-jammy as builder

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    git \
    wget \
    curl \
    unzip \
    && rm -rf /var/lib/apt/lists/*

ENV MAVEN_VERSION=3.8.6
ENV MAVEN_HOME=/usr/share/maven

RUN wget https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz -P /tmp && \
    tar xzf /tmp/apache-maven-${MAVEN_VERSION}-bin.tar.gz -C /opt && \
    ln -s /opt/apache-maven-${MAVEN_VERSION} ${MAVEN_HOME} && \
    ln -s ${MAVEN_HOME}/bin/mvn /usr/bin/mvn && \
    rm -f /tmp/apache-maven-${MAVEN_VERSION}-bin.tar.gz

ENV FLINK_HOME=/opt/flink

WORKDIR /flink-src

COPY . .

RUN ./mvnw clean package -DskipTests -Djdk17 -Pjava17-target

FROM eclipse-temurin:17-jre-jammy

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    curl \
    bash \
    libsnappy1v5 \
    && rm -rf /var/lib/apt/lists/*

ENV FLINK_HOME=/opt/flink
ENV PATH=$PATH:$FLINK_HOME/bin

COPY --from=builder /flink-src/build-target /opt/flink

EXPOSE 8081

WORKDIR $FLINK_HOME

CMD ["bash", "-c", "bin/start-cluster.sh && tail -f /opt/flink/log/*.log"] 
