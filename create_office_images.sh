#!/bin/bash


cd schema

# make sure the image is available
#ant docker.buildimage 
IMAGE_NAME=`ant -q -s docker.imagename`

echo "Using $IMAGE_NAME"