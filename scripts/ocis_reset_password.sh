#!/bin/bash
# ownCloud Infinite Scale (oCIS) admin password reset script

# change DOCKER_HOME to the value of docker_home in your overrides file (./ane.sh -s to view)
DOCKER_HOME=/data/docker
OCIS_CONFIG=$DOCKER_HOME/ocis/config
OCIS_DATA=$DOCKER_HOME/ocis/data

docker run --rm -it --mount type=bind,source=$OCIS_CONFIG,target=/etc/ocis --mount type=bind,source=$OCIS_DATA,target=/var/lib/ocis     owncloud/ocis init --insecure yes --force-overwrite
