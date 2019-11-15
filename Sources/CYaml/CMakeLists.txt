
add_library(CYaml
  src/api.c
  src/emitter.c
  src/parser.c
  src/reader.c
  src/scanner.c
  src/writer.c)
if(NOT BUILD_SHARED_LIBS)
  target_compile_definitions(CYaml PRIVATE
    YAML_DECLARE_STATIC)
endif()
target_compile_definitions(CYaml PRIVATE
  YAML_DECLARE_EXPORT)
target_include_directories(CYaml PUBLIC
  include)

set_property(GLOBAL APPEND PROPERTY YAMS_EXPORTS CYaml)
install(TARGETS CYaml
  EXPORT YamsExports
  RUNTIME DESTINATION bin
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})
install(FILES
  include/module.modulemap
  include/yaml.h
  DESTINATION include/cyaml)
