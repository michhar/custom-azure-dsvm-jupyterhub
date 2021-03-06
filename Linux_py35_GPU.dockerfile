
FROM nvidia/cuda:9.0-cudnn7-devel-ubuntu16.04

LABEL maintainer "Micheleen Harris (contact michhar <at> microsoft.com)"

# Vars for framework versions

ENV TENSORFLOW_VERSION="1.12.0"
ENV KERAS_VERSION="2.2.4"
ENV PYTORCH_VERSION="1.0"
ENV TORCHVISION_VERSION="0.2.2"

# # PyTorch Release 0.3.1 if needed
# ENV PYTORCH_COMMIT_ID="2b47480"

# Set the locale
# Ensure that we always use UTF-8 and with US English locale

RUN apt-get -qq update && \
    apt-get -q -y upgrade && \
    apt-get install -y sudo curl wget locales && \
    rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8

#COPY ./default_locale /etc/default/locale
RUN chmod 0755 /etc/default/locale

ENV LC_ALL en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en

# Install some essential packages
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    software-properties-common \
    zip \
    sudo \
    libsm6 \
    libxext6 &&\
    rm -rf /var/lib/apt/lists/*

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
    wget \
    bzip2 \
    libssl-dev \
    libffi-dev &&\
    rm -rf /var/lib/apt/lists/*

# For Azure CLI

RUN apt-get update && apt-get install apt-transport-https lsb-release software-properties-common dirmngr -y

RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ $(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/azure-cli.list

RUN apt-key --keyring /etc/apt/trusted.gpg.d/Microsoft.gpg adv \
     --keyserver packages.microsoft.com \
     --recv-keys BC528686B50D79E339D3721CEB3E94ADBE1229CF && \
     apt-get update && \
     apt-get install azure-cli


# Nodejs v11 because current apt-get has v4
RUN curl -sL https://deb.nodesource.com/setup_11.x | sudo -E bash -
RUN sudo apt-get install -y nodejs
RUN npm install npm --global

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

# Install Python 3.6
RUN apt-get install software-properties-common &&\
    add-apt-repository -y ppa:deadsnakes/ppa &&\
    apt-get update &&\
    apt-get install -y python3.6 &&\
    curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py && \
    python3.6 get-pip.py


# # Old Python install
# RUN apt-get update && apt-get install -y \
#     python3.6-dev \
#     python3.6-numpy \
#     python3.6-pip \
#     python3.6-py \
#     python3.6-pytest \
#     python3.6-setuptools \
#     && \
#     apt-get clean && \
#     rm -rf /var/lib/apt/lists/*

# Add admin user (other users can be made admins of jupyterhub from this user)
ARG USER_PW
RUN USER_PW=$USER_PW

# Configure environment
ENV PY_LIB_DIR=/usr/lib/python3.6 \
    SHELL=/bin/bash \
    NB_USER=wonderwoman \
    NB_UID=1000 \
    NB_GID=100 \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH=$PY_LIB_DIR/bin:$PATH \
    HOME=/home

# ADD fix-permissions /usr/bin/fix-permissions
# Create users with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN useradd -u $NB_UID -m -s /bin/bash -N $NB_USER && \
    mkdir -p $PY_LIB_DIR && \
    chown $NB_USER:$NB_GID $PY_LIB_DIR && \
    chmod g+w /etc/passwd /etc/group && \
    chmod -R 777 $HOME/$NB_USER
RUN printf "${USER_PW}\n${USER_PW}" | passwd wonderwoman

ENV NB_USER=user1
RUN useradd -m -s /bin/bash -N $NB_USER && \
    mkdir -p $PY_LIB_DIR && \
    chown $NB_USER:$NB_GID $PY_LIB_DIR && \
    chmod g+w /etc/passwd /etc/group && \
    chmod -R 777 $HOME/$NB_USER
RUN printf "${USER_PW}\n${USER_PW}" | passwd $NB_USER

ENV NB_USER=user2
RUN useradd -m -s /bin/bash -N $NB_USER && \
    mkdir -p $PY_LIB_DIR && \
    chown $NB_USER:$NB_GID $PY_LIB_DIR && \
    chmod g+w /etc/passwd /etc/group && \
    chmod -R 777 $HOME/$NB_USER
RUN printf "${USER_PW}\n${USER_PW}" | passwd $NB_USER

ENV NB_USER=user3
RUN useradd -m -s /bin/bash -N $NB_USER && \
    mkdir -p $PY_LIB_DIR && \
    chown $NB_USER:$NB_GID $PY_LIB_DIR && \
    chmod g+w /etc/passwd /etc/group && \
    chmod -R 777 $HOME/$NB_USER
RUN printf "${USER_PW}\n${USER_PW}" | passwd $NB_USER

ENV NB_USER=user4
RUN useradd -m -s /bin/bash -N $NB_USER && \
    mkdir -p $PY_LIB_DIR && \
    chown $NB_USER:$NB_GID $PY_LIB_DIR && \
    chmod g+w /etc/passwd /etc/group && \
    chmod -R 777 $HOME/$NB_USER
RUN printf "${USER_PW}\n${USER_PW}" | passwd $NB_USER

ENV NB_USER=wonderwoman
USER $NB_USER

# Setup work directory for backward-compatibility
RUN mkdir /home/$NB_USER/work && \
    chmod -R 777 /home/$NB_USER

USER root

RUN chmod -R 777 $PY_LIB_DIR

WORKDIR /
COPY requirements.txt .

# Requirements into the Python 3.6
RUN pip3.6 install -r requirements.txt

# Install PyTorch with pip (installs with GPU support automagically)

RUN pip3.6 install torch==${PYTORCH_VERSION} torchvision==${TORCHVISION_VERSION}

# # Install PyTorch from source (keeps just in case) - developers have all the fun!

# # Build PyTorch command
# RUN git clone --recursive https://github.com/pytorch/pytorch.git &&\
#     pip3.6 uninstall torch &&\
#     pip3.6 install pyyaml==3.13 &&\
#     pip3.6 install -r requirements.txt &&\
#     USE_OPENCV=1 \
#     BUILD_TORCH=ON \
#     CMAKE_PREFIX_PATH="/usr/bin/" \
#     LD_LIBRARY_PATH=/usr/local/cuda/lib64:/usr/local/lib:/usr/lib/x86_64-linux-gnu/:$LD_LIBRARY_PATH \
#     CUDA_BIN_PATH=/usr/local/cuda/bin \
#     CUDA_TOOLKIT_ROOT_DIR=/usr/local/cuda/ \
#     CUDNN_LIB_DIR=/usr/local/cuda/lib64 \
#     CUDA_HOST_COMPILER=cc \
#     USE_CUDA=1 \
#     USE_NNPACK=1 \
#     CC=cc \
#     CXX=c++ \
#     TORCH_CUDA_ARCH_LIST="3.5 5.2 6.0 6.1+PTX" \
#     TORCH_NVCC_FLAGS="-Xfatbin -compress-all" \
#     python3.6 setup.py bdist_wheel

# WORKDIR pytorch

# # Install PyTorch wheel (includes PyTorch C++ API)
# RUN pip3.6 install dist/*.whl

# TensorFlow-GPU, TensorFlow Object Detection API, Keras and TensorFlow Probability
ENV PATH="/usr/local/protobuf-3.5.1/bin:${PATH}"
RUN pip3.6 install --upgrade Cython
RUN pip3.6 install --upgrade tensorflow-gpu==${TENSORFLOW_VERSION}
RUN pip3.6 install --upgrade tensorflow-probability
RUN pip3.6 install -e git+https://github.com/pdollar/coco.git#egg=pycocotools&subdirectory=PythonAPI
ARG DEBIAN_FRONTEND=noninteractive
RUN export DEBIAN_FRONTEND="noninteractive" &&\
    apt-get update && apt-get install --yes protobuf-compiler python-pil python-lxml python-tk
RUN pip3.6 install --upgrade jupyter matplotlib
RUN mkdir -p /tensorflow
WORKDIR /tensorflow/
RUN git clone https://github.com/tensorflow/models.git
COPY . .
WORKDIR /tensorflow/models/research
RUN cd /tensorflow/models/research &&\
    protoc object_detection/protos/*.proto --python_out=.
RUN export PYTHONPATH=$PYTHONPATH:`pwd`:`pwd`/slim
RUN pip3.6 install keras==${KERAS_VERSION}

# CoreML converter and validation tools for models
RUN git clone https://github.com/apple/coremltools.git && cd coremltools && pip3.6 install -v .


# Fix, workaround for broken kernel tornado error (https://stackoverflow.com/questions/54963043/jupyter-notebook-no-connection-to-server-because-websocket-connection-fails)
RUN pip3.6 uninstall --yes tornado
RUN pip3.6 install tornado==5.1.1

# Add Kernel to use in future juypyter notebooks
#RUN pip3.6 install --upgrade ipykernel
#RUN python3.6 -m ipykernel install --name py35_custom --display-name "Python 3.6 Custom"

# Configure jupyter nbextensions (needed as in https://github.com/jupyter-widgets/ipywidgets/issues/1702#issuecomment-332392774)
RUN pip3.6 install jupyter jupyterhub notebook pyzmq
RUN pip3.6 install jupyter_contrib_nbextensions ipywidgets
RUN jupyter contrib nbextension install --sys-prefix
RUN jupyter nbextension enable --py --sys-prefix widgetsnbextension

RUN chmod -R 777 $PY_LIB_DIR

### Jupyterhub setup ###

# Additional configuring
RUN npm install -g configurable-http-proxy

# Create directories
RUN mkdir -p /etc/init.d/jupyterhub
RUN chmod +x /etc/init.d/jupyterhub
RUN chmod +x /etc/init.d/jupyterhub
RUN mkdir -p /etc/jupyterhub
RUN chmod +x /etc/jupyterhub

# Deal with directory permissions for user and add to userlist
RUN mkdir -p /hub/user/wonderwoman/
RUN chown wonderwoman /hub/user/wonderwoman/
RUN mkdir -p /user/wonderwoman/
RUN chown wonderwoman /user/wonderwoman/
RUN echo "wonderwoman admin" >> /etc/jupyterhub/userlist
RUN chown wonderwoman /etc/jupyterhub
RUN chown wonderwoman /etc/jupyterhub

# Create a default config to /etc/jupyterhub/jupyterhub_config.py
RUN jupyterhub --generate-config -f /etc/jupyterhub/jupyterhub_config.py
RUN echo "c.PAMAuthenticator.open_sessions=False" >> /etc/jupyterhub/jupyterhub_config.py
RUN echo "c.Authenticator.whitelist={'wonderwoman'}" >> /etc/jupyterhub/jupyterhub_config.py
RUN echo "c.LocalAuthenticator.create_system_users=True" >> /etc/jupyterhub/jupyterhub_config.py
RUN echo "c.Authenticator.admin_users={'wonderwoman'}" >> /etc/jupyterhub/jupyterhub_config.py

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

CMD bash -c "jupyterhub -f /etc/jupyterhub/jupyterhub_config.py --JupyterHub.Authenticator.whitelist=\{\'wonderwoman\',\'user1\',\'user2\',\'user3\',\'user4\'\} --JupyterHub.hub_ip='' --JupyterHub.ip='' JupyterHub.cookie_secret=bytes.fromhex\('xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'\) Spawner.cmd=\['jupyterhub-singleuser'\] --ip '' --port 8788 --ssl-key /etc/jupyterhub/secrets/mykey.key --ssl-cert /etc/jupyterhub/secrets/mycert.pem"
