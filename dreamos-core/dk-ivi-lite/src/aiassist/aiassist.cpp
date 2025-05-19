#define USING_VSS

#ifdef USING_VSS
#pragma push_macro("slots")
#undef slots
#include <Python.h>
#pragma pop_macro("slots")
// Python global object
PyObject *pFunc;
PyObject *pName;
PyObject *pModule;
bool isPyEnvOk = false;
#endif

#include <stdio.h>
#include <stdlib.h>
#include <signal.h>
#include <QFile>
#include <QStringList>
#include <QDebug>
#include <QThread>
#include <QMutex>
#include <QFileInfo>

#include <QJsonDocument>
#include <QJsonValue>
#include <QJsonArray>
#include <QJsonObject>

#include "aiassist.hpp"
#include <iostream>
#include <string>



void initPyEnv()
{
#ifdef USING_VSS
    // Initialize the Python Interpreter
    Py_Initialize();

    // Set the Python script's directory (optional)
    PyRun_SimpleString("import sys");
    PyRun_SimpleString("sys.path.append(\".\")"); // Add the current directory to the Python path

    // Load the script
    pName = PyUnicode_DecodeFSDefault("vssclient");
    if(!pName) {
        isPyEnvOk = false;
        return;
    }

    pModule = PyImport_Import(pName);
    if(!pModule) {
        isPyEnvOk = false;
        return;
    }

    pFunc = PyObject_GetAttrString(pModule, "getCurrentValue");
    if(!pFunc) {
        isPyEnvOk = false;
        return;
    }
    
    isPyEnvOk= true;
#endif
}

void endPyEnv()
{
#ifdef USING_VSS
    Py_Finalize();
#endif
}

VssThread::VssThread(AiassistAsync *parent)
{
    m_parent = parent;
}

void VssThread::run()
{    
    QString oldTimeStamp;
    QString oldTtsText;
    bool oldIsAttackedSts = false;
    int oldVehicleReact = 0;

    initPyEnv();

    #ifdef USING_VSS
    if(!isPyEnvOk) {
        //////qDebug() << "Python Environment Setup is failed. This IVI shall not get access to VSS data.\n \
        Below could be the issues:\n \
        1. Python dev lib is missing.\n \
        2. Missing vssclient.py. Let's copy from retrofitivi/vss/vssclient.py to build folder.";
        return;
    }
    #endif
    
    while(1) {
        ////////qDebug() << "VssThread::run";
        QString ttsText;
        QString currentTimeStamp="";

        ttsText = getString_VssApiValue("Vehicle.TextToSpeech", currentTimeStamp);
        if (ttsText != "nullstring") {
            if (currentTimeStamp != oldTimeStamp) {
                m_parent->setTextToSpeech(ttsText);
                oldTimeStamp = currentTimeStamp;
                oldTtsText = ttsText;
            }            
        }
        
        // for security
        // check is attacked
        currentTimeStamp="";
        bool isAttacked = getBool_VssApiValue("Vehicle.Security.isAttacked", currentTimeStamp);
        if (currentTimeStamp == "") {
            //////qDebug() << "Vehicle.Security.isAttacked is not set";
        }
        else {
            if (isAttacked != oldIsAttackedSts) {
                // only show the widget when isAttacked gets changed.
                // play the sound                
                if(isAttacked) {
                    QString cmd = "";
                    cmd += "dapr run --app-id sec_car_under_attack_alarm -- mpg123 --gain 10 -l 0 /usr/bin/dreamkit/retrofitivi/resource/sec_under_attack.mp3 &";
                    system(cmd.toUtf8());
                }
                else {
                    system("dapr stop sec_car_under_attack_alarm");
                }
                m_parent->setSecurityIsAttacked(isAttacked);
            }
            oldIsAttackedSts = isAttacked;
        }

        if (isAttacked) {
            // check security reaction stage
            currentTimeStamp="";
            u_int32_t secReact = getUint32_VssApiValue("Vehicle.Security.IDPS.VehicleReaction", currentTimeStamp);
            if (currentTimeStamp == "") {
                //////qDebug() << "Vehicle.Security.IDPS.VehicleReaction is not set";
            }
            else {
                if (oldVehicleReact != secReact) {
                    if (secReact == 2) {
                        system("dapr stop sec_car_under_attack_alarm");
                        QString cmd = "";                    
                        cmd += "mpg123 --gain 30 /usr/bin/dreamkit/retrofitivi/resource/sec_car_is_secure.mp3 &";
                        system(cmd.toUtf8());
                    }
                    oldVehicleReact = secReact;
                }                
                m_parent->setSecurityReactionStage(secReact);
            }
        }

        QThread::msleep(300);
    }
}

