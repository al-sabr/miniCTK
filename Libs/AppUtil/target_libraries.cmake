set(target_libraries
  #CppMicroServices
  #CppMicroServices_LIBRARIES
  #ITK_LIBRARIES
  CTKCore
  CTKPluginFramework
  #CTKmitkCore
  qtsingleapplication
  Poco::Util
  )

  
if(CTK_QT_VERSION VERSION_GREATER "4")
  list(APPEND target_libraries Qt5::Widgets Qt5::WebEngine)
  if(UNIX AND NOT APPLE)
    set(qt5_depends {qt5_depends} X11Extras)
    list(APPEND target_libraries qt5_depends)
  endif()
endif()

if (CTK_QT_VERSION VERSION_LESS "5")
  list(APPEND target_libraries QT_LIBRARIES)
endif()