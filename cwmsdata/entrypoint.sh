#!/bin/bash

usage(){ printf "\n$0 usage:\n\n" && grep " .*)\ #" $0; exit 0;}

cmds=""

while getopts ":stc:h" option; do
    case ${option} in 
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

# make sure to exit
exit