bool VssThread::getBool_VssApiValue(QString apiName, QString &currentTimeStamp)
{
#ifdef USING_VSS
    if (pModule != nullptr) {

        // Check if the function is callable
        if (PyCallable_Check(pFunc)) {

            // Prepare the arguments for the function call
            PyObject *pArgs = PyTuple_Pack(1, PyUnicode_FromString(apiName.toStdString().c_str()));

            // Call the function
            PyObject *pValue = PyObject_CallObject(pFunc, pArgs);            
            Py_DECREF(pArgs);
            // Check if the result is a tuple
            if (!pValue) return false;
            if (PyTuple_Check(pValue)) {
                PyObject *pVal = PyTuple_GetItem(pValue, 0);
                PyObject *pTime = PyTuple_GetItem(pValue, 1);
                // //////qDebug() << "PyTuple_Check True";

                if (pVal && pTime) {
                    bool result = PyObject_IsTrue(pVal);
                    const char *timestampCStr = PyUnicode_AsUTF8(pTime);

                    if (timestampCStr) {
                        std::string timestamp = timestampCStr;
                        currentTimeStamp = QString::fromStdString(timestamp);
                        Py_DECREF(pValue);
                        // return std::make_tuple(QString::fromStdString(result), QString::fromStdString(timestamp));
                        return result;
                    }
                 }
            }
            else {
                // //////qDebug() << "PyTuple_Check False";
                if (pValue != nullptr) {
                    if (currentTimeStamp == "") 
                        return false;
                    // Convert the result to a C++ string
                    bool result = PyObject_IsTrue(pValue);
                    Py_DECREF(pValue);
                    return result;
                } else {
                    PyErr_Print();
                    std::cerr << "Call to get_tts_text failed" << std::endl;
                }
            }            
        } else {
            if (PyErr_Occurred()) PyErr_Print();
            std::cerr << "Cannot find function 'get_tts_text'" << std::endl;
        }        
    } else {
        PyErr_Print();
        std::cerr << "Failed to load 'vssclient'" << std::endl;
    } 
#endif
    return false;
}

