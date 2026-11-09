cmake_minimum_required(VERSION 3.22)
project(HYPERION_X_ENGINE CXX)

set(CMAKE_CXX_STANDARD 20)

option(PLATFORM "Target platform" "android")
message(STATUS "[Target] Compiling for platform: ${PLATFORM}")

add_executable(hyperion_x src/main.cpp)
target_link_libraries(hyperion_x PRIVATE vulkan pthread)
