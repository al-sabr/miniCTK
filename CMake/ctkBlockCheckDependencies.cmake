
#
# Independently of the value of CTK_SUPERBUILD, each external project definition will
# provides either the include and library directories or a variable name
# used by the corresponding Find<package>.cmake files.
#
# Within top-level CMakeLists.txt file, the variable names will be expanded if not in
# superbuild mode. The include and library dirs are then used in
# ctkMacroBuildApp, ctkMacroBuildLib, and ctkMacroBuildPlugin
#

#-----------------------------------------------------------------------------
# Collect CTK library target dependencies
#

ctkMacroCollectAllTargetLibraries("${CTK_LIBS}" "Libs" ALL_TARGET_LIBRARIES)
ctkMacroCollectAllTargetLibraries("${CTK_PLUGINS}" "Plugins" ALL_TARGET_LIBRARIES)
ctkMacroCollectAllTargetLibraries("${CTK_APPS}" "Applications" ALL_TARGET_LIBRARIES)
#message(STATUS ALL_TARGET_LIBRARIES:${ALL_TARGET_LIBRARIES})

#-----------------------------------------------------------------------------
# Initialize NON_CTK_DEPENDENCIES variable
#
# Using the variable ALL_TARGET_LIBRARIES initialized above with the help
# of the macro ctkMacroCollectAllTargetLibraries, let's get the list of all Non-CTK dependencies.
# NON_CTK_DEPENDENCIES is expected by the macro ctkMacroShouldAddExternalProject
ctkMacroGetAllNonProjectTargetLibraries("${ALL_TARGET_LIBRARIES}" NON_CTK_DEPENDENCIES)
#message(NON_CTK_DEPENDENCIES:${NON_CTK_DEPENDENCIES})

#-----------------------------------------------------------------------------
# Enable and setup External project global properties
#

if(CTK_SUPERBUILD)
  set(ep_install_dir ${CMAKE_BINARY_DIR}/CMakeExternals/Install)
  set(ep_suffix      "-cmake")

  set(ep_common_c_flags "${CMAKE_C_FLAGS_INIT} ${ADDITIONAL_C_FLAGS}")
  set(ep_common_cxx_flags "${CMAKE_CXX_FLAGS_INIT} ${ADDITIONAL_CXX_FLAGS}")

  set(ep_cxx_standard_arg)
  if(CMAKE_CXX_STANDARD)
    set(ep_cxx_standard_arg "-DCMAKE_CXX_STANDARD:STRING=${CMAKE_CXX_STANDARD}")
  endif()

  set(ep_common_cache_args
      -DCMAKE_BUILD_TYPE:STRING=${CMAKE_BUILD_TYPE}
      -DCMAKE_C_COMPILER:FILEPATH=${CMAKE_C_COMPILER}
      -DCMAKE_CXX_COMPILER:FILEPATH=${CMAKE_CXX_COMPILER}
      -DCMAKE_C_FLAGS:STRING=${ep_common_c_flags}
      -DCMAKE_CXX_FLAGS:STRING=${ep_common_cxx_flags}
      -DCMAKE_INSTALL_PREFIX:PATH=${ep_install_dir}
      -DCMAKE_PREFIX_PATH:STRING=${CMAKE_PREFIX_PATH}
      -DBUILD_TESTING:BOOL=OFF
      -DCMAKE_MACOSX_RPATH:BOOL=${CMAKE_MACOSX_RPATH}
      ${ep_cxx_standard_arg}
     )
endif()

if(NOT DEFINED CTK_DEPENDENCIES)
  message(FATAL_ERROR "error: CTK_DEPENDENCIES variable is not defined !")
endif()

set(Log4Qt_enabling_variable Log4Qt_LIBRARIES)
set(${Log4Qt_enabling_variable}_INCLUDE_DIRS Log4Qt_INCLUDE_DIRS)
set(${Log4Qt_enabling_variable}_FIND_PACKAGE_CMD Log4Qt)

