#!/bin/bash

#docker build -f ../docker/bundle.dockerfile -t secbundle ../ 

buildah bud -f ../docker/bundle.dockerfile -t secbundle ../
