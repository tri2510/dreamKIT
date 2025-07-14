cmake_minimum_required(VERSION 3.16)

project(dk_manager VERSION 1.0 LANGUAGES CXX)

# Ensure C++11 standard is used
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add permissive flag
set(CMAKE_CXX_FLAGS "${CMAKE_CXX_FLAGS} -fpermissive")

# Enable automatic generation of moc files
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

# Find Qt6 components
find_package(Qt6 6.2 REQUIRED COMPONENTS Core Network)

# Or directly add include directories and libraries
include_directories("/app/socket.io-client-cpp/install/include")
link_directories("/app/socket.io-client-cpp/install/lib")

# Include directories for Qt and other dependencies
include_directories(${Qt6Core_INCLUDE_DIRS} ${Qt6Network_INCLUDE_DIRS})

# Define preprocessor definitions
add_definitions(-DQT_NO_KEYWORDS)
add_definitions(-DDREAMKIT_MINI)
add_definitions(-DQT_DEPRECATED_WARNINGS)
# Uncomment the following line if you need to disable deprecated APIs before a certain version
# add_definitions(-DQT_DISABLE_DEPRECATED_BEFORE=0x060000)

# Source files
set(SOURCES
    common_utils.cpp
    dapr_utils.cpp
    dkmanager.cpp
    fileutils.cpp
    message_to_kit_handler.cpp
    prototype_utils.cpp
    vcuorchestrator.cpp
    main.cpp
)

# Header files (for clarity, listing them here)
set(HEADERS
    common_utils.h
    dapr_utils.h
    dkmanager.h
    fileutils.h
    message_to_kit_handler.h
    prototype_utils.h
)

# Add executable
qt_add_executable(dk_manager
    ${SOURCES}
    ${HEADERS}  # Ensure moc processes headers with Q_OBJECT macros
)

# Link required libraries
target_link_libraries(dk_manager
    PRIVATE Qt6::Core Qt6::Network
    PRIVATE sioclient_tls ssl crypto
)

# Installation rules
install(TARGETS dk_manager
    RUNTIME DESTINATION /opt/${PROJECT_NAME}/bin
)

# Set target properties (optional, depending on the platform)
if(APPLE)
    set_target_properties(dk_manager PROPERTIES
        MACOSX_BUNDLE_GUI_IDENTIFIER my.example.com
        MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
        MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
        MACOSX_BUNDLE TRUE
    )
elseif(WIN32)
    set_target_properties(dk_manager PROPERTIES
        WIN32_EXECUTABLE TRUE
    )
endif()
