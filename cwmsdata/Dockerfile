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

# entrypoint arguments:
#   -a: keep the container alive
#   -s: run usgs-sites with arguments
#   -t: run usgs-ts with arguments
#   -c: the string of arguments the above takes
#
#   follow the CMD below and add/remove hub and codes.  Space delimited
#   list of huc and codes accepted.  Follow USGS huc https://water.usgs.gov/GIS/huc_name.html
#   only using 2 or 8 huc.
#

# CMD [ "-s", "-c", "--huc 05130101 05130102 05130103 --parameter_code 00060 00065" ]
