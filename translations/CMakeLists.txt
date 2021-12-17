# special case skip regeneration

add_custom_target(ts-all)

set(repo_root_directory "${CMAKE_CURRENT_SOURCE_DIR}/../..")
set(en_ts_file_dir "${CMAKE_CURRENT_BINARY_DIR}/en_ts")

# Create a rudimentary .ts file in ${en_ts_file_dir}.
function(generate_empty_ts_file file_name)
    if(NOT EXISTS "${en_ts_file_dir}/${file_name}")
        file(WRITE "${en_ts_file_dir}/${file_name}" "<TS></TS>")
    endif()
endfunction()

function(add_ts_target target input_file output_file)
    add_custom_target(${target}
        COMMAND ${QT_CMAKE_EXPORT_NAMESPACE}::lupdate -locations relative -no-ui-lines -no-sort "@${input_file}" -ts ${output_file}
    )
endfunction()

function(add_ts_targets catalog)
    cmake_parse_arguments(arg "" "" "DIRECTORIES;EXCLUDE" ${ARGN})
    generate_empty_ts_file("${catalog}_en.ts")
    file(GLOB ts_files "${catalog}_*.ts")

    set(languages)
    foreach(file IN LISTS ts_files)
        if(file MATCHES "([a-z][a-z](_[A-Z][A-Z])?).ts$")
            list(APPEND languages ${CMAKE_MATCH_1})
        endif()
    endforeach()

    set(file_list)
    foreach(dir IN LISTS arg_DIRECTORIES)
        set(dir_path "${repo_root_directory}/${dir}")
        if (NOT IS_DIRECTORY ${dir_path})
            message(WARNING "Directory '${dir_path}' for ${catalog} does not exist. Skipping...")
            continue()
        endif()
        file(GLOB_RECURSE catalog_files "${dir_path}/**")
        list(APPEND file_list ${catalog_files})
    endforeach()
    if (NOT file_list)
        message(WARNING "No source files located for ${catalog}, skipping target creation")
        return()
    endif()

    set(source_files_list_file "${CMAKE_CURRENT_BINARY_DIR}/${catalog}_file_list.txt")
    set(inclusion_regex "\\.h$|\\.cpp$|\\.hpp$|\\.cxx$|\\.cc$|\\.mm$|\\.qml$|\\.ui$")
    list(FILTER file_list INCLUDE REGEX "${inclusion_regex}")
    list(FILTER file_list EXCLUDE REGEX /doc/snippets/)
    if (arg_EXCLUDE)
        list(FILTER file_list EXCLUDE REGEX ${arg_EXCLUDE})
    endif()
    list(JOIN file_list "\n" file_list_string)

    file(GENERATE
        OUTPUT "${source_files_list_file}"
        CONTENT "${file_list_string}"
    )

    add_custom_target(ts-${catalog}-all)
    add_dependencies(ts-all ts-${catalog}-all)
    foreach(lang IN LISTS languages)
        set(lang_target_name ts-${catalog}-${lang})
        add_ts_target(${lang_target_name}
            ${source_files_list_file}
            "${CMAKE_CURRENT_SOURCE_DIR}/${catalog}_${lang}.ts"
        )
        add_dependencies(ts-${catalog}-all ${lang_target_name})

        if(NOT TARGET ts-${lang})
            add_custom_target(ts-${lang})
        endif()
        add_dependencies(ts-${lang} ${lang_target_name})
    endforeach()
    add_ts_target(ts-${catalog}-untranslated
        ${source_files_list_file}
        "${CMAKE_CURRENT_SOURCE_DIR}/${catalog}_untranslated.ts"
    )
    add_dependencies(ts-${catalog}-all ts-${catalog}-untranslated)
endfunction()

# Create the English "translation" for "qt".
generate_empty_ts_file("qt_en.ts")

# Create TS targets
add_ts_targets(qtbase
    DIRECTORIES
        qtbase/src
        qtactiveqt/src # just 4 strings from QAxSelect
        qtimageformats/src # just 10 error messages from tga reader. uses bad context.
)
add_ts_targets(qtdeclarative DIRECTORIES qtdeclarative/src
               EXCLUDE declarative/src/quickcontrols2/designer)
