#include <QCoreApplication>
#include <QThread>
#include <QDebug>
#include "dkmanager.h"

int main(int argc, char *argv[])
{
    QCoreApplication a(argc, argv);

    qDebug() << "dk-manager verion 1.0.0 !!!";

    DkManger dkManager;
    dkManager.Start();

    return a.exec();
}
