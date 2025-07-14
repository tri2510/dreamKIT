#ifndef PROTOTYPE_UTILS_H
#define PROTOTYPE_UTILS_H

#include <QObject>
#include <QJsonDocument>
#include <QJsonValue>
#include <QJsonArray>
#include <QJsonObject>
#include <QRandomGenerator>

class Prototype_Utils: public QObject
{
    Q_OBJECT
private:
    QString _prototype_dir;
public:
    Prototype_Utils(QString root_dir);
    QJsonArray ReadPrototypeList();
    int AppendPrototypeToList(QString proto_id, QString proto_name, QString execType="", QString deployFrom="");
    int SavePrototypeCode(QString proto_id, QString proto_code);
};

#endif // PROTOTYPE_UTILS_H
