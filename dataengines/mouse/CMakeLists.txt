include_directories( ${CMAKE_CURRENT_BINARY_DIR}/../../)

set(mouse_engine_SRCS
    mouseengine.cpp
)

if (HAVE_X11)
    set(mouse_engine_SRCS ${mouse_engine_SRCS} cursornotificationhandler.cpp)
endif ()

kcoreaddons_add_plugin(plasma_engine_mouse SOURCES ${mouse_engine_SRCS} INSTALL_NAMESPACE plasma/dataengine)
target_link_libraries(plasma_engine_mouse
    Qt::Widgets
    KF5::Plasma
    KF5::WindowSystem
)

if (HAVE_X11)
	target_link_libraries(plasma_engine_mouse Qt::X11Extras X11::X11 X11::Xfixes)
endif ()

kcoreaddons_desktop_to_json(plasma_engine_mouse plasma-dataengine-mouse.desktop)
