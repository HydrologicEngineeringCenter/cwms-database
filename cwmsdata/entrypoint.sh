#!/bin/bash

# set -x

VERBOSE_LEVEL="vvv"
SLEEP_SEC=5

START=1
MAX_CONNECTION_TRY=3

db_statuscheck() {
    echo "$(date) :Checking DB connectivity...";
    sqlplus ${CWMS_USER}/${CWMS_PASSWORD}@${DB_HOST_PORT}${DB_NAME} | grep "Connected to:" > /dev/null
    if [ $? -eq 0 ]
    then
        echo "$(date) :Status: UP. Able to Connect..."
        export CWMS_DB_CONNECTED=true
    else
        echo "$(date) :Status: DOWN; Not able to Connect."
    fi
 }

echo "Start entrypoint"

# always checking the db connection; three times max
for (( i=$START; i<=$MAX_CONNECTION_TRY; i++ ))
do
    db_statuscheck
    if [ $CWMS_DB_CONNECTED ]
    then
        DBUP=true
        break
    else
        echo "Sleep for $SLEEP_SEC seconds then try again."
        sleep $SLEEP_SEC
    fi
done

# check the things we want to do
for arg in "$@"
do
    [ "$arg" == "usgs-sites" ] && USGS_SITES=true
    [ "$arg" == "usgs-ts" ] && USGS_TS=true
done

if [ "$DBUP" == "true" ]
then
    switch="-$VERBOSE_LEVEL"
    [[ ! -z $USGS_HUC_CODES ]] && switch="$switch --huc $(echo "$USGS_HUC_CODES" | sed -e 's/^"//' -e 's/"$//')"
    [[ ! -z $USGS_PARAMETER_CODES ]] && switch="$switch --parameter_code $(echo "$USGS_PARAMETER_CODES" | sed -e 's/^"//' -e 's/"$//')"
    [[ ! -z $USGS_PERIOD ]] && switch="$switch --period $(echo "$USGS_PERIOD" | sed -e 's/^"//' -e 's/"$//')"

    echo "Switches: $switch"
    [ $USGS_SITES ] && usgs-sites ${switch}
    [ $USGS_TS ] && usgs-ts ${switch}
fi

echo "Exiting entrypoint"

exit
