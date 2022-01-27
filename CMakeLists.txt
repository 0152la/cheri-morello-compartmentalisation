cmake_minimum_required(VERSION 3.16)
project(CheriMorelloCompartments)

set(INCLUDE_DIR ${CMAKE_SOURCE_DIR}/include)
set(SRC_DIR ${CMAKE_SOURCE_DIR}/src)
set(TEST_DIR ${CMAKE_SOURCE_DIR}/tests)

# Setup
include_directories("${INCLUDE_DIR}")

find_package(Clang REQUIRED)
find_package(LLVM REQUIRED CONFIG)

# Building
add_subdirectory(${SRC_DIR})

# Testing
if (CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME)
    include(CTest)
endif()

if (CMAKE_PROJECT_NAME STREQUAL PROJECT_NAME AND BUILD_TESTING)
    add_subdirectory(${TEST_DIR})
endif()
