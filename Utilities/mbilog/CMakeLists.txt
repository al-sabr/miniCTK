project(mbilog)

option(MBILOG_ENABLE_DEBUG_MESSAGES "Enable extra debug log output" ON)
mark_as_advanced(MBILOG_ENABLE_DEBUG_MESSAGES)

if(MBILOG_ENABLE_DEBUG_MESSAGES)
  set(_define_enable_debug "#define MBILOG_ENABLE_DEBUG")
endif(MBILOG_ENABLE_DEBUG_MESSAGES)

include(CMakePackageConfigHelpers)

write_basic_package_version_file(
    ${PROJECT_NAME}ConfigVersion.cmake
    VERSION "1.0.0"
    COMPATIBILITY AnyNewerVersion
    )

configure_file("${CMAKE_CURRENT_SOURCE_DIR}/mbilogConfig.cmake.in"
"${CMAKE_CURRENT_BINARY_DIR}/mbilogConfig.cmake" @ONLY)

configure_file("${CMAKE_CURRENT_SOURCE_DIR}/mbilogConfig.h.in"
"${CMAKE_CURRENT_BINARY_DIR}/mbilogConfig.h" @ONLY)

include(files.cmake)

include (GenerateExportHeader)
include(FeatureSummary)

# Apply properties to the module target.
add_compile_definitions(${PROJECT_NAME}_EXPORTS)

include_directories(${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR})

#target_include_directories(${PROJECT_NAME} PUBLIC "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR} ${CMAKE_CURRENT_BINARY_DIR}>"
#                                                         "$<INSTALL_INTERFACE:$<INSTALL_PREFIX>/${CMAKE_INSTALL_INCLUDEDIR}>")

#include_directories(${CMAKE_CURRENT_BINARY_DIR})

add_library(${PROJECT_NAME} STATIC ${CPP_FILES} ${H_FILES})

generate_export_header(${PROJECT_NAME}
  EXPORT_MACRO_NAME MBILOG_EXPORT
  EXPORT_FILE_NAME ${PROJECT_NAME}Exports.h
  )

export(TARGETS ${PROJECT_NAME} NAMESPACE ${PROJECT_NAME}:: FILE "${PROJECT_BINARY_DIR}/${PROJECT_NAME}Targets.cmake")

install(TARGETS ${PROJECT_NAME}
        EXPORT ${PROJECT_NAME}Targets
        LIBRARY DESTINATION lib
        ARCHIVE DESTINATION lib
        RUNTIME DESTINATION bin
        INCLUDES DESTINATION include
        )

install(FILES "${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}Config.cmake"
"${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME}ConfigVersion.cmake"
  DESTINATION lib/cmake/${PROJECT_NAME}
  )