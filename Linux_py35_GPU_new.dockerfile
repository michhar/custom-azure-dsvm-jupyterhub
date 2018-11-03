
FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04

LABEL maintainer "Micheleen Harris (contact michhar <at> microsoft.com)"

# Vars for framework versions

ENV TENSORFLOW_VERSION="1.12.0"
ENV CNTK_VERSION="2.6"
ENV KERAS_VERSION="2.1.6"
ENV TORCHVISION_VERSION="0.2.1"
ENV AZURE_CVS_VERSION="0.2.0"
ENV AZURE_IMAGESEARCH_VERSION="1.0.0"
ENV PYTORCH_VERSION="1.0rc1"

# Locale setting
ENV LC_ALL=C

# Install some essential packages
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    software-properties-common \
    nodejs \
    npm \
    zip \
    sudo \
    libsm6 \
    libxext6

RUN apt-get update && apt-get install -y --no-install-recommends \
         build-essential \
         cmake \
         git \
         curl \
         vim \
         ca-certificates \
         libjpeg-dev \
         libpng-dev &&\
    rm -rf /var/lib/apt/lists/*

# For Protobuf and zlib1g-dev/python-dev/bzip2 for Boost
RUN apt-get update && apt-get install -y \
    autoconf  \
    automake \
    libtool \
    make \
    g++ \
    unzip \
    zlib1g-dev \
    python3-dev \
    wget \
    bzip2 \
    libssl-dev \
    libffi-dev

# MKL (for CNTK and others)
RUN mkdir /usr/local/mklml && \
    wget https://github.com/01org/mkl-dnn/releases/download/v0.12/mklml_lnx_2018.0.1.20171227.tgz && \
    tar -xzf mklml_lnx_2018.0.1.20171227.tgz -C /usr/local/mklml && \
    wget --no-verbose -O - https://github.com/01org/mkl-dnn/archive/v0.12.tar.gz | tar -xzf - && \
    cd mkl-dnn-0.12 && \
    ln -s /usr/local external && \
    mkdir -p build && \
    cd build && \
    cmake .. && \
    make && \
    make install && \
    cd ../.. && \
    rm -rf mkl-dnn-0.12
    
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Protobuf v3.5.1 (for CNTK and others)
RUN wget https://github.com/google/protobuf/releases/download/v3.5.1/protobuf-all-3.5.1.tar.gz && \
    tar -xzf protobuf-all-3.5.1.tar.gz && \
    cd protobuf-3.5.1 && \
    ./autogen.sh && \
    ./configure CFLAGS=-fPIC CXXFLAGS=-fPIC --disable-shared --prefix=/usr/local/protobuf-3.5.1 && \
    make -j $(nproc) && \
    make install &&\
    cd /usr/local/protobuf-3.5.1/bin &&\
    chmod +x protoc &&\
    cd .. &&\
    export PATH=$PATH:`pwd`:`pwd`/bin

# Install Python
RUN apt-get update && apt-get install -y \
    python3-dev \
    python3-numpy \
    python3-pip \
    python3-py \
    python3-pytest \
    python3-setuptools \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Add admin user (other users can be made admins of jupyterhub from this user)
ARG USER_PW
RUN USER_PW=$USER_PW

# Configure environment
ENV PY_LIB_DIR=/usr/lib/python3.5 \
    SHELL=/bin/bash \
    NB_USER=tpol \
    NB_UID=1000 \
    NB_GID=100 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH=$PY_LIB_DIR/bin:$PATH \
    HOME=/home/$NB_USER

# ADD fix-permissions /usr/bin/fix-permissions
# Create users with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN useradd -u $NB_UID -m -s /bin/bash -N $NB_USER && \
    mkdir -p $PY_LIB_DIR && \
    chown $NB_USER:$NB_GID $PY_LIB_DIR && \
    chmod g+w /etc/passwd /etc/group && \
    chmod -R 777 $HOME && \
    chmod -R 777 $PY_LIB_DIR
RUN printf "${USER_PW}\n${USER_PW}" | passwd tpol

ENV NB_USER=user1
RUN useradd -m -s /bin/bash -N $NB_USER && \
    mkdir -p $PY_LIB_DIR && \
    chown $NB_USER:$NB_GID $PY_LIB_DIR && \
    chmod g+w /etc/passwd /etc/group && \
    chmod -R 777 $HOME && \
    chmod -R 777 $PY_LIB_DIR
RUN printf "${USER_PW}\n${USER_PW}" | passwd $NB_USER

ENV NB_USER=user2
RUN useradd -m -s /bin/bash -N $NB_USER && \
    mkdir -p $PY_LIB_DIR && \
    chown $NB_USER:$NB_GID $PY_LIB_DIR && \
    chmod g+w /etc/passwd /etc/group && \
    chmod -R 777 $HOME && \
    chmod -R 777 $PY_LIB_DIR
RUN printf "${USER_PW}\n${USER_PW}" | passwd $NB_USER

ENV NB_USER=user3
RUN useradd -m -s /bin/bash -N $NB_USER && \
    mkdir -p $PY_LIB_DIR && \
    chown $NB_USER:$NB_GID $PY_LIB_DIR && \
    chmod g+w /etc/passwd /etc/group && \
    chmod -R 777 $HOME && \
    chmod -R 777 $PY_LIB_DIR
RUN printf "${USER_PW}\n${USER_PW}" | passwd $NB_USER

ENV NB_USER=user4
RUN useradd -m -s /bin/bash -N $NB_USER && \
    mkdir -p $PY_LIB_DIR && \
    chown $NB_USER:$NB_GID $PY_LIB_DIR && \
    chmod g+w /etc/passwd /etc/group && \
    chmod -R 777 $HOME && \
    chmod -R 777 $PY_LIB_DIR
RUN printf "${USER_PW}\n${USER_PW}" | passwd $NB_USER

ENV NB_USER=tpol
USER $NB_USER

# Setup work directory for backward-compatibility
RUN mkdir /home/$NB_USER/work && \
    chmod -R 777 /home/$NB_USER

USER root

# Install PyTorch from source
RUN git clone --recursive --depth 1 https://github.com/pytorch/pytorch.git && cd pytorch && git checkout -b 8619230

WORKDIR pytorch

ENV USE_OPENCV=1
ENV BUILD_TORCH=ON

ENV CMAKE_PREFIX_PATH="/usr/bin/"
ENV LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/lib:$LD_LIBRARY_PATH
ENV CUDA_BIN_PATH=/usr/local/cuda/bin
ENV CUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda/
ENV CUDNN_LIB_DIR=/usr/local/cuda/lib64
ENV CUDA_HOST_COMPILER=cc
ENV USE_CUDA=1
ENV USE_NNPACK=1
ENV CC=cc
ENV CXX=c++
ENV TORCH_CUDA_ARCH_LIST="3.5 5.2 6.0 6.1+PTX" 
ENV TORCH_NVCC_FLAGS="-Xfatbin -compress-all"

# This is the PyTorch requirements.txt
RUN LC_ALL=C python3 -m pip install -r requirements.txt

# Build PyTorch command
RUN python3 setup.py bdist_wheel

RUN LC_ALL=C python3 -m pip install dist/*.whl

# TensorFlow-GPU, TensorFlow Object Detection API and Keras
ENV PATH="/usr/local/protobuf-3.5.1/bin:${PATH}"
RUN bash -c pip3 install --upgrade Cython
RUN bash -c pip3 install --upgrade tensorflow-gpu==${TENSORFLOW_VERSION}
RUN bash -c pip3 install -e git+https://github.com/pdollar/coco.git#egg=pycocotools&subdirectory=PythonAPI
ARG DEBIAN_FRONTEND=noninteractive
RUN export DEBIAN_FRONTEND="noninteractive" &&\
    apt-get update && apt-get install --yes protobuf-compiler python-pil python-lxml python-tk
RUN bash -c pip3 install --upgrade jupyter matplotlib
RUN mkdir -p /tensorflow
WORKDIR /tensorflow/
RUN git clone https://github.com/tensorflow/models.git
COPY . .
WORKDIR /tensorflow/models/research
RUN cd /tensorflow/models/research &&\
    protoc object_detection/protos/*.proto --python_out=.
RUN export PYTHONPATH=$PYTHONPATH:`pwd`:`pwd`/slim
RUN bash -c pip3 install keras==${KERAS_VERSION}

# CNTK and Custom Vision Service Python libraries
RUN bash -c pip3 install cntk==${CNTK_VERSION}
RUN bash -c pip3 install azure-cognitiveservices-vision-customvision==${AZURE_CVS_VERSION}
RUN bash -c pip3 install azure-cognitiveservices-search-imagesearch==${AZURE_IMAGESEARCH_VERSION}

WORKDIR /
COPY requirements.txt .

# Requirements into the Python 3.5
RUN LC_ALL=C python3 -m pip install -r requirements.txt

# CoreML converter and validation tools for models
RUN git clone https://github.com/apple/coremltools.git && cd coremltools && LC_ALL=C pip3 install -v .

RUN chmod -R 777 $PY_LIB_DIR

### Jupyterhub setup ###

# Additional installs
RUN apt-get install nodejs npm
RUN ln -s /usr/bin/nodejs /usr/bin/node
RUN npm install -g configurable-http-proxy

# Create directories
RUN mkdir -p /etc/init.d/jupyterhub
RUN chmod +x /etc/init.d/jupyterhub
RUN chmod +x /etc/init.d/jupyterhub
RUN mkdir -p /etc/jupyterhub
RUN chmod +x /etc/jupyterhub

# Deal with directory permissions for user and add to userlist
RUN mkdir -p /hub/user/tpol/
RUN chown tpol /hub/user/tpol/
RUN mkdir -p /user/tpol/
RUN chown tpol /user/tpol/
RUN echo "tpol admin" >> /etc/jupyterhub/userlist
RUN chown tpol /etc/jupyterhub
RUN chown tpol /etc/jupyterhub

# Create a default config to /etc/jupyterhub/jupyterhub_config.py
RUN LC_ALL=C jupyterhub --generate-config -f /etc/jupyterhub/jupyterhub_config.py
RUN bash -c echo "c.PAMAuthenticator.open_sessions=False" >> /etc/jupyterhub/jupyterhub_config.py
RUN bash -c echo "c.Authenticator.whitelist={\'tpol\'}" >> /etc/jupyterhub/jupyterhub_config.py
RUN bash -c echo "c.LocalAuthenticator.create_system_users=True" >> /etc/jupyterhub/jupyterhub_config.py
RUN bash -c echo "c.Authenticator.admin_users={\'tpol\'}" >> /etc/jupyterhub/jupyterhub_config.py

# Copy TLS certificate and key
ENV SSL_CERT /etc/jupyterhub/secrets/mycert.pem
ENV SSL_KEY /etc/jupyterhub/secrets/mykey.key
COPY ./secrets/*.crt $SSL_CERT
COPY ./secrets/*.key $SSL_KEY
RUN chmod 700 /etc/jupyterhub/secrets && \
    chmod 600 /etc/jupyterhub/secrets/*

# Creating a file directory for files to spawn to all users - testing this
# c.Spawner.notebook_dir = '~/files' # could be a good place to place tf models
ENV USER_FILES_DIR /etc/jupyterhub/files
RUN mkdir $USER_FILES_DIR &&\
    cd $USER_FILES_DIR

RUN cd /home

CMD bash -c "jupyterhub -f /etc/jupyterhub/jupyterhub_config.py --JupyterHub.Authenticator.whitelist=\{\'user1\',\'user2\',\'user3\',\'user4\'\} --JupyterHub.hub_ip='' --JupyterHub.ip='' JupyterHub.cookie_secret=bytes.fromhex\('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'\) Spawner.cmd=\['/user/miniconda3/bin/jupyterhub-singleuser'\] --ip '' --port 8788 --ssl-key /etc/jupyterhub/secrets/mykey.key --ssl-cert /etc/jupyterhub/secrets/mycert.pem"
