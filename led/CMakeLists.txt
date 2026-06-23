# Include subdirectories
add_subdirectory(drivers)

# add header files in drivers directory so that our app code can find the .h files when we include them
zephyr_include_directories(drivers)