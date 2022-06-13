
# Plug-ins must be ordered according to their dependencies

set(MITK_PLUGINS
  org.blueberry.core.runtime:ON
  org.blueberry.core.expressions:OFF
  org.blueberry.core.commands:OFF
  org.blueberry.core.jobs:OFF
  org.blueberry.ui.qt:OFF
  org.blueberry.ui.qt.help:ON
  org.blueberry.ui.qt.log:ON
  org.blueberry.ui.qt.objectinspector:OFF
)
