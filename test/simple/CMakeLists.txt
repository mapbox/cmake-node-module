cmake_minimum_required(VERSION 3.4)
project(simple LANGUAGES CXX C)

set(NODE_MODULE_CACHE_DIR "../..")
set(NODE_MODULE_MINIMUM_ABI 48)
include(node_modules/@mapbox/cmake-node-module/module.cmake)

add_node_module(simple
    INSTALL_DIR lib
    NAN_VERSION 2.10.0
)

target_sources(simple INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/simple.cpp
)
