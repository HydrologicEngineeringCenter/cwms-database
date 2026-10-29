FROM ubuntu:26.10
LABEL MAINTAINER="CWMS DB Team"
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install wget git \
               zip unzip \
               openjdk-11-jdk \
               libaio1t64 python3 \
               ant \
               --no-install-recommends \
    && rm -rf /var/lib/apt/lists/* \
    && ln -s /usr/lib/jvm-1.11.0.openjdk-amd64 /usr/lib/jvm/java

# always start fresh
RUN mkdir /opt/oracle && rm -rf /opt/oracle/*
WORKDIR /opt/oracle
RUN wget https://download.oracle.com/otn_software/linux/instantclient/1933000/instantclient-basiclite-linux.x64-19.33.0.0.0dbru.zip && \
    wget https://download.oracle.com/otn_software/linux/instantclient/1933000/instantclient-tools-linux.x64-19.33.0.0.0dbru.zip && \
    wget https://download.oracle.com/otn_software/linux/instantclient/1933000/instantclient-sqlplus-linux.x64-19.33.0.0.0dbru.zip && \
    unzip -o instantclient-basiclite-linux.x64-19.33.0.0.0dbru.zip && \
    unzip -o instantclient-tools-linux.x64-19.33.0.0.0dbru.zip && \
    unzip -o instantclient-sqlplus-linux.x64-19.33.0.0.0dbru.zip && \
    rm *.zip && \
    ln -sf /usr/lib/x86_64-linux-gnu/libaio.so.1t64 /opt/oracle/instantclient_19_33/libaio.so.1
RUN mkdir /after.install.d

COPY . /cwmsdb
WORKDIR /cwmsdb
ARG branch
RUN if [ "${branch}" != "" ]; then sed -i "s/99.99.99-SNAPSHOT/${branch}/" pom.xml; fi
WORKDIR /cwmsdb/schema

ENV PATH=$PATH:/opt/oracle/instantclient_19_33
ENV LD_LIBRARY_PATH=/opt/oracle/instantclient_19_33

ENV OFFICE_ID=HQ
ENV OFFICE_EROC=Q0
ENV INSTALLONCE=0
ENV QUIET=0
ENV TEST_ACCOUNT=-testaccount

RUN chmod +x ./docker/install.sh

CMD ["/cwmsdb/schema/docker/install.sh"]