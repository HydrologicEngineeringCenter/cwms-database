#/bin/bash
sqlplus sys/${'$'}SYS_PASSWORD@${'$'}HOST_AND_PORT/${'$'}ContainerDB as SYSDBA <<EOF | grep "ORA-65012: Pluggable database REFS_HEADS_MASTER already exists"
alter session set PDB_FILE_NAME_CONVERT='/opt/oracle/oradata/ROOTDB/CWMSBASE/','/opt/oracle/oradata/ROOTDB/${'$'}{CWMS_PDB}/';
CREATE PLUGGABLE DATABASE ${'$'}CWMS_PDB from CWMSBASE;
ALTER PLUGGABLE DATABASE ${'$'}CWMS_PDB OPEN READ WRITE;
EOF
if [ ${'$'}? -eq 0 ]; then
    echo "Database wasn't correctly destroyed" 1>&2
    exit 1
fi