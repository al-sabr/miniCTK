# See CMake/ctkFunctionGetTargetLibraries.cmake
#
# This file should list the libraries required to build the current CTK plugin.
# For specifying required plugins, see the manifest_headers.cmake file.
#

set(target_libraries
  CTKWidgets
  org_blueberry_ui_qt
  mbilog
)

if(Qt5_DIR)
  list(APPEND target_libraries
  Qt5::Core
  Qt5::Network
  Qt5::Help
  Qt5::OpenGL
  Qt5::PrintSupport
  Qt5::WebEngineCore
  Qt5::WebEngineWidgets 
  Qt5::WebEngine
  Qt5::Widgets
  Qt5::Xml)
endif()