
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
target_compile_options(Yams PRIVATE
  $<$<BOOL:${BUILD_TESTING}>:-enable-testing>)

target_link_libraries(Yams PRIVATE
  CYaml
  $<$<NOT:$<PLATFORM_ID:Darwin>>:dispatch>
  $<$<NOT:$<PLATFORM_ID:Darwin>>:Foundation>)
set_target_properties(Yams PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})

set_property(GLOBAL APPEND PROPERTY YAMS_EXPORTS Yams)
swift_install(TARGETS Yams
  EXPORT YamsExports)
