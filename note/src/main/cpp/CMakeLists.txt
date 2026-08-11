cmake_minimum_required(VERSION 3.5.0)
project(nota_recording)

add_library(nota_recording SHARED nota_recording.cpp)
target_link_libraries(nota_recording PUBLIC
  libace_napi.z.so
  libnative_avscreen_capture.so
)
