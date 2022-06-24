###########################################################################
#
#  Library:   CTK
#
#  Copyright (c) Kitware Inc.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0.txt
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
###########################################################################

cmake_minimum_required(VERSION 3.2)

project(CTK)

foreach(p
  CMP0054 # CMake 3.1
  CMP0042
  )
  if(POLICY ${p})
    cmake_policy(SET ${p} NEW)
  endif()
endforeach()

#-----------------------------------------------------------------------------
# Superbuild
#
set(CMAKE_MODULE_PATH "${CMAKE_CURRENT_SOURCE_DIR}/CMake" ${CMAKE_MODULE_PATH})
set(EXTERNAL_PROJECT_DIR ${CMAKE_CURRENT_SOURCE_DIR}/CMakeExternals)
set(EXTERNAL_PROJECT_FILE_PREFIX "")
include(ExternalProject)
include(ctkMacroCheckExternalProjectDependency)

#-----------------------------------------------------------------------------
if(APPLE)
  # Note: By setting CMAKE_OSX_* variables before any enable_language() or project() calls,
  #       we ensure that the bitness will be properly detected.
  include(ctkBlockSetCMakeOSXVariables)
  mark_as_superbuild(
    VARS CMAKE_OSX_ARCHITECTURES:STRING CMAKE_OSX_SYSROOT:PATH CMAKE_OSX_DEPLOYMENT_TARGET:STRING
    ALL_PROJECTS
    )
endif()

#-----------------------------------------------------------------------------

#-----------------------------------------------------------------------------
#-----------------------------------------------------------------------------
# Check miminum Mac OS X version
#-----------------------------------------------------------------------------
# The minimum supported Mac OS X version is 10.9. If you use a version less than 10.9, there is no guarantee that the build still works.
if(APPLE)
  exec_program(sw_vers ARGS -productVersion OUTPUT_VARIABLE osx_version)
  if (osx_version VERSION_LESS "10.9")
    message(WARNING "Detected OS X version \"${osx_version}\" is not supported anymore. Minimum required OS X version is 10.9 or greater.")
  endif()
  if (CMAKE_OSX_DEPLOYMENT_TARGET AND CMAKE_OSX_DEPLOYMENT_TARGET VERSION_LESS 10.9)
    message(WARNING "Detected OS X deployment target \"${CMAKE_OSX_DEPLOYMENT_TARGET}\" is not supported anymore. Minimum required OS X version is 10.9 or greater.")
  endif()
endif()

#-----------------------------------------------------------------------------
# Check miminum compiler versions
#-----------------------------------------------------------------------------

if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
  # require at least gcc 4.7.3 as provided by ppa:ubuntu-toolchain-r/test for Ubuntu 12.04
  if (CMAKE_CXX_COMPILER_VERSION VERSION_LESS 4.7.3)
    message(FATAL_ERROR "GCC version must be at least 4.7.3
If you are using Ubuntu 12.04, you can easily install gcc and g++ 4.7.3 (or any later version available) in addition to your version ${CMAKE_CXX_COMPILER_VERSION}:
  sudo add-apt-repository ppa:ubuntu-toolchain-r/test
  sudo apt-get update
  sudo apt-get install gcc-4.7 g++-4.7
Make sure to explicitly specify these compilers when configuring MITK:
  CMAKE_C_COMPILER:FILEPATH=/usr/bin/gcc-4.7
  CMAKE_CXX_COMPILER:FILEPATH=/usr/bin/g++-4.7
For more information on the proposed PPA see the Toolchain Updates section of https://wiki.ubuntu.com/ToolChain.")
  endif()
elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "Clang")
  # require at least clang 3.4 as provided by Ubuntu 12.04
  if (CMAKE_CXX_COMPILER_VERSION VERSION_LESS 3.4)
    message(FATAL_ERROR "Clang version must be at least 3.4")
  endif()
elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "AppleClang")
  # require at least clang 5.0
  if (CMAKE_CXX_COMPILER_VERSION VERSION_LESS 5.0)
    message(FATAL_ERROR "Apple Clang version must be at least 5.0")
  endif()
elseif("${CMAKE_CXX_COMPILER_ID}" STREQUAL "MSVC")
  # require at least Visual Studio 2012
  if (CMAKE_CXX_COMPILER_VERSION VERSION_LESS 17.0.61030.0)
    message(FATAL_ERROR "Microsoft Visual Studio 2012 Update 4 or newer required (MSVC 17.0.61030.0)")
  endif()
else()
  message(WARNING "You are using an unsupported compiler! Compilation has only been tested with Clang (Linux or Apple), GCC and MSVC.")
endif()

#-----------------------------------------------------------------------------
# MITK Extension Feature
#-----------------------------------------------------------------------------

set(MITK_EXTENSION_DIRS "" CACHE STRING "")

unset(MITK_ABSOLUTE_EXTENSION_DIRS)

foreach(MITK_EXTENSION_DIR ${MITK_EXTENSION_DIRS})
  get_filename_component(MITK_ABSOLUTE_EXTENSION_DIR "${MITK_EXTENSION_DIR}" ABSOLUTE)
  list(APPEND MITK_ABSOLUTE_EXTENSION_DIRS "${MITK_ABSOLUTE_EXTENSION_DIR}")
endforeach()

set(MITK_DIR_PLUS_EXTENSION_DIRS "${MITK_SOURCE_DIR}" ${MITK_ABSOLUTE_EXTENSION_DIRS})

# Compiler settings for MITK.

if(CMAKE_COMPILER_IS_GNUCXX)
  mitkFunctionGetGccVersion(${CMAKE_CXX_COMPILER} GCC_VERSION)
else()
  set(GCC_VERSION 0)
endif()

set(MITK_CXX_STANDARD 11)

set(CMAKE_CXX_EXTENSIONS 0)
set(CMAKE_CXX_STANDARD ${MITK_CXX_STANDARD})
set(CMAKE_CXX_STANDARD_REQUIRED 1)

# This is necessary to avoid problems with compile feature checks.
# CMAKE_CXX_STANDARD seems to only set the -std=c++11 flag for targets.
# However, compile flag checks also need to be done with -std=c++11.
# The MITK_CXX11_FLAG variable is also used for external projects
# build during the MITK super-build.

#mitkFunctionCheckCompilerFlags("-std=c++11" MITK_CXX11_FLAG)
if(NOT MITK_CXX11_FLAG)
  # Older gcc compilers use -std=c++0x
  #mitkFunctionCheckCompilerFlags("-std=c++0x" MITK_CXX11_FLAG)
endif()

#-----------------------------------------------------------------------------
# Warn if source or build path is too long
#-----------------------------------------------------------------------------

if(WIN32)
  set(_src_dir_length_max 50)
  set(_bin_dir_length_max 50)
  if(MITK_USE_SUPERBUILD)
    set(_src_dir_length_max 34) # _src_dir_length_max - strlen(ep/src/ITK-build)
    set(_bin_dir_length_max 40) # _bin_dir_length_max - strlen(MITK-build)
  endif()

  string(LENGTH "${MITK_SOURCE_DIR}" _src_n)
  string(LENGTH "${MITK_BINARY_DIR}" _bin_n)

  # The warnings should be converted to errors
  if(_src_n GREATER _src_dir_length_max)
    message(WARNING "MITK source code directory path length is too long (${_src_n} > ${_src_dir_length_max})."
		    "Please move the MITK source code directory to a directory with a shorter path." )
  endif()
  if(_bin_n GREATER _bin_dir_length_max)
    message(WARNING "MITK build directory path length is too long (${_bin_n} > ${_bin_dir_length_max})."
		    "Please move the MITK build directory to a directory with a shorter path." )
  endif()
endif()
#-----------------------------------------------------------------------------
# Library mode: SHARED (default) or STATIC
#
set(CTK_LIBRARY_MODE "SHARED")

option(CTK_BUILD_SHARED_LIBS "Build CTK libraries as shared module." ON)
mark_as_advanced(CTK_BUILD_SHARED_LIBS)
mark_as_superbuild(CTK_BUILD_SHARED_LIBS)
if(NOT CTK_BUILD_SHARED_LIBS)
  set(CTK_LIBRARY_MODE "STATIC")
endif()

