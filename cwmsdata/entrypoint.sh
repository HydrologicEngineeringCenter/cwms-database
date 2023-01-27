#!/bin/bash

usage(){ printf "\n$0 usage:\n\n" && grep " .*)\ #" $0; exit 0;}

db_statuscheck() {
    echo "$(date) :Checking DB connectivity...";
    echo "$(date) :Trying to connect "${DB_HOST_PORT}${DB_NAME}" ..."
    echo "exit" | sqlplus -S ${CWMS_USER}/${CWMS_PASSWORD}@${DB_HOST_PORT}${DB_NAME} | grep -q "Connected to:" > /dev/null
    if [ $? -eq 0 ]
    then
        DB_STATUS="UP"
        export DB_STATUS
        echo "$(date) :Status: ${DB_STATUS}. Able to Connect..."
    else
        DB_STATUS="DOWN"
        export DB_STATUS
        echo "$(date) :Status: DOWN; Not able to Connect."
        echo "$(date) :Not able to connect to database with Username:  "${CWMS_USER}" DB HostName: "${DB_HOST_PORT}${DB_NAME}"."
        echo "$(date) :Exiting Script"
        sleep 15
        exit 1
    fi
 }

# Check the database first
echo "$(date) :Starting Sql auto run script."
db_statuscheck
echo "$(date) :Sql auto run script execution completed."


cmds=""
ALIVE=false

while getopts ":ac:sth" option; do
    case ${option} in 
        a) # Keep container alive
            ALIVE=true
            ;;
        c) # Switches for commands
            switch="$OPTARG";
            ;;
        s) # Run usgs-sites
            cmds="$cmds usgs-sites"
            ;;
        t) # Run usgs-ts
            ts="$cmds usgs-ts"
            ;;
        h) # Print usage message
            usage
            exit 1
            ;;
        :)
            echo "$0: Must supply an argument to -$OPTARG."
            exit 1
            ;;
        ?)
            echo "Invalid option: -$OPTARG."
            exit 2
            ;;    esac
done

for cmd in $sites $ts
do
    eval ${cmd} ${switch}
done

while $ALIVE
do
    sleep 10000
done
