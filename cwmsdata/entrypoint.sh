#!/bin/bash

if [ $# -gt 0 ]
then
    usgs-sites "$@"

    usgs-ts "$@"
fi
