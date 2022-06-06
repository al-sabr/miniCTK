project(org_blueberry_ui_qt_log)

find_package(Qt5 COMPONENTS REQUIRED Core Widgets)
find_package(mbilog)

set(PLUGIN_export_directive "org_blueberry_ui_qt_log_EXPORT")

include(files.cmake)

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
    src
)

target_link_libraries(${PROJECT_NAME} PUBLIC
  Qt5::Core
  Qt5::Widgets
  mbilog
  )