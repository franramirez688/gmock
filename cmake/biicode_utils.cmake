# bii_cxx_test_with_flags(name cxx_flags libs srcs...)
#
# creates a named C++ test that depends on the given libs and is built
# from the given source files with the given compiler flags.
function(bii_cxx_test_with_flags name cxx_flags libs)
  cxx_executable_with_flags(${name} "${cxx_flags}" "${libs}" ${ARGN})
  add_test(${name} ${CMAKE_RUNTIME_OUTPUT_DIRECTORY}/${name})
endfunction()

# bii_cxx_test(name libs srcs...)
#
# creates a named test target that depends on the given libs and is
# built from the given source files.  Unlike bii_cxx_test_with_flags,
# test/name.cc is already implicitly included in the source file list.
function(bii_cxx_test name libs)
  bii_cxx_test_with_flags("${name}" "${cxx_default}" "${libs}"
    "test/${name}.cc" ${ARGN})
endfunction()