FROM ubuntu:22.04
LABEL MAINTAINER="CWMS DB Team"
ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get -y update && \
    apt-get -y upgrade && \
    apt-get -y install wget git \
               zip unzip \
               openjdk-8-jdk \
               libaio1 python2 python3 \
               ant

RUN ln -s /usr/lib/jvm-1.8.0.openjdk-amd64 /usr/lib/jvm/java

RUN mkdir /opt/oracle
WORKDIR /opt/oracle
RUN wget https://download.oracle.com/otn_software/linux/instantclient/19600/instantclient-basiclite-linux.x64-19.6.0.0.0dbru.zip && \
    wget https://download.oracle.com/otn_software/linux/instantclient/19600/instantclient-tools-linux.x64-19.6.0.0.0dbru.zip && \
    wget https://download.oracle.com/otn_software/linux/instantclient/19600/instantclient-sqlplus-linux.x64-19.6.0.0.0dbru.zip
RUN unzip instantclient-basiclite-linux.x64-19.6.0.0.0dbru.zip && \
    unzip instantclient-tools-linux.x64-19.6.0.0.0dbru.zip && \
    unzip instantclient-sqlplus-linux.x64-19.6.0.0.0dbru.zip && \
    rm *.zip

#RUN mkdir /opt/apex
#WORKDIR /opt/apex
#RUN wget https://download.oracle.com/otn_software/apex/apex_23.2_en.zip
#RUN unzip apex_23.2_en.zip && \
#    rm *.zip

COPY . /cwmsdb

WORKDIR /cwmsdb/schema

ENV PATH=$PATH:/opt/oracle/instantclient_19_6
ENV LD_LIBRARY_PATH=/opt/oracle/instantclient_19_6

ENV OFFICE_ID=HQ
ENV OFFICE_EROC=Q0
ENV INSTALLONCE=0
ENV QUIET=0
ENV TEST_ACCOUNT=-testaccount

RUN chmod +x ./docker/install.sh

CMD ["/cwmsdb/schema/docker/install.sh"]