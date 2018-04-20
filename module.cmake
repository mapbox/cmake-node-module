set(NODE_MODULE_NAN_VERSION "2.10.0")
set(NODE_MODULE_MINIMUM_ABI 46) # Don't build node modules for versions earlier than Node 4
set(NODE_MODULE_CACHE_DIR ${CMAKE_CURRENT_LIST_DIR})


function(add_node_module NAME)
    cmake_parse_arguments("" "" "MINIMUM_NODE_ABI;NAN_VERSION;INSTALL_DIR" "EXCLUDE_NODE_ABIS" ${ARGN})
    if(NOT _MINIMUM_NODE_ABI)
        set(_MINIMUM_NODE_ABI "${NODE_MODULE_MINIMUM_ABI}")
    endif()
    if(NOT _NAN_VERSION)
        set(_NAN_VERSION "${NODE_MODULE_NAN_VERSION}")
    endif()
    if(_UNPARSED_ARGUMENTS)
        message(WARNING "[Node.js] Unused arguments: '${_UNPARSED_ARGUMENTS}'")
    endif()


    # Create master target
    add_library(${NAME} INTERFACE)


    # Obtain a list of current Node versions and retrieves the latest version per ABI
    if(NOT EXISTS "${NODE_MODULE_CACHE_DIR}/node/index.tab")
        file(DOWNLOAD "https://nodejs.org/dist/index.tab"
            "${NODE_MODULE_CACHE_DIR}/node/index.tab"
            TLS_VERIFY ON
        )
    endif()
    file(STRINGS "${NODE_MODULE_CACHE_DIR}/node/index.tab" _INDEX_FILE)
    list(REMOVE_AT _INDEX_FILE 0)
    set(_ABIS)
    foreach(_LINE IN LISTS _INDEX_FILE)
        string(REGEX MATCHALL "[^\t]*\t" _COLUMNS "${_LINE}")
        list(GET _COLUMNS 8 _ABI)
        string(STRIP "${_ABI}" _ABI)
        if(${_ABI} GREATER_EQUAL ${_MINIMUM_NODE_ABI} AND NOT ${_ABI} IN_LIST _EXCLUDE_NODE_ABIS AND NOT DEFINED _NODE_ABI_${_ABI}_VERSION)
            list(APPEND _ABIS ${_ABI})
            list(GET _COLUMNS 0 _VERSION)
            string(STRIP "${_VERSION}" _NODE_ABI_${_ABI}_VERSION)
        endif()
    endforeach()



    # Install NAN
    if(NOT EXISTS "${NODE_MODULE_CACHE_DIR}/nan/${_NAN_VERSION}/nan.h")
        message(STATUS "[Node.js] Downloading NAN version ${_NAN_VERSION}")
        file(DOWNLOAD "https://registry.npmjs.org/nan/-/nan-${_NAN_VERSION}.tgz"
            "${NODE_MODULE_CACHE_DIR}/nan/${_NAN_VERSION}.tar.gz"
            STATUS _STATUS
            TLS_VERIFY ON)
        list(GET _STATUS 0 _STATUS_CODE)
        if(NOT _STATUS_CODE EQUAL 0)
            file(REMOVE "${NODE_MODULE_CACHE_DIR}/nan/${_NAN_VERSION}.tar.gz")
            list(GET _STATUS 1 _STATUS_MESSAGE)
            message(FATAL_ERROR "[Node.js] Failed to download NAN ${_NAN_VERSION}: ${_STATUS_MESSAGE}")
        endif()
        file(REMOVE_RECURSE "${NODE_MODULE_CACHE_DIR}/nan/${_NAN_VERSION}" "${NODE_MODULE_CACHE_DIR}/nan/package")
        execute_process(COMMAND ${CMAKE_COMMAND} -E tar xfz "${NODE_MODULE_CACHE_DIR}/nan/${_NAN_VERSION}.tar.gz"
            WORKING_DIRECTORY "${NODE_MODULE_CACHE_DIR}/nan"
            RESULT_VARIABLE _STATUS_CODE
            OUTPUT_VARIABLE _STATUS_MESSAGE
            ERROR_VARIABLE _STATUS_MESSAGE)
        file(REMOVE "${NODE_MODULE_CACHE_DIR}/nan/${_NAN_VERSION}.tar.gz")
        if(NOT _STATUS_CODE EQUAL 0)
            message(FATAL_ERROR "[Node.js] Failed to unpack NAN ${_NAN_VERSION}: ${_STATUS_MESSAGE}")
        endif()
        file(RENAME "${NODE_MODULE_CACHE_DIR}/nan/package" "${NODE_MODULE_CACHE_DIR}/nan/${_NAN_VERSION}")
    endif()


    # Generate a target for every ABI
    set(_TARGETS)
    foreach(_ABI IN LISTS _ABIS)
        set(_NODE_VERSION ${_NODE_ABI_${_ABI}_VERSION})

        # Download the headers if we don't have them yet
        if(NOT EXISTS "${NODE_MODULE_CACHE_DIR}/node/${_NODE_VERSION}/node.h")
            message(STATUS "[Node.js] Downloading headers for Node ${_NODE_VERSION}")
            file(DOWNLOAD "https://nodejs.org/download/release/${_NODE_VERSION}/node-${_NODE_VERSION}-headers.tar.gz"
                "${NODE_MODULE_CACHE_DIR}/node/${_NODE_VERSION}.tar.gz"
                STATUS _STATUS
                TLS_VERIFY ON)
            list(GET _STATUS 0 _STATUS_CODE)
            if(NOT _STATUS_CODE EQUAL 0)
                file(REMOVE "${NODE_MODULE_CACHE_DIR}/node/${_NODE_VERSION}.tar.gz")
                list(GET _STATUS 1 _STATUS_MESSAGE)
                message(FATAL_ERROR "[Node.js] Failed to download headers for Node ${_NODE_VERSION}: ${_STATUS_MESSAGE}")
            endif()
            file(REMOVE_RECURSE "${NODE_MODULE_CACHE_DIR}/node/${_NODE_VERSION}" "${NODE_MODULE_CACHE_DIR}/node/node-${_NODE_VERSION}")
            execute_process(COMMAND ${CMAKE_COMMAND} -E tar xfz "${NODE_MODULE_CACHE_DIR}/node/${_NODE_VERSION}.tar.gz"
                WORKING_DIRECTORY "${NODE_MODULE_CACHE_DIR}/node"
                RESULT_VARIABLE _STATUS_CODE
                OUTPUT_VARIABLE _STATUS_MESSAGE
                ERROR_VARIABLE _STATUS_MESSAGE)
            file(REMOVE "${NODE_MODULE_CACHE_DIR}/node/${_NODE_VERSION}.tar.gz")
            if(NOT _STATUS_CODE EQUAL 0)
                message(FATAL_ERROR "[Node.js] Failed to unpack headers for Node ${_NODE_VERSION}: ${_STATUS_MESSAGE}")
            endif()
            file(RENAME "${NODE_MODULE_CACHE_DIR}/node/node-${_NODE_VERSION}/include/node" "${NODE_MODULE_CACHE_DIR}/node/${_NODE_VERSION}")
            file(REMOVE_RECURSE "${NODE_MODULE_CACHE_DIR}/node/node-${_NODE_VERSION}")
        endif()


        # Generate the library
        set(_TARGET "${NAME}.abi-${_ABI}")
        add_library(${_TARGET} SHARED "${NODE_MODULE_CACHE_DIR}/empty.cpp")
        list(APPEND _TARGETS "${_TARGET}")


        # C identifiers can only contain certain characters (e.g. no dashes)
        string(REGEX REPLACE "[^a-z0-9]+" "_" NAME_IDENTIFIER "${NAME}")

        set_target_properties(${_TARGET} PROPERTIES
            OUTPUT_NAME "${_TARGET}"
            SOURCES "" # Removes the fake empty.cpp again
            PREFIX ""
            SUFFIX ".node"
            MACOSX_RPATH ON
            C_VISIBILITY_PRESET hidden
            CXX_VISIBILITY_PRESET hidden
            POSITION_INDEPENDENT_CODE TRUE
        )

        # NAN requires C++11. Use a compile option to allow interfaces to override this with a later version.
        target_compile_options(${_TARGET} PRIVATE -std=c++11)

        target_compile_definitions(${_TARGET} PRIVATE
            "MODULE_NAME=${NAME_IDENTIFIER}"
            "BUILDING_NODE_EXTENSION"
            "_LARGEFILE_SOURCE"
            "_FILE_OFFSET_BITS=64"
        )

        target_include_directories(${_TARGET} PRIVATE
            "${NODE_MODULE_CACHE_DIR}/node/${_NODE_VERSION}"
            "${NODE_MODULE_CACHE_DIR}/nan/${_NAN_VERSION}"
        )

        target_link_libraries(${_TARGET} PRIVATE ${NAME})

        if(APPLE)
            set_target_properties(${_TARGET} PROPERTIES
                LINK_FLAGS "-undefined dynamic_lookup -bind_at_load"
            )
            target_compile_definitions(${_TARGET} PRIVATE
                "_DARWIN_USE_64_BIT_INODE=1"
            )
        else()
            set_target_properties(${_TARGET} PROPERTIES
                LINK_FLAGS "-z now"
            )
        endif()

        # Copy the file to the installation directory, if provided.
        if (_INSTALL_DIR)
            add_custom_command(
                TARGET ${_TARGET}
                POST_BUILD
                COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${_TARGET}> "${_INSTALL_DIR}/$<TARGET_FILE_NAME:${_TARGET}>"
            )
        endif()
    endforeach()

    # Add a target that builds all Node ABIs.
    add_custom_target("${NAME}.all")
    add_dependencies("${NAME}.all" ${_TARGETS})

    # Add a variable that allows users to iterate over all of the generated/dependendent targets.
    set("${NAME}::abis" "${_ABIS}" PARENT_SCOPE)
    set("${NAME}::targets" "${_TARGETS}" PARENT_SCOPE)
endfunction()
