cmake_minimum_required(VERSION 3.20)
project(afterkey VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Widgets)

add_executable(afterkey
    src/main.cpp
    src/settings.cpp
    src/keymap.cpp
    src/keymonitor.cpp
    src/overlay.cpp
    src/settingswindow.cpp
    src/tray.cpp
)

target_link_libraries(afterkey PRIVATE Qt6::Widgets)

install(TARGETS afterkey DESTINATION bin)
