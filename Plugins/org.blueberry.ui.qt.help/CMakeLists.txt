project(org_blueberry_ui_qt_help)

set(QT_USE_QTHELP 1)
set(QT_USE_QTWEBKIT 1)
set(QT_USE_QTNETWORK 1)

find_package(Qt5 COMPONENTS REQUIRED Core
  Network
  Help
  OpenGL
  PrintSupport
  WebEngineCore
  WebEngineWidgets 
  WebEngine
  WebView
  Widgets
  Xml
  )

find_package(mbilog REQUIRED)

set(QT_USE_QTHELP 1)
set(QT_USE_QTWEBENGINE 1)
set(QT_USE_QTNETWORK 1)

set(PLUGIN_export_directive "org_blueberry_ui_qt_help_EXPORT")

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
${QRC_FILES}
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
    src
)

target_link_libraries(${PROJECT_NAME} PUBLIC
  mbilog
  Qt5::Core
  Qt5::Network
  Qt5::Help
  Qt5::OpenGL
  Qt5::PrintSupport
  Qt5::WebEngineCore
  Qt5::WebEngineWidgets 
  Qt5::WebEngine
  Qt5::WebView
  Qt5::Widgets
  Qt5::Xml
  )