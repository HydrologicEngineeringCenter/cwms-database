#/bin/bash
if [ -d output ]; then
    rm -rf output
fi
mkdir output
export PW=`tr -cd '[:alnum:]' < /dev/urandom | fold -w25 | head -n1`

export CWMS_PDB=`echo %teamcity.build.branch% | sed -e "s@/refs/heads/@@g" | sed "s@/@_@g" | sed "s@\.@_@g" | sed "s@-@_@g" | sed "s@#@_@g"`
if [[ $CWMS_PDB =~ ^[0-9]+$ ]]; then
    echo "prefixing pull request number with text."
    export CWMS_PDB="PULLREQUEST_${CWMS_PDB}"
elif [[ $CWMS_PDB =~ ^[0-9] ]]; then
    # while not a pull request, it still needs an alpha prefix.
    echo "prefixing with letter"
    export CWMS_PDB="z_${CWMS_PDB}"
fi
cat <<EOF
##teamcity[setParameter name='env.CWMS_PDB' value='$CWMS_PDB']

EOF

echo "=$CWMS_PDB="

sed -e "s/SYS_PASSWORD/$SYS_PASSWORD/g" \
    -e "s/PASSWORD/$PW/g" \
    -e "s/HOST_AND_PORT/$HOST_AND_PORT/g" \
    -e "s/SERVICE_NAME/$CWMS_PDB/g" \
    -e "s/OFFICE_ID/$OFFICE_ID/g" \
    -e "s/OFFICE_CODE/$OFFICE_CODE/g" \
    -e "s/TEST_ACCOUNT_FLAG/-testaccount/g" teamcity_overrides.xml > output/overrides.xml
cat <<EOF
##teamcity[setParameter name='env.CWMS_PASSWORD' value='$PW']

EOF

echo "$CWMS_PDB" > output/database.info
echo "$PW" >> output/database.info
exit 0