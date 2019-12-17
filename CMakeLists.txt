# special case skip regeneration
cmake_minimum_required(VERSION 3.16.0)

project(QtTranslations
    VERSION 6.0.0
    DESCRIPTION "Qt Translations"
    HOMEPAGE_URL "https://qt.io/"
)

set(QT_REPO_NOT_WARNINGS_CLEAN TRUE)
find_package(Qt6 ${PROJECT_VERSION} CONFIG REQUIRED COMPONENTS BuildInternals Core Linguist)

include(QtSetup) # for qt_install

add_subdirectory(translations)
