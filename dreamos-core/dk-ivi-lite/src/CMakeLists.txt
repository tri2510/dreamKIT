cmake_minimum_required(VERSION 3.16)

project(untitled2 VERSION 0.1 LANGUAGES CXX)

# Find Python3
find_package(Python3 COMPONENTS Interpreter Development REQUIRED)

set(ENV{DK_USER} "htr1hc")
set(ENV{DK_ARCH} "amd64")
set(ENV{DK_DOCKER_HUB_NAMESPACE} "")

# Include directories
include_directories(${Python3_INCLUDE_DIRS})

set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(CMAKE_CXX_FLAGS "-fpermissive")

find_package(Qt6 6.2 REQUIRED COMPONENTS Quick)


qt_add_executable(dk_ivi
    main.cpp 
    digitalauto/digitalauto.cpp
    aiassist/aiassist.cpp
    marketplace/marketplace.cpp
    marketplace/fetching.cpp
    installedservices/installedservices.cpp
    installedservices/unsafeparamcheck.cpp
    installedvapps/installedvapps.cpp
)

qt_add_qml_module(dk_ivi
    URI untitled2
    VERSION 1.0
    QML_FILES 
        Main.qml
        digitalauto.qml
        aiassist.qml
        marketplace.qml
        installedservices.qml
        installedvapps.qml
        controls/CustomBtn1.qml
        controls/ImgOverlay.qml
    RESOURCES
        icons/search.png
        icons/cloud-download-alt.png
        resource/trashbin2.png
        resource/editicon3.png
        resource/bot.png
        resource/bgswlogo.png
        resource/logo2.png
        resource/logo3.png
        resource/logo4.png
)

set_target_properties(dk_ivi PROPERTIES
    MACOSX_BUNDLE_GUI_IDENTIFIER my.example.com
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

target_link_libraries(dk_ivi
    PRIVATE Qt6::Quick 
    ${Python3_LIBRARIES}
)

install(TARGETS dk_ivi
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
