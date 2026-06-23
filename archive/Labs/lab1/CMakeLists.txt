cmake_minimum_required(VERSION 3.20.0)

message(STATUS "DEBUG: CMAKE_SOURCE_DIR is: ${CMAKE_SOURCE_DIR}")
set(ZEPHYR_EXTRA_MODULES "${CMAKE_SOURCE_DIR}/../../modules/led")


#locates and loads Zephyr’s build system, toolchain,
#to make project as zephyr app
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})

#declares project name, enables languages
project(my_led)

#zephyr defines static library target "app",
#out-of-tree main.c code becomes a "Zephyr" app
target_sources(app PRIVATE src/main.c)