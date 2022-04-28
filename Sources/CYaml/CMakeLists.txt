
add_library(CYaml STATIC
  src/api.c
  src/emitter.c
  src/parser.c
  src/reader.c
  src/scanner.c
  src/writer.c)
target_compile_definitions(CYaml PUBLIC
  $<$<COMPILE_LANGUAGE:C>:YAML_DECLARE_STATIC>)
target_include_directories(CYaml PUBLIC
  $<$<COMPILE_LANGUAGE:C>:${CMAKE_CURRENT_SOURCE_DIR}/include>)
target_compile_options(CYaml PUBLIC
  "$<$<COMPILE_LANGUAGE:Swift>:SHELL:-Xcc -DYAML_DECLARE_STATIC>"
  "$<$<COMPILE_LANGUAGE:Swift>:SHELL:-Xcc -I${CMAKE_CURRENT_SOURCE_DIR}/include>")
set_property(TARGET CYaml PROPERTY POSITION_INDEPENDENT_CODE ON)

set_property(GLOBAL APPEND PROPERTY YAMS_EXPORTS CYaml)