#-----------------------------------------------------------------------------
# Set a default build type if none was specified
#
if(NOT CMAKE_BUILD_TYPE AND NOT CMAKE_CONFIGURATION_TYPES)
  message(STATUS "Setting build type to 'Debug' as none was specified.")
  set(CMAKE_BUILD_TYPE Debug CACHE STRING "Choose the type of build." FORCE)
  mark_as_advanced(CMAKE_BUILD_TYPE)
  # Set the possible values of build type for cmake-gui
  set_property(CACHE CMAKE_BUILD_TYPE PROPERTY STRINGS "Debug" "Release"
    "MinSizeRel" "RelWithDebInfo")
endif()
if(NOT CMAKE_CONFIGURATION_TYPES)
  mark_as_superbuild(VARS CMAKE_BUILD_TYPE ALL_PROJECTS)
endif()

mark_as_superbuild(
  VARS
    CMAKE_PREFIX_PATH:STRING
    CMAKE_DEBUG_POSTFIX:STRING
  ALL_PROJECTS
  )

#-----------------------------------------------------------------------------
# Superbuild Option - Enabled by default
#
option(CTK_SUPERBUILD "Build ${PROJECT_NAME} and the projects it depends on." ON)
mark_as_advanced(CTK_SUPERBUILD)

#-----------------------------------------------------------------------------
# Output directories.
#
foreach(type LIBRARY RUNTIME ARCHIVE)
  # Make sure the directory exists
  if(DEFINED CTK_CMAKE_${type}_OUTPUT_DIRECTORY
     AND NOT EXISTS ${CTK_CMAKE_${type}_OUTPUT_DIRECTORY})
    message(FATAL_ERROR "CTK_CMAKE_${type}_OUTPUT_DIRECTORY is set to a non-existing directory [${CTK_CMAKE_${type}_OUTPUT_DIRECTORY}]")
  endif()

  if(CTK_SUPERBUILD)
    set(output_dir ${CTK_BINARY_DIR}/bin)
    if(NOT DEFINED CTK_CMAKE_${type}_OUTPUT_DIRECTORY)
      set(CTK_CMAKE_${type}_OUTPUT_DIRECTORY ${CTK_BINARY_DIR}/CTK-build/bin)
    endif()
    mark_as_superbuild(CTK_CMAKE_${type}_OUTPUT_DIRECTORY:PATH)
  else()
    if(NOT DEFINED CTK_CMAKE_${type}_OUTPUT_DIRECTORY)
      set(output_dir ${CTK_BINARY_DIR}/bin)
    else()
      set(output_dir ${CTK_CMAKE_${type}_OUTPUT_DIRECTORY})
    endif()
  endif()
  set(CMAKE_${type}_OUTPUT_DIRECTORY ${output_dir} CACHE INTERNAL "Single output directory for building all libraries.")
  if(NOT DEFINED CTK_PLUGIN_${type}_OUTPUT_DIRECTORY)
    set(CTK_PLUGIN_${type}_OUTPUT_DIRECTORY ${CMAKE_${type}_OUTPUT_DIRECTORY})
  endif()
endforeach()

#-----------------------------------------------------------------------------
# CTK version number.  An even minor number corresponds to releases.
#
set(CTK_MAJOR_VERSION 0)
set(CTK_MINOR_VERSION 1)
set(CTK_PATCH_VERSION 0)
set(CTK_VERSION
    "${CTK_MAJOR_VERSION}.${CTK_MINOR_VERSION}.${CTK_PATCH_VERSION}")

# Append the library version information to the library target
# properties.  A parent project may set its own properties and/or may
# block this.
if(NOT CTK_NO_LIBRARY_VERSION)
  set(CTK_LIBRARY_PROPERTIES ${CTK_LIBRARY_PROPERTIES}
    VERSION "${CTK_VERSION}"
    SOVERSION "${CTK_MAJOR_VERSION}.${CTK_MINOR_VERSION}"
    )
endif()

#-----------------------------------------------------------------------------
# Install directories, used for install rules.
#
if(NOT CTK_INSTALL_BIN_DIR)
  set(CTK_INSTALL_BIN_DIR "bin")
endif()
if(NOT CTK_INSTALL_LIB_DIR)
  set(CTK_INSTALL_LIB_DIR "lib/ctk-${CTK_MAJOR_VERSION}.${CTK_MINOR_VERSION}")
endif()
if(NOT CTK_INSTALL_PLUGIN_DIR)
  set(CTK_INSTALL_PLUGIN_DIR "lib/ctk-${CTK_MAJOR_VERSION}.${CTK_MINOR_VERSION}/plugins")
endif()
if(NOT CTK_INSTALL_CMAKE_DIR)
  set(CTK_INSTALL_CMAKE_DIR "lib/ctk-${CTK_MAJOR_VERSION}.${CTK_MINOR_VERSION}/CMake")
endif()
if(NOT CTK_INSTALL_INCLUDE_DIR)
  set(CTK_INSTALL_INCLUDE_DIR "include/ctk-${CTK_MAJOR_VERSION}.${CTK_MINOR_VERSION}")
endif()
if(NOT CTK_INSTALL_PLUGIN_INCLUDE_DIR)
  set(CTK_INSTALL_PLUGIN_INCLUDE_DIR ${CTK_INSTALL_INCLUDE_DIR})
endif()
if(NOT CTK_INSTALL_QTPLUGIN_DIR)
  set(CTK_INSTALL_QTPLUGIN_DIR ${CTK_INSTALL_LIB_DIR})
endif()
if(NOT CTK_INSTALL_DOC_DIR)
  set(CTK_INSTALL_DOC_DIR "doc")
endif()

mark_as_superbuild(
  CTK_INSTALL_BIN_DIR:STRING
  CTK_INSTALL_LIB_DIR:STRING
  CTK_INSTALL_PLUGIN_DIR:STRING
  CTK_INSTALL_CMAKE_DIR:STRING
  CTK_INSTALL_INCLUDE_DIR:STRING
  CTK_INSTALL_PLUGIN_INCLUDE_DIR:STRING
  CTK_INSTALL_QTPLUGIN_DIR:STRING
  CTK_INSTALL_DOC_DIR:STRING
  )

#-----------------------------------------------------------------------------
# Update CMake module path
# Note: FindXXX.cmake script specific to utility should be copied into Utilities/CMake
#
set(CMAKE_MODULE_PATH
  "${CMAKE_CURRENT_SOURCE_DIR}/Utilities/CMake"
  ${CMAKE_MODULE_PATH})

#-----------------------------------------------------------------------------
# Clear CTK_BASE_LIBRARIES and CTK_WRAPPED_LIBRARIES_PYTHONQT
#
set(CTK_BASE_LIBRARIES CACHE INTERNAL "CTK base libraries" FORCE)
set(CTK_WRAPPED_LIBRARIES_PYTHONQT CACHE INTERNAL "CTK libraries wrapped using PythonQt" FORCE)

# Variable use in CTKConfig.cmake.in
set(CTK_LIBRARIES CACHE INTERNAL "CTK libraries" FORCE)
set(${PROJECT_NAME}_PLUGIN_LIBRARIES CACHE INTERNAL "CTK plugins" FORCE)

# Used by CTKGenerateCTKConfig.cmake and also used to reference script from other scripts
set(CTK_CMAKE_DIR ${CTK_SOURCE_DIR}/CMake)
set(CTK_CMAKE_UTILITIES_DIR ${CTK_SOURCE_DIR}/Utilities/CMake)

# MITK necessary configuration variable which are used with functions and macros.
set(MITK_SOURCE_DIR "${CTK_SOURCE_DIR}")
set(MITK_MODULES_PACKAGE_DEPENDS_DIR "${MITK_SOURCE_DIR}/CMake/PackageDepends")
set(MODULES_PACKAGE_DEPENDS_DIRS "${MITK_MODULES_PACKAGE_DEPENDS_DIR}")

if(DEFINED Qt5_DIR AND Qt5_FOUND)
  option(MITK_USE_Qt5 "Use Qt 5 library" ON)
endif()

if(NOT DEFINED Poco_DIR AND Poco_FOUND)
  option(MITK_USE_Poco "Use Poco library" ON)
  find_package(Poco CONFIG REQUIRED)
endif()

option(MITK_USE_BLUEBERRY "Build the BlueBerry platform" ON)

