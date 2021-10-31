/*
    optionsmodel.cpp
    SPDX-FileCopyrightText: 2021 Han Young <hanyoung@protonmail.com>
    SPDX-FileCopyrightText: 2019 Kevin Ottens <kevin.ottens@enioka.com>
    SPDX-License-Identifier: GPL-2.0-or-later
*/
#pragma once
#include <QAbstractListModel>
class SelectedLanguageModel;
class FormatsSettings;
class LanguageListModel : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(SelectedLanguageModel *selectedLanguageModel READ selectedLanguageModel CONSTANT)
    Q_PROPERTY(int currentIndex READ currentIndex WRITE setCurrentIndex NOTIFY currentIndexChanged)
    Q_PROPERTY(QString numberExample READ numberExample NOTIFY exampleChanged)
    Q_PROPERTY(QString currencyExample READ currencyExample NOTIFY exampleChanged)
    Q_PROPERTY(QString timeExample READ timeExample NOTIFY exampleChanged)
    Q_PROPERTY(QString metric READ metric NOTIFY exampleChanged)
public:
    enum Roles { NativeName = Qt::DisplayRole, LanguageCode, Flag };
    explicit LanguageListModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    SelectedLanguageModel *selectedLanguageModel() const;

    int currentIndex() const;
    void setCurrentIndex(int index);
    QString numberExample() const;
    QString currencyExample() const;
    QString timeExample() const;
    QString metric() const;

    Q_INVOKABLE void setFormatsSettings(QObject *settings);
Q_SIGNALS:
    void currentIndexChanged();
    void exampleChanged();

protected:
    friend class SelectedLanguageModel;
    static QString languageCodeToName(const QString &languageCode);

private:
    QString exampleHelper(std::function<QString(const QLocale&)> func) const;
    FormatsSettings *m_settings{nullptr};
    QList<QString> m_availableLanguages;
    SelectedLanguageModel *m_selectedLanguageModel;
    int m_index = -1;
};

class SelectedLanguageModel : public QAbstractListModel
{
    Q_OBJECT
public:
    explicit SelectedLanguageModel(LanguageListModel *parent);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    void setFormatsSettings(FormatsSettings *settings);

    Q_INVOKABLE void move(int from, int to);
    Q_INVOKABLE void remove(int index);
    Q_INVOKABLE void addLanguages(const QStringList &langs);

private:
    void saveLanguages();
    FormatsSettings *m_settings{nullptr};
    QList<QString> m_selectedLanguages;
};
