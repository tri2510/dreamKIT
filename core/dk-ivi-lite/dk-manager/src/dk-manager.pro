QT -= gui
QT += core network

CONFIG += no_keywords
CONFIG += c++11 console
CONFIG -= app_bundle

# use this only if the target is dreamKIT (VCU + Zonecontroller)
#DEFINES += USING_DK_ORCHESTRATOR
DEFINES += DREAMKIT_MINI

# The following define makes your compiler emit warnings if you use
# any Qt feature that has been marked deprecated (the exact warnings
# depend on your compiler). Please consult the documentation of the
# deprecated API in order to know how to port your code away from it.
DEFINES += QT_DEPRECATED_WARNINGS

QMAKE_CXXFLAGS += -fpermissive

# You can also make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
# You can also select to disable deprecated APIs only up to a certain version of Qt.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

SOURCES += \
        common_utils.cpp \
        dapr_utils.cpp \
        dkmanager.cpp \
        fileutils.cpp \
        message_to_kit_handler.cpp \
        prototype_utils.cpp \
        vcuorchestrator.cpp \
        main.cpp

LIBS += -lsioclient_tls -lssl -lcrypto
#-lboost_random -lboost_system -lboost_date_time

# Default rules for deployment.
qnx: target.path = /tmp/$${TARGET}/bin
else: unix:!android: target.path = /opt/$${TARGET}/bin
!isEmpty(target.path): INSTALLS += target

HEADERS += \
    common_utils.h \
    dapr_utils.h \
    dkmanager.h \
    fileutils.h \
    message_to_kit_handler.h \
    prototype_utils.h
