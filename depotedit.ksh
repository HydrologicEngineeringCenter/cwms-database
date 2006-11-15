#!sh
# Opens for edit files in the Perforce depot that have been modified but not opened for edit.
#

p4 diff -se //wcdba/dev/src/java/cwmsdb/... | p4 -x - edit
p4 diff -se //wcdba/dev/src/java/dataexchange/... | p4 -x - edit

