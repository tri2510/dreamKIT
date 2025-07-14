#include "fileutils.h"
#include <QFile>
#include <QFileInfo>
#include <QDir>
#include <QDebug>
#include <QThread>

FileUtils::FileUtils()
{
    qDebug() << "FileUtils initial!";
}

int FileUtils::CreateDirIfNotExist(QString filePath)
{
    if (!QDir(filePath).exists())
    {
        if (!QDir().mkdir(filePath))
        {
            return -1;
        }
    }
    return 0;
}

QString FileUtils::ReadFile(QString filePath)
{
    QString result;
    if (filePath.length() == 0)
    {
        return result;
    }

    QFile file(filePath);
    file.open(QIODevice::ReadOnly | QIODevice::Text);
    if (file.isOpen())
    {
        result = QString(file.readAll());
        file.close();
    }
    else
    {
        qDebug() << filePath << " is not existing";
        result = "";
    }

    return result;
}

int FileUtils::WriteFile(QString filePath, QString content)
{
    QFile file(filePath);
    if (!file.open(QIODevice::ReadWrite | QIODevice::Truncate | QIODevice::Text))
    {
        qDebug() << __func__ << __LINE__ << file.errorString();
        return -1;
    }
    QTextStream stream(&file);
    stream << content;
    QThread::msleep(50);
    file.flush();
    file.close();

    return 0;
}

bool FileUtils::fileExists(std::string path)
{
    QFileInfo check_file(QString::fromStdString(path));
    // check if path exists and if yes: Is it really a file and no directory?
    return check_file.exists() && check_file.isFile();
}
