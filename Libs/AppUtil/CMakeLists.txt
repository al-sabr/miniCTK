project(CTKAppUtil)

#find_package(  CppMicroServices REQUIRED)
#find_package(  itkCommon REQUIRED)
#find_package(  qtsingleapplication  REQUIRED)
#find_package(  mitkCore  REQUIRED)

include (GenerateExportHeader)
include(FeatureSummary)

# Apply properties to the module target.
add_compile_definitions(${PROJECT_NAME}_EXPORTS)

#
# See CTK/CMake/ctkMacroBuildLib.cmake for details
#
include(files.cmake)

set(KIT_export_directive "MITKAPPUTIL_EXPORT")


# Source files
set(KIT_SRCS
    ${CPP_FILES}
  )

# Headers that should run through moc
set(KIT_MOC_SRCS
    ${H_FILES}
)

# UI files
set(KIT_UI_FORMS
)

# Resources
set(KIT_resources
)

# Target libraries - See CMake/ctkFunctionGetTargetLibraries.cmake
# The following macro will read the target libraries from the file 'target_libraries.cmake'
ctkFunctionGetTargetLibraries(KIT_target_libraries)

#if(CTK_QT_VERSION VERSION_GREATER "4")
#  list(APPEND KIT_target_libraries Qt5::Sql Qt5::Concurrent)
#endif()

ctkMacroBuildLib(
  NAME ${PROJECT_NAME}
  EXPORT_DIRECTIVE ${KIT_export_directive}
  INCLUDE_DIRECTORIES ${CTK_SUPERBUILD_BINARY_DIR}
  SRCS ${KIT_SRCS}
  MOC_SRCS ${KIT_MOC_SRCS}
  UI_FORMS ${KIT_UI_FORMS}
  TARGET_LIBRARIES ${KIT_target_libraries}
  RESOURCES ${KIT_resources}
  LIBRARY_TYPE ${CTK_LIBRARY_MODE}
  )

include_directories(include)
include_directories(${CMAKE_CURRENT_BINARY_DIR})
# Testing
if(BUILD_TESTING)
#  add_subdirectory(Testing)
endif()

generate_export_header(${PROJECT_NAME}
  EXPORT_MACRO_NAME MITKAPPUTIL_EXPORT
  EXPORT_FILE_NAME MitkAppUtilExports.h
  )

#target_link_libraries(${PROJECT_NAME} PUBLIC mitkCore qtsingleapplication )