set(QtTesting_enabling_variable QtTesting_LIBRARIES)
set(${QtTesting_enabling_variable}_INCLUDE_DIRS QtTesting_INCLUDE_DIRS)
set(${QtTesting_enabling_variable}_FIND_PACKAGE_CMD QtTesting)

set(ZMQ_enabling_variable ZMQ_LIBRARIES)
set(${ZMQ_enabling_variable}_LIBRARY_DIRS ZMQ_LIBRARY_DIRS)
set(${ZMQ_enabling_variable}_INCLUDE_DIRS ZMQ_INCLUDE_DIRS)
set(${ZMQ_enabling_variable}_FIND_PACKAGE_CMD ZMQ)

set(mbilog_enabling_variable mbilog_LIBRARIES)
set(${mbilog_enabling_variable}_LIBRARY_DIRS mbilog_LIBRARY_DIRS)
set(${mbilog_enabling_variable}_INCLUDE_DIRS mbilog_INCLUDE_DIRS)
set(${mbilog_enabling_variable}_FIND_PACKAGE_CMD mbilog)

set(itkCommon_enabling_variable itkCommon_LIBRARIES)
set(${itkCommon_enabling_variable}_LIBRARY_DIRS itkCommon_LIBRARY_DIRS)
set(${itkCommon_enabling_variable}_INCLUDE_DIRS itkCommon_INCLUDE_DIRS)
set(${itkCommon_enabling_variable}_FIND_PACKAGE_CMD itkCommon)

set(qtsingleapplication_enabling_variable qtsingleapplication_LIBRARIES)
set(${qtsingleapplication_enabling_variable}_LIBRARY_DIRS qtsingleapplication_LIBRARY_DIRS)
set(${qtsingleapplication_enabling_variable}_INCLUDE_DIRS qtsingleapplication_INCLUDE_DIRS)
set(${qtsingleapplication_enabling_variable}_FIND_PACKAGE_CMD qtsingleapplication)

set(mitkCore_enabling_variable mitkCore_LIBRARIES)
set(${mitkCore_enabling_variable}_LIBRARY_DIRS mitkCore_LIBRARY_DIRS)
set(${mitkCore_enabling_variable}_INCLUDE_DIRS mitkCore_INCLUDE_DIRS)
set(${mitkCore_enabling_variable}_FIND_PACKAGE_CMD mitkCore)

set(CppMicroServices_enabling_variable CppMicroServices_LIBRARIES)
set(${CppMicroServices_enabling_variable}_LIBRARY_DIRS CppMicroServices_LIBRARY_DIRS)
set(${CppMicroServices_enabling_variable}_INCLUDE_DIRS CppMicroServices_INCLUDE_DIRS)
set(${CppMicroServices_enabling_variable}_FIND_PACKAGE_CMD CppMicroServices)

macro(superbuild_is_external_project_includable possible_proj output_var)
  if(DEFINED ${possible_proj}_enabling_variable)
    ctkMacroShouldAddExternalProject(${${possible_proj}_enabling_variable} ${output_var})
    if(NOT ${${output_var}})
      if(${possible_proj} STREQUAL "VTK"
         AND CTK_LIB_Scripting/Python/Core_PYTHONQT_USE_VTK)
        set(${output_var} 1)
      else()
        unset(${${possible_proj}_enabling_variable}_INCLUDE_DIRS)
        unset(${${possible_proj}_enabling_variable}_LIBRARY_DIRS)
        unset(${${possible_proj}_enabling_variable}_FIND_PACKAGE_CMD)
      endif()
    endif()
  else()
    set(${output_var} 1)
  endif()
endmacro()

set(proj CTK)
ExternalProject_Include_Dependencies(CTK
  PROJECT_VAR proj
  DEPENDS_VAR CTK_DEPENDENCIES
  USE_SYSTEM_VAR ${CMAKE_PROJECT_NAME}_USE_SYSTEM_${proj}
  )

#message("Updated CTK_DEPENDENCIES:")
#foreach(dep ${CTK_DEPENDENCIES})
#  message("  ${dep}")
#endforeach()
