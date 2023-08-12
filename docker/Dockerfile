ARG UBUNTU_VERSION=22.04
ARG CUDA_VERSION=11.7.1

ARG WEBUI_COMMIT=b17893a58f1b6d11d3c39594608a421bf09928a1
ARG BNB_COMMIT=18e827d666fa2b70a12d539ccedc17aa51b2c97c

ARG BASE_CUDA_DEV_CONTAINER=nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION}
ARG BASE_CUDA_RUN_CONTAINER=nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu${UBUNTU_VERSION}


FROM ${BASE_CUDA_DEV_CONTAINER} as build

# pre-req
RUN apt-get update \
&&  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
        python3 python3-pip python3-venv python3-dev git build-essential

ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

ENV CUDA_DOCKER_ARCH=all

# Install torch
RUN python3 -m pip install --upgrade pip wheel setuptools \
&&  python3 -m pip install torch torchvision torchaudio \
	--index-url https://download.pytorch.org/whl/cu117

# Install GPTQ for llama

ARG TORCH_CUDA_ARCH_LIST="${TORCH_CUDA_ARCH_LIST:-6.1;7.0;7.5;8.0;8.6+PTX}"

RUN git clone https://github.com/oobabooga/GPTQ-for-LLaMa /build \
&&  cd /build \
&&  python3 -m pip install -r requirements.txt \
&&  python3 setup_cuda.py install \
&&  rm -rf /build

# Install text-generation-webui / release 1.15
RUN git clone https://github.com/oobabooga/text-generation-webui.git /app \
&&  cd /app && git checkout ${WEBUI_COMMIT} \
&&  python3 -m pip install -r requirements.txt \
&&  for f in ./extensions/*/requirements.txt ; do python3 -m pip install -r $f ; done

# Installing latest llama.cpp python bindings
RUN python3 -m pip uninstall -y llama-cpp-python \
&&  CMAKE_ARGS="-DLLAMA_CUBLAS=on" FORCE_CMAKE=1 python3 -m pip install llama-cpp-python==0.1.77

# Making latest bitsandbytes with cuda support / v0.41.0
RUN python3 -m pip uninstall -y bitsandbytes \
&&  git clone https://github.com/TimDettmers/bitsandbytes.git /build \
&&  cd /build && git checkout ${BNB_COMMIT} \
&&  CUDA_VERSION=117 make cuda11x \
&&  python3 setup.py install \
&&  rm -rf /build

# Prepare for app dist
RUN mkdir /dist &&  tar -C /app -czf /dist/app.tgz .


FROM ${BASE_CUDA_RUN_CONTAINER}

LABEL maintainer="Kenneth Zhao <ken@epenguin.com>"

# Default user and working dir
ARG UID=1000
ARG GID=1000
ARG USER=worker
ARG HOME=/app

# the port the webui binds to inside the container
ENV CONTAINER_PORT=7860

# the port the api binds to inside the container
ENV CONTAINER_API_PORT=5000

# the port the api stream endpoint binds to inside the container
ENV CONTAINER_API_STREAM_PORT=5005


# pre-req
RUN apt-get update \
&&  DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y python3 git \
&&  apt-get clean \
&&  rm -rf /var/lib/apt/lists*

# copy virtual env from the build
ENV VIRTUAL_ENV=/opt/venv
COPY --from=build ${VIRTUAL_ENV} ${VIRTUAL_ENV} 
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

COPY ./run.sh /run.sh

RUN groupadd -g $GID $USER \
&&  useradd -u $UID -g worker --shell /bin/bash -d $HOME $USER

USER $USER
WORKDIR $HOME

EXPOSE ${CONTAINER_PORT}
EXPOSE ${CONTAINER_API_PORT}
EXPOSE ${CONTAINER_API_STREAM_PORT}

ENV CLI_ARGS="--help"
ENV WEBUI_VERSION=${WEBUI_COMMIT}

CMD /run.sh ${CLI_ARGS}

