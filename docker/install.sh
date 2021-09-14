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

if [ "$DB_NAME" == "" ]
then
    echo "Database name must be specified ( -e DB_NAME=<container or pluggable db name> )"
    echo " include the : or / as appropriate"
    exit 1
elif [[ "$DB_NAME" =~ ^\/.* ]]
then
    echo "Adding escape character"
    export DB_NAME="\\$DB_NAME"
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
    -e "s/\/SERVICE_NAME/$DB_NAME/g" \
    -e "s/BUILDUSER_PASS/$BUILDUSER_PASSWORD/g" \
    -e "s/OFFICE_ID/$OFFICE_ID/g" \
    -e "s/OFFICE_CODE/Q0/g" \
    -e "s/TEST_ACCOUNT_FLAG/-NOTESTACCOUNT/g" \
    -e "s/SYS_PASSWORD/$SYS_PASSWORD/g" \
    -e "s/PASSWORD/$CWMS_PASSWORD/g" /cwmsdb/teamcity_overrides.xml > /overrides.xml
 # TODO: create lookup system for office code

cat /overrides.xml

cd /cwmsdb
ant -Dbuilduser.overrides=/overrides.xml clean build
if [ $? -eq 0 ]; then
    echo "CWMS USER PASSWORD: $CWMS_PASSWORD"
    exit 0
else
    exit 1
fi