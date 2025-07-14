#include "prototype_utils.h"
#include "fileutils.h"

Prototype_Utils::Prototype_Utils(QString root_dir)
{
    this->_prototype_dir = root_dir;
}

QJsonArray Prototype_Utils::ReadPrototypeList()
{
    QString file_content = FileUtils::ReadFile(this->_prototype_dir + "prototypes.json");
    QJsonDocument doc = QJsonDocument::fromJson(file_content.toUtf8());
    QJsonArray jsonAppList = doc.array();

    return jsonAppList;
}

int Prototype_Utils::AppendPrototypeToList(QString proto_id, QString proto_name, QString execType, QString deployFrom)
{
    QJsonArray jsonAppList = this->ReadPrototypeList();

    bool found = false;
    for (int i = 0; i < jsonAppList.count(); i++)
    {
        QJsonObject obj = jsonAppList[i].toObject();
        if (proto_id == obj.value("id").toString())
        {
            qDebug() << __func__ << __LINE__ << " update current app id : " << proto_id;
            obj["lastDeploy"] = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss");
            jsonAppList[i] = obj;
            found = true;
            break;
        }
    }
    if (!found)
    {
        if(execType == "") {
            execType = "py";
        }
        if(deployFrom == "") {
            deployFrom = "digital.auto";
        }
        QJsonObject obj;
        obj["deployFrom"] = deployFrom;
        obj["execType"] = execType;
        obj["id"] = proto_id;
        obj["name"] = proto_name;
        obj["lastDeploy"] = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss");
        QJsonValue value(obj);
        jsonAppList.append(value);
    }

    qDebug() << "after append: jsonAppList: " << jsonAppList;

    QJsonDocument newDoc(jsonAppList);
    QString newContent = newDoc.toJson();
    int n_write_result = FileUtils::WriteFile(this->_prototype_dir + "prototypes.json", newContent);

    return n_write_result;
}

int Prototype_Utils::SavePrototypeCode(QString proto_id, QString proto_code)
{
    return 0;
}
