#!/bin/bash

echo "I'm installing CWMS Database with the following parameters"
echo "DB HOST_PORT: $DB_HOST_PORT"
echo "DB NAME: $DB_NAME"
echo "OFFICE_ID: $OFFICE_ID"
echo "OFFICE_EROC: $OFFICE_EROC"
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

cd /cwmsdb/schema

echo $DB_NAME
sed -e "s/HOST_AND_PORT/$DB_HOST_PORT/g" \
    -e "s/\/SERVICE_NAME/$SUB_DB_NAME/g" \
    -e "s/BUILDUSER_PASS/$BUILDUSER_PASSWORD/g" \
    -e "s/OFFICE_ID/$OFFICE_ID/g" \
    -e "s/OFFICE_CODE/$OFFICE_EROC/g" \
    -e "s/TEST_ACCOUNT_FLAG/-testaccount/g" \
    -e "s/SYS_PASSWORD/$SYS_PASSWORD/g" \
    -e "s/PASSWORD/$CWMS_PASSWORD/g" teamcity_overrides.xml > /overrides.xml
 # TODO: create lookup system for office code

cat /overrides.xml
TABLESPACE_DIR="/opt/oracle/oradata"
echo "Installing APEX"
cd /opt/apex/apex
sqlplus sys/$SYS_PASSWORD@$DB_HOST_PORT$DB_NAME as sysdba <<END
    alter system set db_create_file_dest = '/opt/oracle/oradata';
    create tablespace apex datafile '/opt/oracle/oradata/apex01.dat' size 100M autoextend on next 1M;
END

sqlplus sys/$SYS_PASSWORD@$DB_HOST_PORT$DB_NAME as sysdba @apexins.sql APEX APEX TEMP /i/

echo "Creating table spaces at sys/$SYS_PASSWORD@$DB_HOST_PORT$DB_NAME as sysdba"
sqlplus sys/$SYS_PASSWORD@$DB_HOST_PORT$DB_NAME as sysdba <<END
    CREATE TABLESPACE "CWMS_20AT_DATA" DATAFILE '/opt/oracle/oradata/at_data.dat' size 20M autoextend on next 10M;
    CREATE TABLESPACE "CWMS_20DATA" DATAFILE '/opt/oracle/oradata/data.dat' size 20M autoextend on next 10M;
    CREATE TABLESPACE "CWMS_20_TSV" DATAFILE '/opt/oracle/oradata/tsv.dat' size 20M autoextend on next 10M;
    CREATE TABLESPACE "CWMS_AQ" DATAFILE '/opt/oracle/oradata/aq.dat' size 20M autoextend on next 10M;
    CREATE TABLESPACE "CWMS_AQ_EX" DATAFILE '/opt/oracle/oradata/aq_ex.dat' size 20M autoextend on next 10M;

END

echo "Installing CWMS Schema"
cd /cwmsdb/schema
if [ "$INSTALLONCE" == "1" ]; then
    echo "Running only build task"
    ant -Dbuilduser.overrides=/overrides.xml build
    build_ret=$?
else
    echo "Running clean build tasks"
    ant -Dbuilduser.overrides=/overrides.xml clean build
    build_ret=$?
fi

if [ "$QUIET" == 0 ]; then
    echo "Build Files contents are"
    echo "buildCWMS_DB.log:"
    echo "=================="
    cat src/buildCWMS_DB.log
    echo "=================="
    echo "other build .txt files"
    for f in `ls *.txt`; do
        echo "$f:"
        echo "==============="
        cat $f
        echo "==============="
    done
fi

echo "ret val: $build_ret"
if [ $build_ret -eq 0 ]; then
    echo "CWMS USER PASSWORD: $CWMS_PASSWORD"
    exit 0
elif [ $build_ret -eq 50 ]; then
    # password would've already been set
    exit 0
else
    exit 1
fi
