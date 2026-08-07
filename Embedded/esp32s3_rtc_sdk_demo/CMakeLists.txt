# protocols：ESP-IDF 组件，主产物为静态库 build/esp-idf/protocols/libprotocols.a
# 完整配置+编库：idf.py set-target esp32s3 && idf.py build
# 若只需编译库（不链接最终 elf）：cmake --build build --target __idf_protocols
cmake_minimum_required(VERSION 3.16)
include($ENV{IDF_PATH}/tools/cmake/project.cmake)
project(protocols)
