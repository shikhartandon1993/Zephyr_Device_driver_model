#Imports subdirectory "led" if KConfig option MY_LED is available
add_subdirectory_ifdef(CONFIG_MY_LED led)