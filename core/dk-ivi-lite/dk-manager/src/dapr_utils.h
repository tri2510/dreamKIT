#ifndef DAPR_UTILS_H
#define DAPR_UTILS_H

#include <QObject>
#include <QDebug>
#include <QThread>
#include <QFile>

class Dapr_Utils: public QObject
{
    Q_OBJECT
private:
    QString _dapr_dir;
    QString _proto_dir;
    QString _app_args;
    QString _log_dir;
public:
    Dapr_Utils(QString dapr_dir, QString proto_dir, QString _log_dir);
    int stopApp(QString app_id);
    int startApp(QString app_id);
    int stopAllApp();
    QString daprCliList();
};

#endif // DAPR_UTILS_H
