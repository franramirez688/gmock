###########################################################################
#
#
#     GMock Library CMakeLists.txt adapted to biicode app
#     If you want check the original CMakeLists.txt, see CMakeLists.txt
#
###########################################################################
include(${CMAKE_HOME_DIRECTORY}/biicode.cmake)
# Initializes block variables
INIT_BIICODE_BLOCK()
INCLUDE_DIRECTORIES(${CMAKE_CURRENT_SOURCE_DIR})
SET(gmock_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})
########################################################################
# CMake build script for Google Mock.
#
# To run the tests for Google Mock itself on Linux, use 'make test' or
# ctest.  You can select which tests to run using 'ctest -R regex'.
# For more options, run 'ctest --help'.

# BUILD_SHARED_LIBS is a standard CMake variable, but we declare it here to
# make it prominent in the GUI.
option(BUILD_SHARED_LIBS "Build shared libraries (DLLs)." OFF)

option(gmock_build_tests "Build all of Google Mock's own tests." ON)

# A directory to find Google Test sources.
if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/gtest/CMakeLists.txt")
  set(gtest_dir gtest)
else()
  set(gtest_dir ../gtest)
endif()

# Defines pre_project_set_up_hermetic_build() and set_up_hermetic_build().
include("${gtest_dir}/cmake/hermetic_build.cmake" OPTIONAL)

if (COMMAND pre_project_set_up_hermetic_build)
  # Google Test also calls hermetic setup functions from add_subdirectory,
  # although its changes will not affect things at the current scope.
  pre_project_set_up_hermetic_build()
endif()


# Actually create targets: EXEcutables and libraries.
ADD_BIICODE_TARGETS()
#TARGET_INCLUDE_DIRECTORIES(${BII_LIB_TARGET} PUBLIC include)
INCLUDE_DIRECTORIES(include)
ADD_DEFINITIONS(-DBIICODE)


if (COMMAND set_up_hermetic_build)
  set_up_hermetic_build()
endif()

# Instructs CMake to process Google Test's CMakeLists.txt and add its
# targets to the current scope.  We are placing Google Test's binary
# directory in a subdirectory of our own as VC compilation may break
# if they are the same (the default).
add_subdirectory("${gtest_dir}" "${gmock_BINARY_DIR}/gtest")

# Although Google Test's CMakeLists.txt calls this function, the
# changes there don't affect the current scope.  Therefore we have to
# call it again here.
config_compiler_and_linker()  # from ${gtest_dir}/cmake/internal_utils.cmake

# Adds Google Mock's and Google Test's header directories to the search path.
include_directories("${gmock_SOURCE_DIR}/include"
                    "${gmock_SOURCE_DIR}"
                    "${gtest_SOURCE_DIR}/include"
                    # This directory is needed to build directly from Google
                    # Test sources.
                    "${gtest_SOURCE_DIR}")

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

if (gmock_build_tests)
  # This must be set in the root directory for the tests to be run by
  # 'make test' or ctest.
  enable_testing()

  ############################################################
  # C++ tests built with standard compiler flags.

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

MESSAGE("CMAKE_USE_PTHREADS_INIT ${CMAKE_USE_PTHREADS_INIT}")
if (NOT CMAKE_USE_PTHREADS_INIT)
  set_target_properties(google_gmock_test_gmock_stress_test PROPERTIES EXCLUDE_FROM_ALL 1 EXCLUDE_FROM_DEFAULT_BUILD 1)
endif()
