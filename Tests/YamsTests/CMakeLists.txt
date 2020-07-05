add_library(YamsTests
  ConstructorTests.swift
  EmitterTests.swift
  EncoderTests.swift
  MarkTests.swift
  NodeTests.swift
  PerformanceTests.swift
  RepresenterTests.swift
  ResolverTests.swift
  SpecTests.swift
  StringTests.swift
  TestHelper.swift
  TopLevelDecoderTests.swift
  YamlErrorTests.swift)
set_target_properties(YamsTests PROPERTIES
  INTERFACE_INCLUDE_DIRECTORIES ${CMAKE_Swift_MODULE_DIRECTORY})
target_link_libraries(YamsTests PUBLIC
  Foundation
  XCTest
  Yams)
target_compile_options(YamsTests PRIVATE
  -enable-testing)
