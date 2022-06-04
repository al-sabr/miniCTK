project(org_blueberry_core_runtime)

set(CMAKE_AUTOMOC ON)

include(files.cmake)

set(QT_USE_QTXML 1)

find_package(Qt5 COMPONENTS Core Gui Widgets Xml)
find_package(mbilog REQUIRED)

message("mbilog_INCLUDE_DIRS = ${mbilog_INCLUDE_DIRS}")

include_directories(
    src
    src/application
    src/dynamichelpers
    src/internal
    src/registry
    #${mbilog_INCLUDE_DIRS}
    )

message(STATUS "Blueberry include: ${CMAKE_BINARY_DIR}/CMakeExternals/Install/include")

set(PLUGIN_export_directive  "org_blueberry_core_runtime_EXPORT")

set(PLUGIN_SRCS
  ${CPP_FILES}
  )

# Files which should be processed by Qts moc
set(PLUGIN_MOC_SRCS
  ${MOC_H_FILES}
  )

# Qt Designer files which should be processed by Qts uic
set(PLUGIN_UI_FORMS
)

# QRC Files which should be compiled into the plugin
set(PLUGIN_resources
)

set(PLUGIN_CACHED_RESOURCEFILES
  ${CACHED_RESOURCE_FILES}
)

#Compute the plugin dependencies
ctkFunctionGetTargetLibraries(PLUGIN_target_libraries)

ctkMacroBuildPlugin(
  NAME ${PROJECT_NAME}
  EXPORT_DIRECTIVE ${PLUGIN_export_directive}
  SRCS ${PLUGIN_SRCS}
  MOC_SRCS ${PLUGIN_MOC_SRCS}
  UI_FORMS ${PLUGIN_UI_FORMS}
  RESOURCES ${PLUGIN_resources}
  CACHED_RESOURCEFILES ${PLUGIN_CACHED_RESOURCEFILES}
  TARGET_LIBRARIES ${PLUGIN_target_libraries}
  EXPORTED_INCLUDE_SUFFIXES
    src
    src/application
    src/dynamichelpers
    src/registry
)

configure_file("${CMAKE_CURRENT_SOURCE_DIR}/src/berryConfig.h.in" "${CMAKE_CURRENT_BINARY_DIR}/berryConfig.h" @ONLY)

target_link_libraries(${PROJECT_NAME} PRIVATE Qt5::Core Qt5::Gui Qt5::Widgets Qt5::Xml mbilog)