FROM ubuntu:20.04

RUN apt-get update && \
    apt-get -y install python3 python3-pip zip unzip wget libaio1

RUN mkdir -p /opt/oracle
WORKDIR /opt/oracle
RUN wget https://download.oracle.com/otn_software/linux/instantclient/1917000/instantclient-basic-linux.x64-19.17.0.0.0dbru.zip && \
    wget https://download.oracle.com/otn_software/linux/instantclient/1917000/instantclient-tools-linux.x64-19.17.0.0.0dbru.zip && \
    wget https://download.oracle.com/otn_software/linux/instantclient/1917000/instantclient-sqlplus-linux.x64-19.17.0.0.0dbru.zip && \
    unzip -U instantclient-basic-linux.x64-19.17.0.0.0dbru.zip && \
    unzip -U instantclient-tools-linux.x64-19.17.0.0.0dbru.zip && \
    unzip -U instantclient-sqlplus-linux.x64-19.17.0.0.0dbru.zip && \
    rm -rf *.zip


RUN echo "/opt/oracle/instantclient_19_17" > /etc/ld.so.conf.d/oracle.conf && ldconfig

ENV LD_LIBRARY_PATH=/opt/oracle/instantclient_19_17:${LD_LIBRARY_PATH}

ENV PATH=${LD_LIBRARY_PATH}:${PATH}

RUN mkdir -p /cwmsdata

COPY . /cwmsdata

WORKDIR /cwmsdata

RUN pip install .

ENTRYPOINT [ "entrypoint.sh" ]