if(MITK_USE_Qt5)
  if(WIN32)
    set(MITK_QT5_MINIMUM_VERSION 5.12.9)
  else()
    set(MITK_QT5_MINIMUM_VERSION 5.12)
  endif()
  set(MITK_QT5_COMPONENTS Concurrent OpenGL PrintSupport Script Sql Svg Widgets Xml XmlPatterns WebEngineWidgets UiTools Help LinguistTools)
  if(APPLE)
    list(APPEND MITK_QT5_COMPONENTS DBus)
  elseif(UNIX)
    list(APPEND MITK_QT5_COMPONENTS X11Extras)
  endif()

  # Hint at default install locations of Qt
  if(NOT Qt5_DIR)
    if(MSVC)
      set(_dir_candidates "C:/Qt")

      if(CMAKE_GENERATOR MATCHES "^Visual Studio [0-9]+ ([0-9]+)")
        set(_compilers "msvc${CMAKE_MATCH_1}")
      elseif(CMAKE_GENERATOR MATCHES "Ninja")
        include(mitkFunctionGetMSVCVersion)
        mitkFunctionGetMSVCVersion()
        if(VISUAL_STUDIO_PRODUCT_NAME MATCHES "^Visual Studio ([0-9]+)")
          set(_compilers "msvc${CMAKE_MATCH_1}")
        endif()
      endif()

      if(_compilers MATCHES "[0-9]+")
        if (CMAKE_MATCH_0 EQUAL 2022)
          list(APPEND _compilers "msvc2019" "msvc2017") # Binary compatible
        elseif (CMAKE_MATCH_0 EQUAL 2019)
          list(APPEND _compilers "msvc2017") # Binary compatible
        endif()
      endif()
    else()
      set(_dir_candidates ~/Qt)

      if(APPLE)
        set(_compilers clang)
      else()
        list(APPEND _dir_candidates /opt/Qt)
        set(_compilers gcc)
      endif()
    endif()

    if(CMAKE_SIZEOF_VOID_P EQUAL 8)
      foreach(_compiler ${_compilers})
        list(APPEND _compilers64 "${_compiler}_64")
      endforeach()
      set(_compilers ${_compilers64})
    endif()

    foreach(_dir_candidate ${_dir_candidates})
      get_filename_component(_dir_candidate ${_dir_candidate} REALPATH)
      foreach(_compiler ${_compilers})
        set(_glob_expression "${_dir_candidate}/5.*/${_compiler}")
        file(GLOB _hints ${_glob_expression})
        list(SORT _hints)
        list(APPEND MITK_QT5_HINTS ${_hints})
      endforeach()
    endforeach()
  endif()

  find_package(Qt5 ${MITK_QT5_MINIMUM_VERSION} COMPONENTS ${MITK_QT5_COMPONENTS} REQUIRED HINTS ${MITK_QT5_HINTS})
endif()
#-----------------------------------------------------------------------------
# CMake function(s) and macro(s)
#
foreach(file
  CMake/ctkListToString.cmake
  CMake/ctkMacroParseArguments.cmake
  CMake/ctkMacroSetPaths.cmake
  CMake/ctkMacroListFilter.cmake
  CMake/ctkMacroOptionUtils.cmake
  CMake/ctkMacroBuildLib.cmake
  CMake/ctkMacroBuildLibWrapper.cmake
  CMake/ctkMacroBuildPlugin.cmake
  CMake/ctkMacroBuildApp.cmake
  CMake/ctkMacroBuildQtPlugin.cmake
  CMake/ctkMacroCompilePythonScript.cmake
  CMake/ctkMacroGenerateMocs.cmake
  CMake/ctkMacroWrapPythonQt.cmake
  CMake/ctkMacroSetupPlugins.cmake
  CMake/ctkMacroSetupQt.cmake
  CMake/ctkMacroTargetLibraries.cmake # Import multiple macros
  CMake/ctkFunctionExtractOptionNameAndValue.cmake
  CMake/ctkMacroValidateBuildOptions.cmake
  CMake/ctkMacroAddCtkLibraryOptions.cmake
  CMake/ctkFunctionGenerateDGraphInput.cmake
  CMake/ctkFunctionGeneratePluginManifest.cmake
  CMake/ctkMacroGeneratePluginResourceFile.cmake
  CMake/ctkFunctionAddPluginRepo.cmake
  CMake/ctkFunctionCheckCompilerFlags.cmake
  CMake/ctkFunctionCheckoutRepo.cmake
  CMake/ctkFunctionGetIncludeDirs.cmake
  CMake/ctkFunctionGetLibraryDirs.cmake
  CMake/ctkFunctionGetGccVersion.cmake
  CMake/ctkFunctionGetCompilerVisibilityFlags.cmake
  CMake/ctkFunctionCompileSnippets.cmake
  CMake/ctkFunctionGetAllPluginTargets.cmake
  
  CMake/mitkFunctionGetGccVersion.cmake
  CMake/mitkFunctionCheckCompilerFlags.cmake
  CMake/mitkFunctionSuppressWarnings.cmake # includes several functions
  CMake/mitkMacroEmptyExternalProject.cmake
  CMake/mitkFunctionGenerateProjectXml.cmake
  CMake/mitkFunctionEnableBuildConfiguration.cmake
  CMake/mitkFunctionWhitelists.cmake
  CMake/mitkFunctionAddExternalProject.cmake
  CMake/mitkFunctionInstallExternalCMakeProject.cmake
  CMake/mitkFunctionCreateModule.cmake
  CMake/mitkFunctionUseModules.cmake
  CMake/mitkFunctionCheckModuleDependencies.cmake
  CMake/mitkFunctionOrganizeSources.cmake
  CMake/mitkFunctionCreateBlueBerryApplication.cmake
  CMake/mitkFunctionInstallCTKPlugin.cmake
  CMake/mitkMacroInstall.cmake
  CMake/mitkMacroInstallTargets.cmake
  CMake/mitkFunctionGetLibrarySearchPaths.cmake
  CMake/mitkFunctionCreateProvisioningFile.cmake
  CMake/mitkFunctionInstallProvisioningFiles.cmake
  CMake/mitkFunctionInstallThirdPartyCTKPlugins.cmake
  CMake/mitkFunctionCreatePlugin.cmake
  CMake/mitkFunctionCheckModuleDependencies.cmake
  CMake/mitkFunctionConfigureVisualStudioUserProjectFile.cmake
  CMake/mitkFunctionCheckCompilerFlags.cmake
  )
  include(${file})
  install(FILES ${file} DESTINATION ${CTK_INSTALL_CMAKE_DIR} COMPONENT Development)
endforeach()

foreach(file
  Libs/ctkExport.h.in
  CMake/ctkLinkerAsNeededFlagCheck.cmake
  CMake/ctk_compile_python_scripts.cmake.in
  CMake/CMakeFindDependencyMacro.cmake
  )
  install(FILES ${file} DESTINATION ${CTK_INSTALL_CMAKE_DIR} COMPONENT Development)
endforeach()

install(FILES
  CMake/ctkLinkerAsNeededFlagCheck/CMakeLists.txt
  CMake/ctkLinkerAsNeededFlagCheck/A.cpp
  CMake/ctkLinkerAsNeededFlagCheck/B.cpp
  CMake/ctkLinkerAsNeededFlagCheck/C.cpp
  DESTINATION ${CTK_INSTALL_CMAKE_DIR}/ctkLinkerAsNeededFlagCheck
  COMPONENT Development
  )

#-----------------------------------------------------------------------------
# Testing
#
include(CTest)
mark_as_advanced(BUILD_TESTING)
mark_as_superbuild(BUILD_TESTING)

