# Generated from qttranslations.pro.

cmake_minimum_required(VERSION 3.15.0)

include(.cmake.conf)
project(QtTranslations # special case
    VERSION "${QT_REPO_MODULE_VERSION}"
    DESCRIPTION "Qt Translations" # special case
    HOMEPAGE_URL "https://qt.io/"
    LANGUAGES CXX C
)

# special case begin
set(QT_REPO_NOT_WARNINGS_CLEAN TRUE)
find_package(Qt6 ${PROJECT_VERSION} CONFIG REQUIRED COMPONENTS BuildInternals Core Linguist) # special case

include(QtSetup) # for qt_install

add_subdirectory(translations)
# special case end
