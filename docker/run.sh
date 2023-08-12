#!/bin/bash

CLI_ARGS=${CLI_ARGS:-"--chat --listen --api"}
WEBUI_VERSION=${WEBUI_VERSION:-"b17893a58f1b6d11d3c39594608a421bf09928a1"}  # release 1.15

WORK_DIR=/app

# goto work dir
cd ${WORK_DIR}

# clone the webui repo
[ ! -f ${WORK_DIR}/server.py ] && git clone https://github.com/oobabooga/text-generation-webui.git .

# checkout the specific commit
git checkout ${WEBUI_VERSION} || true	# ignore error

exec python3 server.py ${CLI_ARGS}
