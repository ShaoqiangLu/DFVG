cmake_minimum_required(VERSION 3.5)
project(data-layout-gen)

find_package(ZLIB REQUIRED)

set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -g -std=c++14")

include_directories(
  ./
  ../backend/3rdparty/cnpy
  ../backend/3rdparty/json/single_include
)

set(dlg-source
  driver.cpp
  bias_layout.cpp
  weight_layout.cpp
  utils.cpp
  ../backend/3rdparty/cnpy/cnpy.cpp
)

add_executable(data-layout-gen ${dlg-source})

target_link_libraries(data-layout-gen ${ZLIB_LIBRARIES})
