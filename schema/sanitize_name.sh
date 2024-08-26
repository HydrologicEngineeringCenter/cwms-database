#!/bin/bash
INPUT=$1
NAME=`echo $INPUT | sed -e s@/refs/heads/@@g -e s@/@_@g -e s@-@_@g -e s@#@_@g | md5sum | sed -rn -e 's/([a-z0-9]*)\s+.*/\1/p'`
echo "cwmsdb_$NAME"