project(CTKWidgets)

include(files.cmake)
#
# See CTK/CMake/ctkMacroBuildLib.cmake for details
#

set(KIT_export_directive "CTK_WIDGETS_EXPORT")

# add local include directory for FreeBSD
# (QtOpengl can't find GL/gl.h)
# actual bug: https://bugs.freebsd.org/bugzilla/show_bug.cgi?id=195105
if(CMAKE_SYSTEM_NAME STREQUAL FreeBSD)
  include_directories("/usr/local/include")
endif()

#
# Add the libraries QtTesting
#
if(CTK_USE_QTTESTING)
  find_package(QtTesting REQUIRED)
  include_directories(
    ${QtTesting_INCLUDE_DIRS}
    ${CMAKE_BINARY_DIR} # For ctkConfig.h
    )
endif()

# Target libraries - See CMake/ctkFunctionGetTargetLibraries.cmake
# The following macro will read the target libraries from the file 'target_libraries.cmake'
ctkFunctionGetTargetLibraries(KIT_target_libraries)

if(CTK_QT_VERSION VERSION_GREATER "4")
  list(APPEND KIT_target_libraries Qt5::Core Qt5::Widgets Qt5::Xml Qt5::OpenGL)
endif()

ctkMacroBuildLib(
  NAME ${PROJECT_NAME}
  EXPORT_DIRECTIVE ${KIT_export_directive}
  SRCS ${KIT_SRCS}
  MOC_SRCS ${KIT_MOC_SRCS}
  GENERATE_MOC_SRCS ${KIT_GENERATE_MOC_SRCS}
  UI_FORMS ${KIT_UI_FORMS}
  TARGET_LIBRARIES ${KIT_target_libraries}
  RESOURCES ${KIT_resources}
  LIBRARY_TYPE ${CTK_LIBRARY_MODE}
  )

if(CTK_WRAP_PYTHONQT_LIGHT)
  ctkMacroBuildLibWrapper(
    TARGET ${PROJECT_NAME}
    SRCS ${KIT_SRCS}
    WRAPPER_LIBRARY_TYPE ${CTK_LIBRARY_MODE}
    )
endif()

# Plugins
if(CTK_BUILD_QTDESIGNER_PLUGINS)
  add_subdirectory(Plugins)
endif()

# Testing
if(BUILD_TESTING)
  add_subdirectory(Testing)
endif()
