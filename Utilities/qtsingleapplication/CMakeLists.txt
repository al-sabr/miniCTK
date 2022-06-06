project(qtsingleapplication)

include(files.cmake)

find_package(Qt5 COMPONENTS Core Widgets Network REQUIRED)
#
# See CTK/CMake/ctkMacroBuildLib.cmake for details
#

set(KIT_export_directive "QTSINGLEAPPLICATION_EXPORT")
include(CMakePackageConfigHelpers)

write_basic_package_version_file(
    ${PROJECT_NAME}ConfigVersion.cmake
    VERSION "1.0.0"
    COMPATIBILITY AnyNewerVersion
    )

include(files.cmake)

include (GenerateExportHeader)
include(FeatureSummary)

# Apply properties to the module target.
add_compile_definitions(${PROJECT_NAME}_EXPORTS)

add_library(${PROJECT_NAME} STATIC ${CPP_FILES} ${H_FILES})

include_directories(${CMAKE_CURRENT_SOURCE_DIR})

target_include_directories(${PROJECT_NAME} PUBLIC 
$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR}>
$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/${CMAKE_INSTALL_INCLUDEDIR}>)

generate_export_header(${PROJECT_NAME}
  EXPORT_MACRO_NAME ${KIT_export_directive}
  EXPORT_FILE_NAME ${PROJECT_NAME}Exports.h
  )

export(TARGETS ${PROJECT_NAME} FILE "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Targets.cmake")

target_link_libraries(${PROJECT_NAME} PRIVATE Qt5::Core Qt5::Widgets Qt5::Network)