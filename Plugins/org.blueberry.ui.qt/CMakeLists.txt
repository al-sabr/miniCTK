project(org_blueberry_ui_qt)

#set(CMAKE_AUTOMOC ON)
find_package(Qt5 COMPONENTS Core Widgets PrintSupport Svg)
find_package(mbilog REQUIRED)

set(PLUGIN_exported_include_suffixes
  src
  src/actions
  src/application
  src/commands
  src/guitk
  src/handlers
  src/intro
  src/model
  src/presentations
  src/services
  src/testing
  src/tweaklets
  src/util
)

set(PLUGIN_export_directive "BERRY_UI_QT")

include(files.cmake)

set(PLUGIN_SRCS
  ${CPP_FILES}
  )

# Files which should be processed by Qts moc
set(PLUGIN_MOC_SRCS
  ${MOC_H_FILES}
  )

# Qt Designer files which should be processed by Qts uic
set(PLUGIN_UI_FORMS
  ${UI_FILES}
)

# QRC Files which should be compiled into the plugin
set(PLUGIN_resources
)

set(PLUGIN_CACHED_RESOURCEFILES
  ${CACHED_RESOURCE_FILES}
)

ctkFunctionGetTargetLibraries(PLUGIN_target_libraries)

ctkMacroBuildPlugin(
  NAME ${PROJECT_NAME}
  EXPORT_DIRECTIVE ${PLUGIN_export_directive}
  SRCS ${PLUGIN_SRCS}
  MOC_SRCS ${PLUGIN_MOC_SRCS}
  UI_FORMS ${PLUGIN_UI_FORMS}
  RESOURCES ${PLUGIN_resources}
  TARGET_LIBRARIES ${PLUGIN_target_libraries}
  CACHED_RESOURCEFILES ${PLUGIN_CACHED_RESOURCEFILES}
  EXPORTED_INCLUDE_SUFFIXES
  ${PLUGIN_exported_include_suffixes}
)

target_link_libraries(${PROJECT_NAME} PRIVATE  Qt5::Core Qt5::Widgets Qt5::Svg Qt5::PrintSupport mbilog)