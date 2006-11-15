#!sh
# Adds *.java files to the perforce depot.
#

find src/java/cwmsdb -name "*.java" -print | p4 -x - add | grep "opened for add"
find src/java/dataexchange -name "*.java" -print | p4 -x - add | grep "opened for add"

