cmake_minimum_required(VERSION 3.5.0)
project(nota_native)

add_library(nota_recording SHARED nota_recording.cpp)
target_link_libraries(nota_recording PUBLIC
  libace_napi.z.so
  libnative_avscreen_capture.so
)

set(MICROTEX_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/third_party/microtex)
file(GLOB_RECURSE MICROTEX_SOURCES CONFIGURE_DEPENDS
  ${MICROTEX_ROOT}/src/atom/*.cpp
  ${MICROTEX_ROOT}/src/box/*.cpp
  ${MICROTEX_ROOT}/src/core/*.cpp
  ${MICROTEX_ROOT}/src/fonts/*.cpp
  ${MICROTEX_ROOT}/src/res/builtin/*.cpp
  ${MICROTEX_ROOT}/src/res/font/*.cpp
  ${MICROTEX_ROOT}/src/res/parser/*.cpp
  ${MICROTEX_ROOT}/src/res/reg/*.cpp
  ${MICROTEX_ROOT}/src/res/sym/*.cpp
  ${MICROTEX_ROOT}/src/utils/*.cpp
  ${MICROTEX_ROOT}/src/latex.cpp
  ${MICROTEX_ROOT}/src/render.cpp
)

add_library(nota_math SHARED
  nota_math.cpp
  third_party/tinyxml2/tinyxml2.cpp
  ${MICROTEX_SOURCES}
)
target_compile_features(nota_math PRIVATE cxx_std_17)
target_include_directories(nota_math PRIVATE
  ${MICROTEX_ROOT}/src
  ${CMAKE_CURRENT_SOURCE_DIR}/third_party/tinyxml2
)
target_compile_definitions(nota_math PRIVATE NDEBUG)
target_link_libraries(nota_math PUBLIC
  libace_napi.z.so
  libnative_drawing.so
)
