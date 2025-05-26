#ifndef COMMONUTILS_H
#define COMMONUTILS_H

#include <QObject>
#include <QCryptographicHash>

class CommonUtils
{
public:
    CommonUtils();
    static quint64 dk_hash(const QString &str);
    static std::string runLinuxCommand(const char *cmd);
    static QString get_dreamkit_code(std::string dkboard_unqfile, std::string dkdreamkit_unqfile);
};

#endif // COMMONUTILS_H
