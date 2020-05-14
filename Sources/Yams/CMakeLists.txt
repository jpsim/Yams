
add_library(Yams
  Constructor.swift
  Decoder.swift
  Emitter.swift
  Encoder.swift
  Mark.swift
  Node.Mapping.swift
  Node.Scalar.swift
  Node.Sequence.swift
  Node.swift
  Parser.swift
  Representer.swift
  Resolver.swift
  String+Yams.swift
  Tag.swift
  YamlError.swift)
target_compile_definitions(Yams PRIVATE
  SWIFT_PACKAGE)

target_link_libraries(Yams PRIVATE
  CYaml
  $<$<NOT:$<PLATFORM_ID:Darwin>>:dispatch>
  $<$<NOT:$<PLATFORM_ID:Darwin>>:Foundation>)
set_target_properties(Yams PROPERTIES
  INTERFACE_COMPILE_OPTIONS "SHELL:-Xcc -I$<TARGET_PROPERTY:CYaml,INCLUDE_DIRECTORIES>"
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

set_property(GLOBAL APPEND PROPERTY YAMS_EXPORTS Yams)
get_swift_host_arch(swift_arch)
install(FILES
  ${CMAKE_CURRENT_BINARY_DIR}/swift/Yams.swiftmodule
  ${CMAKE_CURRENT_BINARY_DIR}/swift/Yams.swiftdoc
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/${swift_arch})
install(TARGETS Yams
  EXPORT YamsExports
  RUNTIME DESTINATION bin
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR})
