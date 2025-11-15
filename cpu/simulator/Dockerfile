FROM ubuntu:16.04

ENV VER=00

RUN apt-get update && \
      apt-get -y install sudo

RUN sudo apt-get install -y software-properties-common
RUN sudo add-apt-repository -y ppa:deadsnakes/ppa && sudo apt-get update && sudo rm /usr/bin/python3 && sudo apt-get install -y python3.7
RUN ln -s /usr/bin/python3.7 /usr/bin/python3
RUN sudo apt-get install -y python3-dev python3-setuptools gcc \
         libtinfo-dev zlib1g-dev build-essential cmake vim\
         wget python3-pip  libgoogle-glog-dev
RUN pip3 install --upgrade pip
RUN pip3 install -U pytest 
RUN pip3 install numpy
# Gtest
RUN apt-get install libgtest-dev
RUN cd /usr/src/gtest && cmake CMakeLists.txt && make && cp *.a /usr/lib
RUN mkdir ws
