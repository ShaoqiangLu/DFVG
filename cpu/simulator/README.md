# opu-sim

Simulator for [OPU: An FPGA-based Overlay Processor for Convolutional Neural Networks](http://eda.ee.ucla.edu/pub/J93.pdf). 
Descriptions about data structures and fucntions can be found in the [doc](https://github.com/OPU-Lab/opu-sim/blob/master/README_Summary.md).

## Dependency

If you are not using docker, please install Google Test (Gtest) following the [link](https://www.eriksmistad.no/getting-started-with-google-test-on-ubuntu/).

## CMake Build
```
mkdir build
cd build
cmake ..
make
```

## Test

Check unit test for inner-product units at [test.cc](https://github.com/OPU-Lab/opu-sim/blob/master/src/tests.cc).
```
./build/runTests
```

## Docker Build
install docker
```
sh docker_install.sh
```
build a container with dependencies for the simulator
```
sudo docker build -f Dockerfile --tag opu-sim:1.0 .
```
launch
```
sudo docker run --rm --pid=host\
                     --mount src="$(pwd)",target=/ws,type=bind\
                     -w /ws\
                     -e "CI_BUILD_HOME=/ws"\
                     -e "CI_BUILD_USER=$(id -u -n)"\
                     -e "CI_BUILD_UID=$(id -u)"\
                     -e "CI_BUILD_GROUP=$(id -g -n)"\
                     -e "CI_BUILD_GID=$(id -g)"\
                     -h opu-sim\
                     --name opu-fsim\
                     -it --net=host\
                     opu-sim:1.0\
                     /bin/bash
```
then you can run cmake build in the container.

detach (can attach later) : ``ctrl+p`` followed by ``ctrl+q``

exit (cannot attach later): ``exit``

Inside container, generate straight line code for simulation, where each line corresponds to a load/compute/store event in the simulator.
```
./compiler/backend -i example/tinyyolo/OPU_IR.json --codegen-non-isa
```

