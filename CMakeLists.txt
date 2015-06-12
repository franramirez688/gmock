###########################################################################
#
#
#     GMock Library CMakeLists.txt adapted to biicode app
#     If you want check the original CMakeLists.txt, see CMakeLists.txt
#
###########################################################################

########################################################################
# CMake build script for Google Mock.
#
# To run the tests for Google Mock itself on Linux, use 'make test' or
# ctest.  You can select which tests to run using 'ctest -R regex'.
# For more options, run 'ctest --help'.

# BUILD_SHARED_LIBS is a standard CMake variable, but we declare it here to
# make it prominent in the GUI.
option(BUILD_SHARED_LIBS "Build shared libraries (DLLs)." OFF)

option(gmock_build_tests "Build all of Google Mock's own tests." OFF)

# A directory to find Google Test sources.
if (EXISTS "${BII_PROJECT_ROOT}/${BII_DEPS_DIR}/google/gtest/CMakeLists.txt")
  set(gtest_dir "${BII_PROJECT_ROOT}/${BII_DEPS_DIR}/google/gtest")
  INCLUDE_DIRECTORIES(${gtest_dir}/include)
  INCLUDE_DIRECTORIES(${gtest_dir})
else()
  MESSAGE(FATAL_ERROR "GTest dependency isn't in your project/deps folder")
endif()

# Defines pre_project_set_up_hermetic_build() and set_up_hermetic_build().
include("${gtest_dir}/cmake/hermetic_build.cmake" OPTIONAL)

if (COMMAND pre_project_set_up_hermetic_build)
  # Google Test also calls hermetic setup functions from add_subdirectory,
  # although its changes will not affect things at the current scope.
  pre_project_set_up_hermetic_build()
endif()

#TARGET_INCLUDE_DIRECTORIES(${BII_LIB_TARGET} PUBLIC include)
INCLUDE_DIRECTORIES(include)


if (COMMAND set_up_hermetic_build)
  set_up_hermetic_build()
endif()

# Although Google Test's CMakeLists.txt calls this function, the
# changes there don't affect the current scope.  Therefore we have to
# call it again here.
config_compiler_and_linker()  # from ${gtest_dir}/cmake/internal_utils.cmake

########################################################################

# To allow GMock to be built as a shared library with MSVC, we have to
# compile it together with GTest sources, so we extract the sources and add
# it to BII_LIB_SRC
list(REMOVE_ITEM BII_LIB_DEPS google_gtest)
get_property(gtest_sources TARGET google_gtest PROPERTY SOURCES)

# We can't just append the relative path gtest source files to BII_LIB_SRC
# and include_directories(${gtest_dir}), as the add_library()...) cmake
# function (used by biicode) expects all files specified in BII_LIB_SRC to
# be relative to the current source directory
set(gtest_sources_abs )
foreach(src ${gtest_sources})
  list(APPEND gtest_sources_abs "${gtest_dir}/${src}")
endforeach()

set(BII_LIB_SRC ${BII_LIB_SRC} ${gtest_sources_abs})

if (MSVC)
  # Disable C4251 warnings as STL templates are not exported as part of
  # the GMock library when building a shared library
  #
  # WARNING: This is only here because there is enough confidence that
  # all template members in GMock's exported interfaces are from the STL.
  foreach(src ${BII_LIB_SRC})
    set_source_files_properties(${src} PROPERTIES COMPILE_FLAGS "/wd4251")
  endforeach()
endif()

# Actually create targets: EXEcutables and libraries.
ADD_BII_TARGETS()

if(BUILD_SHARED_LIBS)
  target_compile_definitions(${BII_LIB_TARGET} PRIVATE "-DGTEST_CREATE_SHARED_LIBRARY=1"
                                               INTERFACE "-DGTEST_LINKED_AS_SHARED_LIBRARY=1")
endif()

IF(BII_BLOCK_TARGET)
  TARGET_INCLUDE_DIRECTORIES(${BII_BLOCK_TARGET} INTERFACE ${CMAKE_CURRENT_SOURCE_DIR})
  TARGET_INCLUDE_DIRECTORIES(${BII_BLOCK_TARGET} INTERFACE ${CMAKE_CURRENT_SOURCE_DIR}/include)
ELSE()
  INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR})
  INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR}/include)
ENDIF()

if (gmock_build_tests)

########################################################################
#
# Defines the gmock & gmock_main libraries.  User tests should link
# with one of them.

# Google Mock libraries.  We build them using more strict warnings than what
# are used for other targets, to ensure that Google Mock can be compiled by
# a user aggressive about warnings.
cxx_library(gmock
            "${cxx_strict}"
            "${gtest_dir}/src/gtest-all.cc"
            src/gmock-all.cc)

cxx_library(gmock_main
            "${cxx_strict}"
            "${gtest_dir}/src/gtest-all.cc"
            src/gmock-all.cc
            src/gmock_main.cc)

if (BIICODE)
  TARGET_INCLUDE_DIRECTORIES(gmock PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
  TARGET_INCLUDE_DIRECTORIES(gmock_main PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
endif()

########################################################################
#
# Google Mock's own tests.
#
# You can skip this section if you aren't interested in testing
# Google Mock itself.
#
# The tests are not built by default.  To build them, set the
# gmock_build_tests option to ON.  You can do it by running ccmake
# or specifying the -Dgmock_build_tests=ON flag when running cmake.


  # This must be set in the root directory for the tests to be run by
  # 'make test' or ctest.
  enable_testing()

  ############################################################
  # C++ tests built with standard compiler flags.

if (BIICODE)
  include(${CMAKE_CURRENT_SOURCE_DIR}/cmake/biicode_utils.cmake)

  # gmock_output_test_ deliberately fails, and is meant for testing the failure output of gmock
  bii_cxx_test(gmock-actions_test gmock_main)
  bii_cxx_test(gmock-cardinalities_test gmock_main)
  bii_cxx_test(gmock_ex_test gmock_main)
  bii_cxx_test(gmock-generated-actions_test gmock_main)
  bii_cxx_test(gmock-generated-function-mockers_test gmock_main)
  bii_cxx_test(gmock-generated-internal-utils_test gmock_main)
  bii_cxx_test(gmock-generated-matchers_test gmock_main)

  if (CMAKE_USE_PTHREADS_INIT)
    bii_cxx_test(gmock_stress_test gmock)
  endif()
else()
  cxx_test(gmock-actions_test gmock_main)
  cxx_test(gmock-cardinalities_test gmock_main)
  cxx_test(gmock_ex_test gmock_main)
  cxx_test(gmock-generated-actions_test gmock_main)
  cxx_test(gmock-generated-function-mockers_test gmock_main)
  cxx_test(gmock-generated-internal-utils_test gmock_main)
  cxx_test(gmock-generated-matchers_test gmock_main)

  if (CMAKE_USE_PTHREADS_INIT)
    cxx_test(gmock_stress_test gmock)
  endif()
endif()

endif()

MESSAGE("CMAKE_USE_PTHREADS_INIT ${CMAKE_USE_PTHREADS_INIT}")
IF (NOT CMAKE_USE_PTHREADS_INIT)
  IF(TARGET google_gmock_test_gmock_stress_test)
    set_target_properties(google_gmock_test_gmock_stress_test PROPERTIES EXCLUDE_FROM_ALL 1 EXCLUDE_FROM_DEFAULT_BUILD 1)
  ENDIF()
ENDIF()
