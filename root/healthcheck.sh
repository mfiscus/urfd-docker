#!/bin/bash

TARGET="localhost"
CURL_OPTS="--connect-timeout 15 --max-time 100 --silent --show-error --fail"

curl ${CURL_OPTS} "http://${TARGET}:${PORT}/index.php" >/dev/null
