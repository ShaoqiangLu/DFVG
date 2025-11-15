FROM ubuntu:16.04

ENV VER=00

COPY install_core.sh /install/install_core.sh
RUN bash /install/install_core.sh

# Python: basic dependencies
RUN sudo apt-get install -y software-properties-common
RUN sudo add-apt-repository -y ppa:deadsnakes/ppa && sudo apt-get update && sudo rm /usr/bin/python3 && sudo apt-get install -y python3.7
RUN ln -s /usr/bin/python3.7 /usr/bin/python3
RUN ln -s /usr/bin/python3.7 /usr/bin/python
RUN sudo apt-get install -y python3-dev python3-setuptools gcc \
         libtinfo-dev zlib1g-dev build-essential cmake libboost-all-dev

RUN sudo apt-get install -y python3-pip
RUN sudo pip3 install --upgrade pip

# Deep learning framework dependencies
RUN sudo pip3 install torchvision==0.4.2
RUN sudo pip3 install onnx==1.6.0
RUN sudo pip3 install tensorflow==1.15
#RUN sudo pip3 install keras=2.2.4
#RUN sudo pip3 install h5py=2.10.0

# TVM python dependencies
RUN sudo pip3 install numpy antlr4-python3-runtime decorator attrs

# LLVM
RUN mkdir /llvm && wget http://releases.llvm.org/9.0.0/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-16.04.tar.xz
RUN tar xvf clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-16.04.tar.xz
RUN rm clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-16.04.tar.xz && mv clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-16.04/ /llvm/ 

# Other tools
RUN sudo apt-get install -y vim 


RUN mkdir /workspace

# Environment variables
ENV TVM_HOME=/workspace/opu-compiler/frontend
ENV PYTHONPATH=$TVM_HOME/python:$TVM_HOME/topi/python:${PYTHONPATH}
ENV LLVM_DIR=/llvm/clang+llvm-9.0.0-x86_64-linux-gnu-ubuntu-16.04