add_ts_targets(qtmultimedia DIRECTORIES qtmultimedia/src)
#add_ts_targets(qtsvg DIRECTORIES qtsvg/src) # empty
#add_ts_targets(qtwebkit DIRECTORIES qtwebkit) # messages from test browser only

#add_ts_targets(qt3d DIRECTIORIES qt3d/src)  # empty except one dubious error message
add_ts_targets(qtconnectivity DIRECTORIES qtconnectivity/src)
#add_ts_targets(qtdocgallery DIRECTORIES qtdocgallery/src)  # dead module
#add_ts_targets(qtfeedback DIRECTORIES qtfeedback/src)  # empty
#add_ts_targets(qtjsondb DIRECTORIES qtjsondb/src)  # dead module, just 3 error messages
add_ts_targets(qtlocation DIRECTORIES qtlocation/src)
#add_ts_targets(qtpim DIRECTORIES qtpim/src)  # not released with qt
#add_ts_targets(qtsensors DIRECTORIES qtsensors/src) # empty
#add_ts_targets(qtsystems DIRECTORIES qtsystems/src)  # not released with qt
add_ts_targets(qtwebsockets DIRECTORIES qtwebsockets/src)
add_ts_targets(qtserialport DIRECTORIES qtserialport/src)
add_ts_targets(qtwebengine DIRECTORIES qtwebengine/src)
add_ts_targets(designer DIRECTORIES qttools/src/designer
                                    qttools/src/shared/deviceskin
                                    qttools/src/shared/findwidget
                                    qttools/src/shared/fontpanel
                                    qttools/src/shared/qtgradienteditor
                                    qttools/src/shared/qtpropertybrowser
                                    qttools/src/shared/qttoolbardialog)
add_ts_targets(linguist DIRECTORIES qttools/src/linguist/linguist)
add_ts_targets(assistant DIRECTORIES qttools/src/assistant/assistant
                                     qttools/src/shared/fontpanel) # add qcollectiongenerator here as well?
add_ts_targets(qt_help DIRECTORIES qttools/src/assistant/help)
#add_ts_targets(qmlscene DIRECTORIES qtdeclarative/tools/qmlscene)  # almost empty due to missing tr()

# Create check target
add_custom_target(check-ts
    COMMAND perl check-ts.pl
    WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
)
add_dependencies(check-ts ts-all)

# Update and install qm command
add_custom_target(updateqm ALL)

file(GLOB ts_files RELATIVE ${CMAKE_CURRENT_SOURCE_DIR} "*.ts")
file(GLOB en_ts_files "${en_ts_file_dir}/*.ts")
list(APPEND ts_files ${en_ts_files})

if(QT_WILL_INSTALL)
    set(qm_output_dir "${QT_BUILD_DIR}/${INSTALL_TRANSLATIONSDIR}")
else()
    set(qm_output_dir "${QT_BUILD_INTERNALS_RELOCATABLE_INSTALL_PREFIX}/${INSTALL_TRANSLATIONSDIR}")
endif()

set_source_files_properties(${ts_files} PROPERTIES OUTPUT_LOCATION "${qm_output_dir}")
qt_add_lrelease(updateqm
    TS_FILES ${ts_files}
    NO_GLOBAL_TARGET
    QM_FILES_OUTPUT_VARIABLE qm_files
    OPTIONS "-silent")
qt_install(FILES ${qm_files} DESTINATION "${INSTALL_TRANSLATIONSDIR}")

# Custom target to add modified ts files to git
add_custom_target(stage-ts
    COMMAND ${CMAKE_COMMAND} -DLCONVERT_BIN="$<TARGET_FILE:${QT_CMAKE_EXPORT_NAMESPACE}::lconvert>" -P ${CMAKE_CURRENT_SOURCE_DIR}/git-stage-script.cmake
    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    COMMAND_EXPAND_LISTS
)
