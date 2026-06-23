# Declare current directory "drivers/led" as a target library
# This library is eventually linked to
# app.elf executable
zephyr_library() 

message(STATUS "DEBUG: ZEPHYR_CURRENT_LIBRARY=${ZEPHYR_CURRENT_LIBRARY}")

# List source code files for the this library
zephyr_library_sources_ifdef(CONFIG_MY_LED my_led_driver.c)

#Make header files in this directory accessible by our code
zephyr_include_directories(.)

#include the syscalls from this header in the 
#generated syscall tables(include/generated/zephyr/syscall_dispatch.c)
# for the final binary.
zephyr_syscall_header(${CMAKE_CURRENT_LIST_DIR}/my_led_driver.h)
