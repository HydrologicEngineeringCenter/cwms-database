#/bin/bash
if [ -d output ]; then
    rm -rf output
fi
mkdir output

cat <<EOF
##teamcity[setParameter name='env.CWMS_PASSWORD' value='$PW']
##teamcity[setParameter name='env.PATH' value='/usr/local/buildtools/instantclient_19_9:$PATH']
##teamcity[setParameter name='env.LD_LIBRARY_PATH' value='/usr/local/buildtools/instantclient_19_9']
##teamcity[setParameter name='env.ORACLE_HOME' value='/usr/local/buildtools/instantclient_19_9']

EOF


exit 0
