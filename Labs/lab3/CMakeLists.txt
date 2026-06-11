cmake_minimum_required(VERSION 3.20.0)

message(STATUS "ZEPHYR BASE is: $ENV{ZEPHYR_BASE}")
find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(demo_temperature_driver_model)

target_sources(app PRIVATE src/main.c)

zephyr_linker_sources(SECTIONS ${CMAKE_SOURCE_DIR}/sections-rom.ld)