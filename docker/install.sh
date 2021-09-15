#!/bin/bash

echo "I installing CWMS Database with the following parameters"
echo "DB HOST_PORT: $DB_HOST_PORT"
echo "DB NAME: $DB_NAME"
echo "OFFICE_ID: $OFFICE_ID"
if [ "$CWMS_PASSWORD" ==  "" ]
then
    export CWMS_PASSWORD=`tr -cd '[:alnum:]' < /dev/urandom | fold -w25 | head -n1`
fi
echo "CWMS PASSWORD: $CWMS_PASSWORD"

if [ "$DB_HOST_PORT" == "" ]
then
    echo "Database host and port (-e DB_HOST_PORT=<hostname>:<port number>) must be supplied"
    exit 1
fi
export SUB_DB_NAME=$DB_NAME
if [ "$DB_NAME" == "" ]
then
    echo "Database name must be specified ( -e DB_NAME=<container or pluggable db name> )"
    echo " include the : or / as appropriate"
    exit 1
elif [[ "$DB_NAME" =~ ^\/.* ]]
then
    echo "Adding escape character"
    export SUB_DB_NAME="\\$DB_NAME"
fi

if [ "$SYS_PASSWORD" == "" ]
then
    echo "SYS password for database must be supplied (-e SYS_PASSWORD=<pw> )"
    exit 1
fi

if [ "$BUILDUSER_PASSWORD" == "" ]
then
    export BUILDUSER_PASSWORD=`tr -cd '[:alnum:]' < /dev/urandom | fold -w25 | head -n1`
    #echo "Build user password must be supplied ( -e BUILDUSER_PASSWORD=<pw> )"
    #exit 1
fi


echo $DB_NAME
sed -e "s/HOST_AND_PORT/$DB_HOST_PORT/g" \
    -e "s/\/SERVICE_NAME/$SUB_DB_NAME/g" \
    -e "s/BUILDUSER_PASS/$BUILDUSER_PASSWORD/g" \
    -e "s/OFFICE_ID/$OFFICE_ID/g" \
    -e "s/OFFICE_CODE/L2/g" \
    -e "s/TEST_ACCOUNT_FLAG/-testaccount/g" \
    -e "s/SYS_PASSWORD/$SYS_PASSWORD/g" \
    -e "s/PASSWORD/$CWMS_PASSWORD/g" /cwmsdb/teamcity_overrides.xml > /overrides.xml
 # TODO: create lookup system for office code

cat /overrides.xml

cd /cwmsdb
echo "Creating table spaces at sys/$SYS_PASSWORD@$DB_HOST_PORT$DB_NAME as sysdba"
sqlplus sys/$SYS_PASSWORD@$DB_HOST_PORT$DB_NAME as sysdba @src/windows_tablespaces.sql



echo "Installing APEX"
cd /opt/apex/apex
sqlplus sys/$SYS_PASSWORD@$DB_HOST_PORT$DB_NAME as sysdba <<END
    create tablespace apex datafile 'apex01.dat' size 100M autoextend on next 1M;
END

sqlplus sys/$SYS_PASSWORD@$DB_HOST_PORT$DB_NAME as sysdba @apexins.sql APEX APEX TEMP /i/

echo "Installing CWMS Schema"
cd /cwmsdb
ant -Dbuilduser.overrides=/overrides.xml clean build
if [ $? -eq 0 ]; then
    echo "CWMS USER PASSWORD: $CWMS_PASSWORD"
    exit 0
else
    exit 1
fi