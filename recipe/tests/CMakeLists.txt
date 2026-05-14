cmake_minimum_required(VERSION 3.16.3)

project(momentum_consumer LANGUAGES CXX)

include(CTest)

find_package(momentum CONFIG REQUIRED)
add_executable(momentum_consumer main.cpp)
target_link_libraries(momentum_consumer PRIVATE momentum::math)
add_test(NAME momentum_consumer COMMAND momentum_consumer)