u_int32_t VssThread::getUint32_VssApiValue(QString apiName, QString &currentTimeStamp)
{
#ifdef USING_VSS
    if (pModule != nullptr) {

        // Check if the function is callable
        if (PyCallable_Check(pFunc)) {

            // Prepare the arguments for the function call
            PyObject *pArgs = PyTuple_Pack(1, PyUnicode_FromString(apiName.toStdString().c_str()));

            // Call the function
            PyObject *pValue = PyObject_CallObject(pFunc, pArgs);            
            Py_DECREF(pArgs);
            // Check if the result is a tuple
            if (!pValue) return 0;
            if (PyTuple_Check(pValue)) {
                PyObject *pVal = PyTuple_GetItem(pValue, 0);
                PyObject *pTime = PyTuple_GetItem(pValue, 1);
                // //////qDebug() << "PyTuple_Check True";

                if (pVal && pTime) {
                    u_int32_t result = PyLong_AsUnsignedLong(pVal);
                    const char *timestampCStr = PyUnicode_AsUTF8(pTime);

                    if (timestampCStr) {
                        std::string timestamp = timestampCStr;
                        currentTimeStamp = QString::fromStdString(timestamp);
                        Py_DECREF(pValue);
                        // return std::make_tuple(QString::fromStdString(result), QString::fromStdString(timestamp));
                        return result;
                    }
                 }
            }
            else {
                // //////qDebug() << "PyTuple_Check False";
                if (pValue != nullptr) {
                    if (currentTimeStamp == "") 
                        return false;
                    // Convert the result to a C++ string
                    u_int32_t result = PyLong_AsUnsignedLong(pValue);
                    Py_DECREF(pValue);
                    return result;
                } else {
                    PyErr_Print();
                    std::cerr << "Call to get_tts_text failed" << std::endl;
                }
            }            
        } else {
            if (PyErr_Occurred()) PyErr_Print();
            std::cerr << "Cannot find function 'get_tts_text'" << std::endl;
        }        
    } else {
        PyErr_Print();
        std::cerr << "Failed to load 'vssclient'" << std::endl;
    } 
#endif
    return 0;
}

QString VssThread::getString_VssApiValue(QString apiName, QString &currentTimeStamp)
{
#ifdef USING_VSS
    if (pModule != nullptr) {

        // Check if the function is callable
        if (PyCallable_Check(pFunc)) {

            // Prepare the arguments for the function call
            PyObject *pArgs = PyTuple_Pack(1, PyUnicode_FromString(apiName.toStdString().c_str()));

            // Call the function
            PyObject *pValue = PyObject_CallObject(pFunc, pArgs);            
            Py_DECREF(pArgs);
            // Check if the result is a tuple
            if (!pValue) return "nullstring";
            if (PyTuple_Check(pValue)) {
                PyObject *pVal = PyTuple_GetItem(pValue, 0);
                PyObject *pTime = PyTuple_GetItem(pValue, 1);
                // //////qDebug() << "PyTuple_Check True";

                if (pVal && pTime) {
                    const char *resultCStr = PyUnicode_AsUTF8(pVal);
                    const char *timestampCStr = PyUnicode_AsUTF8(pTime);

                    if (resultCStr && timestampCStr) {
                        std::string result = resultCStr;
                        std::string timestamp = timestampCStr;
                        currentTimeStamp = QString::fromStdString(timestamp);
                        Py_DECREF(pValue);
                        // return std::make_tuple(QString::fromStdString(result), QString::fromStdString(timestamp));
                        return QString::fromStdString(result);
                    }
                 }
            }
            else {
                // //////qDebug() << "PyTuple_Check False";
                if (pValue != nullptr) {
                    // Convert the result to a C++ string
                    const char* resultCStr = PyUnicode_AsUTF8(pValue);
                    if (resultCStr != nullptr) {
                        std::string result = resultCStr;
                        Py_DECREF(pValue);
                        return QString::fromStdString(result);
                    } else {
                        Py_DECREF(pValue);
                        PyErr_Print();
                        std::cerr << "Error: PyUnicode_AsUTF8 returned null" << std::endl;
                    }
                } else {
                    PyErr_Print();
                    std::cerr << "Call to get_tts_text failed" << std::endl;
                }
            }            
        } else {
            if (PyErr_Occurred()) PyErr_Print();
            std::cerr << "Cannot find function 'get_tts_text'" << std::endl;
        }        
    } else {
        PyErr_Print();
        std::cerr << "Failed to load 'vssclient'" << std::endl;
    } 
#endif
    return "nullstring";
}

AiassistAsync::AiassistAsync()
{
    vssThread = new VssThread(this);    
    vssThread->start();    
}

AiassistAsync::~AiassistAsync()
{
    if(vssThread)
        delete vssThread;
    endPyEnv();
}

void AiassistAsync::setTextToSpeech(QString msg)
{
    updateTextToSpeech(msg);
}