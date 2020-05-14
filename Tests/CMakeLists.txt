find_package(XCTest CONFIG QUIET)

add_subdirectory(YamsTests)

add_executable(YamsTestRunner
  LinuxMain.swift)
target_link_libraries(YamsTestRunner PRIVATE
  YamsTests
  XCTest)

add_test(NAME YamsTests
  COMMAND YamsTestRunner)
