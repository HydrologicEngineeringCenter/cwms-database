#!/bin/bash
BRANCH=sequence_test
AGENT=sequence_agent



cd schema
ant docker.prepdb -Dteamcity.branch=${BRANCH}_${AGENT} -Denv.USER=$AGENT -Denv.BUILD_NUMBER=1 $*
if [ $? -ne 0 ]; then echo "Failed to prep db"; exit 1; fi

ant docker.install -Dteamcity.branch=${BRANCH}_${AGENT} -Denv.USER=$AGENT  -Denv.BUILD_NUMBER=1 $*
if [ $? -ne 0 ]; then echo "Failed to install schema"; exit 2; fi

ant test -Dbuilduser.overrides=build/overrides.external.xml $*
if [ $? -ne 0 ]; then echo "Tests failed"; exit 3; fi

mvn -Dbuilduser.overrides=build/overrides.external.xml package $*
if [ $? -ne 0 ]; then echo "Codegen Failed"; exit 4; fi

ant bundle -Dbuilduser.overrides=build/overrides.external.xml $*
if [ $? -ne 0 ]; then echo "Failed to build bundle"; exit 5; fi

ant docker.stopdb -Dteamcity.branch=${BRANCH}_${AGENT} -Denv.USER=$AGENT  -Denv.BUILD_NUMBER=1 $*
if [ $? -ne 0 ]; then echo "Failed to stop db?"; exit 6; fi

ant docker.push -Dteamcity.branch=${BRANCH}_${AGENT} -Denv.USER=$AGENT  -Denv.BUILD_NUMBER=1 -Ddryrun=true -Ddocker.registry=testregistry $*
if [ $? -ne 0 ]; then echo "Image tagging failed"; exit 7; fi