if(BUILD_TESTING)
  set(CPP_TEST_PATH ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
  mark_as_advanced(TCL_TCLSH DART_ROOT)

  include(CMake/ctkMacroSimpleTest.cmake)
  include(CMake/ctkMacroSimpleTestWithData.cmake)

  # Setup file for setting custom ctest vars
  configure_file(
    CMake/CTestCustom.cmake.in
    ${CMAKE_CURRENT_BINARY_DIR}/CTestCustom.cmake
    @ONLY
    )

  # Configuration for the CMake-generated test driver
  set(CMAKE_TESTDRIVER_EXTRA_INCLUDES "#include <stdexcept>")
  set(CMAKE_TESTDRIVER_BEFORE_TESTMAIN "
    try
      {")
  set(CMAKE_TESTDRIVER_AFTER_TESTMAIN "    }
      catch( std::exception & excp )
        {
        fprintf(stderr,\"%s\\n\",excp.what());
        return EXIT_FAILURE;
        }
      catch( ... )
        {
        printf(\"Exception caught in the test driver\\n\");
        return EXIT_FAILURE;
        }
      ")
endif()

#-----------------------------------------------------------------------------
# QtTesting
#
option(CTK_USE_QTTESTING "Enable/Disable QtTesting" OFF)
mark_as_advanced(CTK_USE_QTTESTING)
mark_as_superbuild(CTK_USE_QTTESTING)

#-----------------------------------------------------------------------------
# Coverage
#
option(WITH_COVERAGE "Enable/Disable coverage" OFF)
mark_as_advanced(WITH_COVERAGE)
mark_as_superbuild(WITH_COVERAGE)

#-----------------------------------------------------------------------------
# Documentation
#
option(DOCUMENTATION_TARGET_IN_ALL "Include the custom target for building documentation in 'all'" OFF)
mark_as_advanced(DOCUMENTATION_TARGET_IN_ALL)
mark_as_superbuild(DOCUMENTATION_TARGET_IN_ALL)

set(DOCUMENTATION_ARCHIVES_OUTPUT_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
 CACHE PATH "Where documentation archives should be stored")
mark_as_advanced(DOCUMENTATION_ARCHIVES_OUTPUT_DIRECTORY)
mark_as_superbuild(DOCUMENTATION_ARCHIVES_OUTPUT_DIRECTORY)

# Attempt to discover Doxygen so that DOXYGEN_EXECUTABLE is set to an appropriate default value
find_package(Doxygen QUIET)
mark_as_superbuild(DOXYGEN_EXECUTABLE)

#-----------------------------------------------------------------------------
# Additional CXX/C Flags
#
set(ADDITIONAL_C_FLAGS "" CACHE STRING "Additional C Flags")
mark_as_advanced(ADDITIONAL_C_FLAGS)
mark_as_superbuild(ADDITIONAL_C_FLAGS)

set(ADDITIONAL_CXX_FLAGS "" CACHE STRING "Additional CXX Flags")
mark_as_advanced(ADDITIONAL_CXX_FLAGS)
mark_as_superbuild(ADDITIONAL_CXX_FLAGS)

#-----------------------------------------------------------------------------
# Set symbol visibility Flags
#

ctkFunctionGetCompilerVisibilityFlags(VISIBILITY_CXX_FLAGS)

#-----------------------------------------------------------------------------
# Set coverage Flags
#
if(WITH_COVERAGE)
  if("${CMAKE_CXX_COMPILER_ID}" STREQUAL "GNU")
    set(coverage_flags "-g -fprofile-arcs -ftest-coverage -O0 -DNDEBUG")
    set(COVERAGE_CXX_FLAGS ${coverage_flags})
    set(COVERAGE_C_FLAGS ${coverage_flags})
  endif()
endif()

#-----------------------------------------------------------------------------
# CTK C/CXX Flags
#
set(CTK_C_FLAGS "${CMAKE_C_FLAGS_INIT} ${COVERAGE_C_FLAGS} ${ADDITIONAL_C_FLAGS}")
set(CTK_CXX_FLAGS "${CMAKE_CXX_FLAGS_INIT} ${VISIBILITY_CXX_FLAGS} ${COVERAGE_CXX_FLAGS} ${ADDITIONAL_CXX_FLAGS}")

if(CMAKE_COMPILER_IS_GNUCXX)
  set(cflags "-Wall -Wextra -Wpointer-arith -Winvalid-pch -Wcast-align -Wwrite-strings")
  if(CMAKE_BUILD_TYPE STREQUAL "Release" OR CMAKE_BUILD_TYPE STREQUAL "RelWithDebInfo")
    set(cflags "${cflags} -D_FORTIFY_SOURCE=2")
  endif()

  ctkFunctionCheckCompilerFlags("-fdiagnostics-show-option" cflags)
  ctkFunctionCheckCompilerFlags("-Wl,--no-undefined" cflags)

  ctkFunctionGetGccVersion(${CMAKE_CXX_COMPILER} GCC_VERSION)

  # With older version of gcc supporting the flag -fstack-protector-all, an extra dependency to libssp.so
  # is introduced. If gcc is smaller than 4.4.0 and the build type is Release let's not include the flag.
  # Doing so should allow to build package made for distribution using older linux distro.
  if(${GCC_VERSION} VERSION_GREATER "4.4.0" OR (CMAKE_BUILD_TYPE STREQUAL "Debug" AND ${GCC_VERSION} VERSION_LESS "4.4.0"))
    ctkFunctionCheckCompilerFlags("-fstack-protector-all" cflags)
  endif()
  if(MINGW)
    # suppress warnings about auto imported symbols
    set(CTK_CXX_FLAGS "-Wl,--enable-auto-import ${CTK_CXX_FLAGS}")
  endif()

  set(CTK_C_FLAGS "${cflags} ${CTK_C_FLAGS}")
  set(CTK_CXX_FLAGS "${cflags} -Woverloaded-virtual -Wold-style-cast -Wstrict-null-sentinel -Wsign-promo ${CTK_CXX_FLAGS}")
endif()

if(MSVC)
  set(msvc_suppressed_warnings
    "/wd4290" # C++ exception specification ignored except to indicate a function is not __declspec(nothrow)
  )
  set(CTK_CXX_FLAGS "${CTK_CXX_FLAGS} ${msvc_suppressed_warnings} -DNOMINMAX")
endif()

#-----------------------------------------------------------------------------
# Check if the linker will resolve symbols of underlinked libraries
#
if(UNIX AND NOT APPLE)
  include(ctkLinkerAsNeededFlagCheck)
  if(CTK_LINKER_NO_AS_NEEDED_FLAG_REQUIRED)
    set(CTK_EXE_LINKER_FLAGS "-Wl,--no-as-needed")
  endif()
endif()

#-----------------------------------------------------------------------------
# QT
#
ctkMacroSetupQt()

# Update CTK_BASE_LIBRARIES with QT libraries
if(QT4_FOUND)
  set(CTK_BASE_LIBRARIES ${CTK_BASE_LIBRARIES} ${QT_LIBRARIES} CACHE INTERNAL "CTK base libraries" FORCE)
endif()

#-----------------------------------------------------------------------------
# To make options show up in both CTK-SuperBuild and CTK regular build, let's add them
# before the SuperBuild script is included
#

#-----------------------------------------------------------------------------
# Special "BUILD ALL" options

# Build all CTK plug-ins
option(CTK_BUILD_ALL_PLUGINS "Build all CTK plug-ins" OFF)
mark_as_superbuild(CTK_BUILD_ALL_PLUGINS)

# Build all CTK libraries
option(CTK_BUILD_ALL_LIBRARIES "Build all CTK libraries" OFF)
mark_as_superbuild(CTK_BUILD_ALL_LIBRARIES)

# Build all CTK applications
option(CTK_BUILD_ALL_APPS "Build all CTK applications" OFF)
mark_as_superbuild(CTK_BUILD_ALL_APPS)

# Build everything
option(CTK_BUILD_ALL "Build everything in CTK" OFF)
mark_as_superbuild(CTK_BUILD_ALL)
if(CTK_BUILD_ALL)
  set(CTK_BUILD_ALL_PLUGINS 1)
  set(CTK_BUILD_ALL_LIBRARIES 1)
  set(CTK_BUILD_ALL_APPS 1)
endif()

#-----------------------------------------------------------------------------
# Other options

# Git protocol option
option(CTK_USE_GIT_PROTOCOL "If behind a firewall turn this OFF to use http instead." ON)
mark_as_advanced(CTK_USE_GIT_PROTOCOL)
set(git_protocol "git")
if(NOT CTK_USE_GIT_PROTOCOL)
  set(git_protocol "http")
endif()

# Let's mark as advanced some default properties
mark_as_advanced(CMAKE_INSTALL_PREFIX)
mark_as_advanced(DART_TESTING_TIMEOUT)

# KWStyle
option(CTK_USE_KWSTYLE     "Enable sourcecode-based style tests." OFF)
mark_as_advanced(CTK_USE_KWSTYLE)
mark_as_superbuild(CTK_USE_KWSTYLE)

# Qt Designer Plugins
#option(CTK_BUILD_QTDESIGNER_PLUGINS "Build Qt Designer plugins" ON)
#mark_as_advanced(CTK_BUILD_QTDESIGNER_PLUGINS)
#mark_as_superbuild(CTK_BUILD_QTDESIGNER_PLUGINS)

#-----------------------------------------------------------------------------
# CTK Libraries
#

ctk_lib_option(Core
               "Build the Core library" ON)

               
ctk_lib_option(PluginFramework
              "Build the Plugin Framework" OFF
              CTK_ENABLE_PluginFramework)
            
ctk_lib_option(Widgets
              "Build the Widgets library" OFF
              CTK_ENABLE_Widgets OR CTK_USE_QTTESTING)

ctk_lib_option(AppUtil
              "Build the AppLib library port from MITK" ON)

ctk_lib_option(CommandLineModules/Core
	       "Build the Command Line Module core library" OFF)

ctk_lib_option(CommandLineModules/Frontend/QtWebKit
	       "Build the QtWebKit based Command Line Module front-end" OFF)

ctk_lib_option(CommandLineModules/Frontend/QtGui
	       "Build the QtGui based Command Line Module front-end" OFF)

ctk_lib_option(CommandLineModules/Backend/XMLChecker
	       "Build the Command Line Module back-end for checking XML" OFF)

ctk_lib_option(CommandLineModules/Backend/LocalProcess
	       "Build the Command Line Module back-end for local processes" OFF)

ctk_lib_option(CommandLineModules/Backend/FunctionPointer
	       "Build the Command Line Module back-end for function pointers" OFF)

# Save the set of enabled libs in a cache file
set(_enabled_libs)
foreach(_lib ${CTK_LIBS})
  if(CTK_LIB_${_lib})
    list(APPEND _enabled_libs ${_lib})
  endif()
endforeach()
set(CTK_ENABLED_LIBS ${_enabled_libs} CACHE INTERNAL "" FORCE)
#-----------------------------------------------------------------------------
# CTK Applications - Use ON or OFF to indicate if the application should be built by default
#


# We use the CTKWidgets library together with the Qt Designer plug-in
# in ctkCommandLineModuleExplorer, so enabling the options here.
# (We do not need to link them into the executable, hence no entries
# in target_libraries.cmake)

#if(CTK_APP_ctkCommandLineModuleExplorer)
#  foreach(_option CTK_BUILD_QTDESIGNER_PLUGINS)
#    if(NOT ${_option})
#      get_property(_docstring CACHE ${_option} PROPERTY HELPSTRING)
#      set(${_option} ON CACHE BOOL "${_docstring}" FORCE)
#      message("Enabling option [${_option}] required by [ctkCommandLineModuleExplorer]")
#    endif()
#  endforeach()
#endif()

# Save the set of enabled apps in a cache file
set(_enabled_apps)
foreach(_app ${CTK_APPS})
  if(CTK_APP_${_app})
    list(APPEND _enabled_apps ${_app})
  endif()
endforeach()
set(CTK_ENABLED_APPS ${_enabled_apps} CACHE INTERNAL "" FORCE)

#-----------------------------------------------------------------------------
# BlueBerry Plugins - none of them is build by default
#
if(MITK_USE_BLUEBERRY)
  option(MITK_BUILD_ALL_PLUGINS "Build all MITK BlueBerry plugins" OFF)
  mark_as_advanced(MITK_BUILD_ALL_PLUGINS)
endif()

#-----------------------------------------------------------------------------
# Installation preparation
#
# These should be set before any MITK install macros are used
#-----------------------------------------------------------------------------

# on macOS all BlueBerry plugins get copied into every
# application bundle (.app directory) specified here
if(MITK_USE_BLUEBERRY AND APPLE)

  foreach(MITK_EXTENSION_DIR ${MITK_DIR_PLUS_EXTENSION_DIRS})
    set(MITK_APPLICATIONS_EXTENSION_DIR "${MITK_EXTENSION_DIR}/Applications")
    if(EXISTS "${MITK_APPLICATIONS_EXTENSION_DIR}/AppList.cmake")
      set(MITK_APPS "")
      include("${MITK_APPLICATIONS_EXTENSION_DIR}/AppList.cmake")
      foreach(mitk_app ${MITK_APPS})
        # extract option_name
        string(REPLACE "^^" "\\;" target_info ${mitk_app})
        set(target_info_list ${target_info})
        list(GET target_info_list 1 option_name)
        list(GET target_info_list 0 app_name)
        # check if the application is enabled
        if(${option_name} OR MITK_BUILD_ALL_APPS)
          set(MACOSX_BUNDLE_NAMES ${MACOSX_BUNDLE_NAMES} ${app_name}) # Commented this part Mitk${app_name})
        endif()
      endforeach()
    endif()
  endforeach()

endif()

# Qt support
if(MITK_USE_Qt5)
  find_package(Qt5Core ${MITK_QT5_MINIMUM_VERSION} REQUIRED) # at least Core required
  get_target_property(_qmake_exec Qt5::qmake LOCATION)
  execute_process(COMMAND ${_qmake_exec} -query QT_INSTALL_BINS
    RESULT_VARIABLE _result
     OUTPUT_VARIABLE QT_BINARY_DIR
    ERROR_VARIABLE _error
  )
  string(STRIP "${QT_BINARY_DIR}" QT_BINARY_DIR)
  if(_result OR NOT EXISTS "${QT_BINARY_DIR}")
    message(FATAL_ERROR "Could not determine Qt binary directory: ${_result} ${QT_BINARY_DIR} ${_error}")
  endif()

  find_program(QT_HELPGENERATOR_EXECUTABLE
    NAMES qhelpgenerator qhelpgenerator-qt5 qhelpgenerator5
    PATHS ${QT_BINARY_DIR}
    NO_DEFAULT_PATH
  )

  find_program(QT_COLLECTIONGENERATOR_EXECUTABLE
    NAMES qcollectiongenerator qcollectiongenerator-qt5 qcollectiongenerator5
    PATHS ${QT_BINARY_DIR}
    NO_DEFAULT_PATH
  )

  find_program(QT_ASSISTANT_EXECUTABLE
    NAMES assistant assistant-qt5 assistant5
    PATHS ${QT_BINARY_DIR}
    NO_DEFAULT_PATH
  )

  find_program(QT_XMLPATTERNS_EXECUTABLE
    NAMES xmlpatterns
    PATHS ${QT_BINARY_DIR}
    NO_DEFAULT_PATH
  )

  mark_as_advanced(QT_HELPGENERATOR_EXECUTABLE
                   QT_COLLECTIONGENERATOR_EXECUTABLE
                   QT_ASSISTANT_EXECUTABLE
                   QT_XMLPATTERNS_EXECUTABLE
                  )

  if(MITK_USE_BLUEBERRY)
    option(BLUEBERRY_USE_QT_HELP "Enable support for integrating plugin documentation into Qt Help" ${DOXYGEN_FOUND})
    mark_as_advanced(BLUEBERRY_USE_QT_HELP)

    # Sanity checks for in-application BlueBerry plug-in help generation
    if(BLUEBERRY_USE_QT_HELP)
      set(_force_blueberry_use_qt_help_to_off 0)
      if(NOT DOXYGEN_FOUND)
        message("> Forcing BLUEBERRY_USE_QT_HELP to OFF because Doxygen was not found.")
        set(_force_blueberry_use_qt_help_to_off 1)
      endif()
      if(DOXYGEN_FOUND AND DOXYGEN_VERSION VERSION_LESS 1.8.7)
        message("> Forcing BLUEBERRY_USE_QT_HELP to OFF because Doxygen version 1.8.7 or newer not found.")
        set(_force_blueberry_use_qt_help_to_off 1)
      endif()

      if(NOT QT_HELPGENERATOR_EXECUTABLE)
        message("> Forcing BLUEBERRY_USE_QT_HELP to OFF because QT_HELPGENERATOR_EXECUTABLE is empty.")
        set(_force_blueberry_use_qt_help_to_off 1)
      endif()

      if(NOT MITK_USE_Qt5)
        message("> Forcing BLUEBERRY_USE_QT_HELP to OFF because MITK_USE_Qt5 is OFF.")
        set(_force_blueberry_use_qt_help_to_off 1)
      endif()

      if(NOT QT_XMLPATTERNS_EXECUTABLE)
        message("You have enabled Qt Help support, but QT_XMLPATTERNS_EXECUTABLE is empty")
        set(_force_blueberry_use_qt_help_to_off 1)
      endif()

      if(_force_blueberry_use_qt_help_to_off)
        set(BLUEBERRY_USE_QT_HELP OFF CACHE BOOL "Enable support for integrating plugin documentation into Qt Help" FORCE)
      endif()
    endif()

    if(BLUEBERRY_QT_HELP_REQUIRED AND NOT BLUEBERRY_USE_QT_HELP)
      message(FATAL_ERROR "BLUEBERRY_USE_QT_HELP is required to be set to ON")
    endif()
  endif()

endif()

#-----------------------------------------------------------------------------
# CTK Plugins - none of them is build by default
#

# Plugins in the list below are not build by default
set(plugin_list
  org.commontk.configadmin
  org.commontk.eventadmin
  org.commontk.log
  org.commontk.metatype
  )

if(CTK_QT_VERSION VERSION_LESS "5")
  list(APPEND plugin_list org.commontk.log4qt)
endif()

foreach(_plugin ${plugin_list})
  ctk_plugin_option(${_plugin} "Build the ${_plugin} plugin." ON)
endforeach()

# Plug-ins related to the PluginGenerator application
ctk_plugin_option(org.commontk.plugingenerator.core "Build the org.commontk.plugingenerator.core plugin." OFF)

#ctk_plugin_option(org.commontk.plugingenerator.ui
#                  "Build the org.commontk.plugingenerator.ui plugin." OFF
#                  CTK_APP_ctkPluginGenerator)

# Plug-ins related to the EventBus demo application
if(CTK_QT_VERSION VERSION_LESS "5")
ctk_plugin_option(org.commontk.eventbus
                  "Build the org.commontk.eventbus plugin." OFF
                  CTK_APP_ctkEventBusDemo)
endif()

# Add the PluginsContrib repo to the build system
option(CTK_USE_CONTRIBUTED_PLUGINS OFF "Use CTK plug-ins from the PluginsContrib repository")
mark_as_advanced(CTK_USE_CONTRIBUTED_PLUGINS)
mark_as_superbuild(CTK_USE_CONTRIBUTED_PLUGINS)
if(CTK_USE_CONTRIBUTED_PLUGINS)
  ctkFunctionAddPluginRepo(NAME PluginsContrib
                           GIT_URL github.com/commontk/PluginsContrib.git
                           GIT_TAG f016d35
                          )
  mark_as_superbuild(PluginsContrib_DIR:PATH)
endif()

#-----------------------------------------------------------------------------
# High-Level CTK options

# The ctk_enable_option macro expects a logical expression after the first
# three arguments. This expression should only contain build option names
# which belong to leafs in the required dependency tree.

ctk_enable_option(Widgets "Enable Qt Widget libraries" OFF
                  CTK_LIB_Widgets)
                  
# The CTK Plugin Framework, a dynamic component system based on OSGi.
# This will enable only the framework itself.
ctk_enable_option(PluginFramework "Enable Plugin Framework" OFF
                  CTK_LIB_PluginFramework)

# Build examples
# Create the logical expression containing the minium set of required options
# for the CTK_BUILD_EXAMPLES option to be ON
set(_build_examples_logical_expr)
foreach(_app ${CTK_ENABLED_APPS})
  list(APPEND _build_examples_logical_expr CTK_APP_${_app} AND)
endforeach()
if(_build_examples_logical_expr)
  list(REMOVE_AT _build_examples_logical_expr -1)
endif()

ctk_enable_option_raw(CTK_BUILD_EXAMPLES "Build examples for CTK components" OFF
                  ${_build_examples_logical_expr})

#-----------------------------------------------------------------------------
# Generate target_directories list - List of directory corresponding to the different
# libraries, plugins and applications associated with the corresponding option name.
#
# The following FOREACH loops are used to:
#   1) Update either CTK_LIBS_SUBDIRS, CTK_PLUGINS_SUBDIRS or CTK_APPS_SUBDIRS variables
#
# For CTK libraries, if the file Libs/<DIR>/<LIBNAME>/ctk_library_options.cmake exists,
# in addition to 'CTK_LIB_<DIR>/<LIBNAME>' option, the following ones
# will also be available in CMake configure menu:
#  CTK_LIB_<DIR>/<LIBNAME>_OPT1  (set to OFF)
#  CTK_LIB_<DIR>/<LIBNAME>_OPT2  (set to ON)
#
# The file Libs/<DIR>/<LIBNAME>/ctk_library_options.cmake should look like:
#
#     set(ctk_library_options
#       OPT1:OFF
#       OPT2:ON
#       )


# Create list of directories corresponding to the enabled targets
set(target_directories)

# Setup testing environment before Libs are added by simulating
# the use of 'ctk_lib_option' for CTKTesting library
set(CTK_LIB_Testing FALSE)
list(APPEND CTK_LIBS Testing)
list(APPEND target_directories "${CMAKE_CURRENT_SOURCE_DIR}/Libs/Testing^^CTK_LIB_Testing")

foreach(lib ${CTK_LIBS})
  if(CTK_LIB_${lib})
    ctkMacroAddCtkLibraryOptions(${lib})
  endif()
  list(APPEND target_directories "${CMAKE_CURRENT_SOURCE_DIR}/Libs/${lib}^^CTK_LIB_${lib}")
endforeach()

foreach(plugin ${CTK_PLUGINS})
  if(${plugin}_SOURCE_DIR)
    list(APPEND target_directories "${${plugin}_SOURCE_DIR}^^CTK_PLUGIN_${plugin}")
  else()
    list(APPEND target_directories "${CMAKE_CURRENT_SOURCE_DIR}/Plugins/${plugin}^^CTK_PLUGIN_${plugin}")
  endif()
endforeach()

foreach(app ${CTK_APPS})
  list(APPEND target_directories "${CMAKE_CURRENT_SOURCE_DIR}/Applications/${app}^^CTK_APP_${app}")
endforeach()

# Emulate the use of 'ctk_lib_option' for CTKQtTesting library
set(CTK_LIB_QtTesting ${CTK_USE_QTTESTING})
if(CTK_USE_QTTESTING)
  list(APPEND CTK_LIBS QtTesting)
  list(APPEND target_directories "${CMAKE_CURRENT_SOURCE_DIR}/Libs/QtTesting^^CTK_LIB_QtTesting")
endif()

#message(STATUS target_directories:${target_directories})

#-----------------------------------------------------------------------------
# Compile DGraph - An application allowing to check for cycle in DAG and also obtain the
# topological order.
try_compile(RESULT_VAR ${CTK_BINARY_DIR}/Utilities/DGraph ${CTK_SOURCE_DIR}/Utilities/DGraph
              DGraph
              CMAKE_FLAGS
                -DCMAKE_OSX_ARCHITECTURES:STRING=${CMAKE_OSX_ARCHITECTURES}
                -DCMAKE_OSX_DEPLOYMENT_TARGET:STRING=${CMAKE_OSX_DEPLOYMENT_TARGET}
                -DCMAKE_OSX_SYSROOT:STRING=${CMAKE_OSX_SYSROOT}
                -DCMAKE_VERBOSE_MAKEFILE:BOOL=FALSE
              OUTPUT_VARIABLE output)
if(NOT RESULT_VAR)
  message(FATAL_ERROR "Failed to compile DGraph application.\n${output}")
endif()
find_program(DGraph_EXECUTABLE DGraph
  "${CTK_BINARY_DIR}/Utilities/DGraph/"
  "${CTK_BINARY_DIR}/Utilities/DGraph/bin/"
  "${CTK_BINARY_DIR}/Utilities/DGraph/Debug/"
  "${CTK_BINARY_DIR}/Utilities/DGraph/Release/")
mark_as_advanced(DGraph_EXECUTABLE)

# Set optional dependencies not captured in 'target_libraries.cmake' files.
if(CTK_LIB_Scripting/Python/Core AND CTK_LIB_Scripting/Python/Core_PYTHONQT_USE_VTK)
  set(ctkSimplePythonShell_OPTIONAL_DEPENDENCIES CTKVisualizationVTKCore VTK_LIBRARIES)
endif()

set(CTKQtTesting_OPTIONAL_DEPENDENCIES)
if(CTK_LIB_Widgets)
  list(APPEND CTKQtTesting_OPTIONAL_DEPENDENCIES CTKWidgets)
endif()
if(CTK_LIB_Visualization/VTK/Widgets)
  list(APPEND CTKQtTesting_OPTIONAL_DEPENDENCIES CTKVisualizationVTKWidgets)
endif()

#-----------------------------------------------------------------------------
# Let's make sure the enabled/disabled libraries, plugins or applications are coherent
#
ctkFunctionGenerateDGraphInput(${CTK_BINARY_DIR} "${target_directories}")
ctkFunctionGenerateDGraphInput(${CTK_BINARY_DIR} "${target_directories}" WITH_EXTERNALS)
ctkMacroValidateBuildOptions("${CTK_BINARY_DIR}" "${DGraph_EXECUTABLE}" "${target_directories}")

#-----------------------------------------------------------------------------
# DGraph
#

# Generate DGraph input file expected by DGraph
ctkFunctionGenerateDGraphInput(${CTK_BINARY_DIR} "${target_directories}" WITH_OPTION)

# Obtain list of target ordered topologically
ctkMacroSetPaths("${QT_INSTALLED_LIBRARY_DIR}")
execute_process(
  COMMAND "${DGraph_EXECUTABLE}" "${CTK_BINARY_DIR}/DGraphInput.txt"
  WORKING_DIRECTORY ${CTK_BINARY_DIR}
  RESULT_VARIABLE RESULT_VAR
  OUTPUT_VARIABLE CTEST_PROJECT_SUBPROJECTS_OUTPUT
  ERROR_VARIABLE error
  OUTPUT_STRIP_TRAILING_WHITESPACE
  )
if(RESULT_VAR)
  message(FATAL_ERROR "Failed to obtain list of target ordered topologically.\n${RESULT_VAR}\n${CTK_BINARY_DIR}\n${error}")
endif()

# Convert 'CTEST_PROJECT_SUBPROJECTS_OUTPUT' to a list
string(REPLACE " " "\\;" CTEST_PROJECT_SUBPROJECTS "${CTEST_PROJECT_SUBPROJECTS_OUTPUT}")
set(CTEST_PROJECT_SUBPROJECTS ${CTEST_PROJECT_SUBPROJECTS})

# If the list of subproject is empty, let's at least build CTKCore
list(LENGTH CTEST_PROJECT_SUBPROJECTS subproject_count)
if(subproject_count EQUAL 0)
  set(CTEST_PROJECT_SUBPROJECTS CTKCore)
endif()

#-----------------------------------------------------------------------------
# CTK dependencies - Projects should be TOPOLOGICALLY ordered
#-----------------------------------------------------------------------------
set(CTK_DEPENDENCIES
  #Poco
  mbilog
  itkCommon
  qtsingleapplication
  mitkCore
  QtTesting
  CppMicroServices
  )

if(CTK_USE_KWSTYLE)
  list(APPEND CTK_DEPENDENCIES KWStyle)
endif()

#-----------------------------------------------------------------------------
# Check out the ExternalProjectsContrib repository
if(CTK_USE_CONTRIBUTED_PLUGINS)
  if(CTK_SUPERBUILD)
    ctkFunctionCheckoutRepo(
      NAME ExternalProjectsContrib
      GIT_URL github.com/commontk/ExternalProjectsContrib.git
      GIT_TAG 4c944ef
      )
    mark_as_superbuild(ExternalProjectsContrib_DIR:PATH)
  endif()

  file(GLOB _contrib_scripts ${ExternalProjectsContrib_DIR}/*.cmake)
  foreach(_contrib_script ${_contrib_scripts})
    get_filename_component(_script_name ${_contrib_script} NAME_WE)
    list(APPEND CTK_DEPENDENCIES ${_script_name})
    set(${_script_name}_FILEPATH ${_contrib_script})
  endforeach()
endif()

include(CMake/ctkBlockCheckDependencies.cmake)

#-----------------------------------------------------------------------------
# Superbuild script
#

if(CTK_SUPERBUILD)
  include("${CMAKE_CURRENT_SOURCE_DIR}/SuperBuild.cmake")
  return()
endif()

if(BUILD_TESTING)
  add_subdirectory(CMake/Testing)
endif()

#-----------------------------------------------------------------------------
# Expand variables containing include and library directories for external projects
# This relies on the variable EXTERNAL_TARGETS set in ctkMacroValidateBuildOptions
foreach(_external_target ${EXTERNAL_TARGETS})
  set(_package_name ${${_external_target}_FIND_PACKAGE_CMD})
  if(_package_name)
    superbuild_is_external_project_includable(${_package_name} required)
    if(required)
      #message("Calling find_package(${_package_name})")
      find_package(${_package_name} REQUIRED)
    endif()
  endif()
endforeach()

foreach(_external_target ${EXTERNAL_TARGETS})
  set(_package_name ${${_external_target}_FIND_PACKAGE_CMD})
  if("${_package_name}" STREQUAL "")
    set(_package_name ${_external_target})
  endif()
  if(${_external_target}_INCLUDE_DIRS)
    #message("[${_package_name}] Resolving include variables: ${${_external_target}_INCLUDE_DIRS}")
    set(_updated_include_dirs)
    foreach(_include_variable ${${_external_target}_INCLUDE_DIRS})
      set(_expanded_include_variable ${_include_variable})
      if(${_include_variable})
        #message("[${_package_name}] Expanding [${_include_variable}] into [${${_include_variable}}]")
        set(_expanded_include_variable ${${_include_variable}})
      endif()
      foreach(_include_dir ${_expanded_include_variable})
        if(EXISTS ${_include_dir})
          #message("[${_package_name}] Appending ${_include_dir}")
          list(APPEND _updated_include_dirs ${_include_dir})
        else()
          message(STATUS "[${_package_name}] Skipping nonexistent include directory or not set variable [${_include_dir}]")
        endif()
      endforeach()
      #message("[${_package_name}] New dirs: ${_updated_include_dirs}")
    endforeach()
    set(${_external_target}_INCLUDE_DIRS ${_updated_include_dirs})
    #message("[${_package_name}] Appended dirs: ${${_external_target}_INCLUDE_DIRS}")
  endif()
  if(${_external_target}_LIBRARY_DIRS)
    #message("[${_package_name}] Resolving library variables: ${${_external_target}_LIBRARY_DIRS}")
    set(_updated_library_dirs)
    foreach(_library_variable ${${_external_target}_LIBRARY_DIRS})
      set(_expanded_library_variable ${_library_variable})
      if(${_library_variable})
        #message("[${_package_name}] Expanding [${_library_variable}] into [${${_library_variable}}]")
        set(_expanded_library_variable ${${_library_variable}})
      endif()
      foreach(_library_dir ${_expanded_library_variable})
        if(EXISTS ${_library_dir})
          #message("[${_package_name}] Appending ${_library_dir}")
          list(APPEND _updated_library_dirs ${_library_dir})
        else()
          message(STATUS "[${_package_name}] Skipping nonexistent library directory or not set variable [${_library_dir}]")
        endif()
      endforeach()
      #message("[${_package_name}] New dirs: ${_updated_library_dirs}")
    endforeach()
    set(${_external_target}_LIBRARY_DIRS ${_updated_library_dirs})
    #message("[${_package_name}] Appended dirs: ${${_external_target}_LIBRARY_DIRS}")
  endif()
endforeach()

set(CTK_WRAP_PYTHONQT_USE_VTK ${CTK_LIB_Scripting/Python/Core_PYTHONQT_USE_VTK})

#-----------------------------------------------------------------------------
# CTK_SUPERBUILD_BINARY_DIR

# If CTK_SUPERBUILD_BINARY_DIR isn't defined, it means CTK is *NOT* build using Superbuild.
# In that specific case, CTK_SUPERBUILD_BINARY_DIR should default to CTK_BINARY_DIR
if(NOT DEFINED CTK_SUPERBUILD_BINARY_DIR)
  set(CTK_SUPERBUILD_BINARY_DIR ${CTK_BINARY_DIR})
endif()

#-----------------------------------------------------------------------------
# Configure files with settings
#
configure_file(${CTK_SOURCE_DIR}/CMake/UseCTK.cmake.in
               ${CTK_SUPERBUILD_BINARY_DIR}/UseCTK.cmake COPYONLY)

install(
  FILES ${CTK_SUPERBUILD_BINARY_DIR}/UseCTK.cmake
  DESTINATION ${CTK_INSTALL_CMAKE_DIR} COMPONENT Development
  )

set(CTK_CONFIG_H_INCLUDE_DIR ${CTK_BINARY_DIR})

#-----------------------------------------------------------------------------
# Set C/CXX Flags
#
set(CMAKE_CXX_FLAGS ${CTK_CXX_FLAGS} CACHE STRING "CMake C Flags" FORCE)
set(CMAKE_C_FLAGS ${CTK_C_FLAGS} CACHE STRING "CMake CXX Flags" FORCE)

set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS_INIT} ${CTK_EXE_LINKER_FLAGS}" CACHE STRING "Flags used when linking executables" FORCE)

#-----------------------------------------------------------------------------
# Set the header template which defines custom export/import macros
# for shared libraries
#
set(CTK_EXPORT_HEADER_TEMPLATE "${CTK_SOURCE_DIR}/Libs/ctkExport.h.in")

#-----------------------------------------------------------------------------
# Add CTK library subdirectories
#
foreach(lib ${CTK_LIBS})
  if(CTK_LIB_${lib})
    add_subdirectory(Libs/${lib})
  endif()
  # Always add the Documentation sub-directory for additional processing
  if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/Libs/${lib}/Documentation/CMakeLists.txt)
    add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/Libs/${lib}/Documentation)
  endif()
endforeach()

# Add the CommandLineModules root directory for additional processing
add_subdirectory(Libs/CommandLineModules)

#-----------------------------------------------------------------------------
# Add CTK plugin subdirectories
#
foreach(plugin ${CTK_PLUGINS})
  if(CTK_PLUGIN_${plugin})
    if(${plugin}_SOURCE_DIR)
      add_subdirectory(${${plugin}_SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR}/Plugins/${plugin})
    else()
      add_subdirectory(Plugins/${plugin})
    endif()
  endif()
endforeach()

#-----------------------------------------------------------------------------
# Add CTK application subdirectories
#
foreach(app ${CTK_APPS})
  IF (CTK_APP_${app})
    add_subdirectory(Applications/${app})
  endif()
endforeach()

#if(BUILD_TESTING)
#  add_subdirectory(Applications/Testing)
#endif()


#-----------------------------------------------------------------------------
# Add general purpose subdirectories
#
#add_subdirectory(Testing)
#add_subdirectory(Examples)


#-----------------------------------------------------------------------------
# Style Checking configuration
#
include(Utilities/KWStyle/KWStyle.cmake)

#---------------------------------------------------------------------------
# Documentation
#
#add_subdirectory( Documentation )

# Fix an error triggered by MITK configuration.
if(EXISTS ${DGraph_EXECUTABLE})
  message("DGraph binary found and compiled successfully.")
  set(CTK_DGRAPH_EXECUTABLE ${DGraph_EXECUTABLE})
endif()

set(MITK_USE_CTK ON)

if(MITK_USE_BLUEBERRY)
  include("${CMAKE_CURRENT_SOURCE_DIR}/PluginsBlueBerry/PluginList.cmake")
  # Temporary commenting the white listing.
  #mitkFunctionWhitelistPlugins(MITK MITK_PLUGINS)

  set(mitk_plugins_fullpath "")
  foreach(mitk_plugin ${MITK_PLUGINS})
    list(APPEND mitk_plugins_fullpath PluginsBlueBerry/${mitk_plugin})
  endforeach()

  set(MITK_PLUGIN_REGEX_LIST "")
  foreach(MITK_EXTENSION_DIR ${MITK_ABSOLUTE_EXTENSION_DIRS})
    set(MITK_PLUGINS_EXTENSION_DIR "${MITK_EXTENSION_DIR}/PluginsBlueBerry")
    if(EXISTS "${MITK_PLUGINS_EXTENSION_DIR}/PluginList.cmake")
      set(MITK_PLUGINS "")
      include("${MITK_PLUGINS_EXTENSION_DIR}/PluginList.cmake")
      foreach(mitk_plugin ${MITK_PLUGINS})
        list(APPEND mitk_plugins_fullpath "${MITK_PLUGINS_EXTENSION_DIR}/${mitk_plugin}")
      endforeach()
    endif()
  endforeach()

  if(EXISTS ${MITK_PRIVATE_MODULES}/PluginList.cmake)
    include(${MITK_PRIVATE_MODULES}/PluginList.cmake)

    foreach(mitk_plugin ${MITK_PRIVATE_PLUGINS})
      list(APPEND mitk_plugins_fullpath ${MITK_PRIVATE_MODULES}/${mitk_plugin})
    endforeach()
  endif()

  # Commented because this part of MITK is not imported here.
  #[[
  if(MITK_BUILD_EXAMPLES)
    include("${CMAKE_CURRENT_SOURCE_DIR}/Examples/Plugins/PluginList.cmake")
    set(mitk_example_plugins_fullpath )
    foreach(mitk_example_plugin ${MITK_EXAMPLE_PLUGINS})
      list(APPEND mitk_example_plugins_fullpath Examples/Plugins/${mitk_example_plugin})
      list(APPEND mitk_plugins_fullpath Examples/Plugins/${mitk_example_plugin})
    endforeach()
  endif()
  ]]

  # Specify which plug-ins belong to this project
  macro(GetMyTargetLibraries all_target_libraries varname)
    set(re_ctkplugin_mitk "^org_mitk_[a-zA-Z0-9_]+$")
    set(re_ctkplugin_bb "^org_blueberry_[a-zA-Z0-9_]+$")
    set(_tmp_list)
    list(APPEND _tmp_list ${all_target_libraries})
    ctkMacroListFilter(_tmp_list re_ctkplugin_mitk re_ctkplugin_bb MITK_PLUGIN_REGEX_LIST OUTPUT_VARIABLE ${varname})
  endmacro()

  # Get infos about application directories and build options
  set(mitk_apps_fullpath "")
  foreach(MITK_EXTENSION_DIR ${MITK_DIR_PLUS_EXTENSION_DIRS})
    set(MITK_APPLICATIONS_EXTENSION_DIR "${MITK_EXTENSION_DIR}/Applications")
    if(EXISTS "${MITK_APPLICATIONS_EXTENSION_DIR}/AppList.cmake")
      set(MITK_APPS "")
      include("${MITK_APPLICATIONS_EXTENSION_DIR}/AppList.cmake")
      foreach(mitk_app ${MITK_APPS})
        # extract option_name
        string(REPLACE "^^" "\\;" target_info ${mitk_app})
        set(target_info_list ${target_info})
        list(GET target_info_list 0 directory_name)
        list(GET target_info_list 1 option_name)
        if(${option_name})
          list(APPEND mitk_apps_fullpath "${MITK_APPLICATIONS_EXTENSION_DIR}/${directory_name}^^${option_name}")
        endif()
      endforeach()
    endif()
  endforeach()

  #message("mitk_plugins_fullpath = ${mitk_plugins_fullpath}")
  #message("mitk_apps_fullpath = ${mitk_apps_fullpath}")
  #message("MITK_BUILD_ALL_PLUGINS = ${MITK_BUILD_ALL_PLUGINS}")
  #message("CTK_DGRAPH_EXECUTABLE = ${CTK_DGRAPH_EXECUTABLE}")
  if (mitk_plugins_fullpath)
    
    ctkMacroSetupPlugins(${mitk_plugins_fullpath}
                         BUILD_OPTION_PREFIX MITK_BUILD_
                         APPS ${mitk_apps_fullpath}
                         BUILD_ALL ${MITK_BUILD_ALL_PLUGINS}
                         COMPACT_OPTIONS)
                         #[[]]
  endif()

  # Commenting and changing for CTK.
  #set(MITK_PLUGIN_USE_FILE "${MITK_BINARY_DIR}/MitkPluginUseFile.cmake")
  set(MITK_PLUGIN_USE_FILE "${CTK_BINARY_DIR}/MitkPluginUseFile.cmake")
  if(${PROJECT_NAME}_PLUGIN_LIBRARIES)
    ctkFunctionGeneratePluginUseFile(${MITK_PLUGIN_USE_FILE})
  else()
    file(REMOVE ${MITK_PLUGIN_USE_FILE})
    set(MITK_PLUGIN_USE_FILE )
  endif()
endif()

#-----------------------------------------------------------------------------
# The commands in this directory are intended to be executed as
# the end of the whole configuration process, as a "last step".
# This directory is typically the last SUBDIRS in the main CMakeLists.txt.
add_subdirectory(CMake/LastConfigureStep)