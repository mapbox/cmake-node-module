cmake_minimum_required(VERSION 3.4)
project(simple LANGUAGES CXX C)

include(node_modules/@mapbox/cmake-node-module/module.cmake)

add_node_module(simple
    INSTALL_DIR "${CMAKE_SOURCE_DIR}"
)

target_sources(simple INTERFACE
    ${CMAKE_CURRENT_SOURCE_DIR}/simple.cpp
)
