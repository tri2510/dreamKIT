#include "common_utils.h"
#include "fileutils.h"
#include <QFile>
#include <QDebug>
#include <QThread>
#include <QCryptographicHash>
#include <QFileInfo>
#include <QtNetwork>

#include <QJsonDocument>
#include <QJsonValue>
#include <QJsonArray>
#include <QJsonObject>
#include <QRandomGenerator>

CommonUtils::CommonUtils()
{

}

quint64 CommonUtils::dk_hash(const QString &str)
{
    QByteArray hash = QCryptographicHash::hash(
        QByteArray::fromRawData((const char *)str.utf16(), str.length() * 2),
        QCryptographicHash::Md5);
    Q_ASSERT(hash.size() == 16);
    QDataStream stream(hash);
    qint64 a, b;
    stream >> a >> b;
    return a ^ b;
}

std::string CommonUtils::runLinuxCommand(const char *cmd)
{
    std::array<char, 1024 * 10> buffer;
    std::string result;
    std::unique_ptr<FILE, decltype(&pclose)> pipe(popen(cmd, "r"), pclose);
    if (!pipe)
    {
        throw std::runtime_error("popen() failed!");
    }
    while (fgets(buffer.data(), buffer.size(), pipe.get()) != nullptr)
    {
        result += buffer.data();
    }
    return result;
}


QString CommonUtils::get_dreamkit_code(std::string dkboard_unqfile, std::string dkdreamkit_unqfile) {
    QString prefix = "";

    prefix = qgetenv("DKCODE");
    if(prefix.isEmpty()) {
        prefix = "Target-Runtime";
    }

    QString serialNo = "";
    if (FileUtils::fileExists(dkboard_unqfile))
    {
        QString cmd = "cp " + QString::fromStdString(dkboard_unqfile) + " " + QString::fromStdString(dkdreamkit_unqfile);
        serialNo += FileUtils::ReadFile(QString::fromStdString(dkboard_unqfile));        
        system(cmd.toUtf8());
    }
    else if (FileUtils::fileExists(dkdreamkit_unqfile))
    {
        serialNo += FileUtils::ReadFile(QString::fromStdString(dkdreamkit_unqfile));
    }
    else
    {
        // It should happen only once when the app is started for the first time.
        int seed = QRandomGenerator::global()->generate();
        QRandomGenerator randomEngine(seed);
        int randomNo = randomEngine.generate();
        QString hashinput = QDateTime::currentDateTime().toString("yyyy-MM-dd HH:mm:ss") + QString::number(randomNo);
        QString hash = QString::number(CommonUtils::dk_hash(hashinput));
        QString hashInHex = QString::number(CommonUtils::dk_hash(hashinput), 16);
        //        qDebug() << __func__ << __LINE__ << "create DreamkitID : " << hash;
        qDebug() << __func__ << __LINE__ << "create DreamkitID in hex: " << hashInHex;
        QString cmd = "echo " + hashInHex + " > " + QString::fromStdString(dkdreamkit_unqfile) + "; sync;";
        system(cmd.toUtf8());
        QThread::msleep(100);

        serialNo = hashInHex;
    }

    serialNo.remove(QChar::Null);
    serialNo.replace("\n", "");
    if((serialNo.length()>8)) {
        serialNo = serialNo.right(8);
    }
    qDebug() << __func__ << __LINE__ << "serialNo: " << serialNo;

    return prefix + "-" + serialNo;
}
