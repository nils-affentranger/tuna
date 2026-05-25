cmake_minimum_required(VERSION 3.22.1)

project(tuna_audio LANGUAGES CXX)

find_package(oboe REQUIRED CONFIG)

add_library(
    tuna_audio
    SHARED
    native_audio.cpp
    pitch_detector.cpp
)

target_include_directories(tuna_audio PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

target_compile_features(tuna_audio PRIVATE cxx_std_17)

target_link_libraries(
    tuna_audio
    oboe::oboe
    android
    log
)
