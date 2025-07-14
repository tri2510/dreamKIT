#ifndef FILEUTILS_H
#define FILEUTILS_H

#include <QObject>

class FileUtils : public QObject
{
    Q_OBJECT
public:
    FileUtils();
    static QString ReadFile(QString filePath);
    static int WriteFile(QString filePath, QString content);
    static int CreateDirIfNotExist(QString filePath);
    static bool fileExists(std::string path);
};

#endif // FILEUTILS_H
