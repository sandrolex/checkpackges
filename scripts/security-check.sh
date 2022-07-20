#!/bin/sh
if [ "$NONBLOCKING" = true ]; then
    echo "# NON BLOCKING MODE"
fi

image=$1
status=0

echo "### SECURITY CHECKS FOR IMAGE $1"

if [ "$PROFILE" = "base-image" ]; then
    echo "# USING BASE-IMAGES PROFILE"
    cd /opt/runtime/base-images
else
    echo "# USING PRODUCTION-IMAGES PROFILE"
    cd /opt/runtime/prod-images
fi


echo "# CHECKPACKAGES TEST"
checkpackages $image /opt/runtime/base-images/blacklist.txt
if [ "$?" = 0 ]; then
    echo "# CHECKPACKAGES PASSED"
else
    echo "# CHECKPACKAGES FAILED"
    status=1
fi

echo "# DOCKLE TEST"
dockle --exit-code 1 $image

if [ "$?" = 0 ]; then
    echo "# DOCKLE PASSED"
else
    echo "# DOCKLE FAILED"
    status=1
fi



echo "# SNYK TEST"
snyk container test --severity-threshold=high --policy-path=/opt/runtime/base-images $image
if [ "$?" = 0 ]; then
    echo "# SNYK PASSED"
else
    echo "# SNYK FAILED"
    status=1
fi


if [ "$MONITOR" = true ]; then
    echo "# SNYK MONITOR"
    snyk container monitor --severity-threshold=high --policy-path=/opt/runtime/base-images $image
fi


if [ "$NONBLOCKING" = true ]; then
    exit 0
else
    exit $status
fi


