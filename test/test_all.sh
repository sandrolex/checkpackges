#!/bin/bash


DOCKER_BUILDKIT=1 docker build -t good -f Dockerfile.good . 
DOCKER_BUILDKIT=1 docker build -t bad -f Dockerfile.tcpdump . 

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v ${PWD}/shortlist.txt:/tmp/policy.txt checkpackages good /tmp/policy.txt
if [ $? -ne 0 ]
then
    echo 'failed, good image expected to return 0'
else
    echo 'OK!'
fi

docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v ${PWD}/shortlist.txt:/tmp/policy.txt checkpackages bad /tmp/policy.txt
if [ $? -ne 1 ]
then
    echo 'failed, bad image expected to return 1'
else
    echo 'OK!'
fi 

# empty policy file
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock -v ${PWD}/empty:/tmp/policy.txt checkpackages bad /tmp/policy.txt
if [ $? -ne 2 ]
then
    echo 'failed, empty policy file expected to return 2'
else
    echo 'OK!'
fi 
