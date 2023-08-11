#!/bin/bash

CLI_ARGS=${CLI_ARGS:-"--help"}
WORK_DIR=/app

if [ ! -f ${WORK_DIR}/server.py ]; then
    if [ -f /dist/app.tgz ]; then
	tar -C /app -xzf /dist/app.tgz
    else
	echo "WARN: app dist does not exist!"
	exit -1
    fi
fi

cd ${WORK_DIR}; exec python3 server.py ${CLI_ARGS}
