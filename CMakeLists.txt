cmake_minimum_required(VERSION 3.22)
project(APC_System VERSION 1.0.0 LANGUAGES C CXX)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# ============================================
# OPTIONAL FEATURES
# ============================================
option(APC_ENABLE_VISAGE "Enable Visage UI framework support" OFF)

# ============================================
# PLATFORM DETECTION
# ============================================
if(WIN32)
    set(APC_PLATFORM "Windows")
    set(APC_PLATFORM_WINDOWS TRUE)
elseif(APPLE)
    set(APC_PLATFORM "macOS")
    set(APC_PLATFORM_MACOS TRUE)
elseif(UNIX)
    set(APC_PLATFORM "Linux")
    set(APC_PLATFORM_LINUX TRUE)
else()
    set(APC_PLATFORM "Unknown")
endif()

message(STATUS "--- APC BUILD SYSTEM ---")
message(STATUS "Platform: ${APC_PLATFORM}")
message(STATUS "Root Directory: ${CMAKE_CURRENT_SOURCE_DIR}")

# ============================================
# GLOBAL DEFINITIONS (Platform-Specific)
# ============================================
if(APC_PLATFORM_WINDOWS)
    # Windows-specific: WebView2
    set(JUCE_USE_WIN_WEBVIEW2 ON CACHE BOOL "" FORCE)
    add_definitions(-DJUCE_USE_WIN_WEBVIEW2=1)
    message(STATUS "WebView2: Enabled")
elseif(APC_PLATFORM_MACOS)
    # macOS-specific: WKWebView (system framework)
    set(JUCE_USE_WIN_WEBVIEW2 OFF CACHE BOOL "" FORCE)
    message(STATUS "WebView: WKWebView (macOS)")
elseif(APC_PLATFORM_LINUX)
    # Linux-specific: WebKitGTK
    set(JUCE_USE_WIN_WEBVIEW2 OFF CACHE BOOL "" FORCE)
    message(STATUS "WebView: WebKitGTK (Linux)")
endif()

# ============================================
# EXTERNAL TOOLS
# ============================================
set(JUCE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/_tools/JUCE")
set(VISAGE_DIR "${CMAKE_CURRENT_SOURCE_DIR}/_tools/visage")

if(NOT EXISTS "${JUCE_DIR}")
    message(FATAL_ERROR "JUCE missing at ${JUCE_DIR}")
endif()
add_subdirectory("${JUCE_DIR}")

# Visage is only needed for Visage UI framework plugins
if(APC_ENABLE_VISAGE)
    if(NOT EXISTS "${VISAGE_DIR}")
        message(FATAL_ERROR "Visage missing at ${VISAGE_DIR}")
    endif()
    add_subdirectory("${VISAGE_DIR}")
    if(TARGET visage AND NOT TARGET visage::visage)
        add_library(visage::visage ALIAS visage)
    endif()
endif()

# ============================================
# PLUGIN DISCOVERY
# ============================================

# External plugins in APC_PLUGINS_DIR
# APC_PLUGINS_DIR: Read from APC config, fallback to env var
if(DEFINED ENV{APC_PLUGINS_DIR})
    set(APC_PLUGINS_DIR "$ENV{APC_PLUGINS_DIR}")
else()
    execute_process(
        COMMAND bash ${CMAKE_SOURCE_DIR}/scripts/apc-config.sh plugins-dir
        OUTPUT_VARIABLE _APC_PLUGINS_DIR_OUT
        OUTPUT_STRIP_TRAILING_WHITESPACE
        RESULT_VARIABLE _APC_CONFIG_RESULT
    )
    if(_APC_CONFIG_RESULT EQUAL 0 AND _APC_PLUGINS_DIR_OUT)
        set(APC_PLUGINS_DIR "${_APC_PLUGINS_DIR_OUT}")
    else()
        message(FATAL_ERROR
            "APC_PLUGINS_DIR not configured (apc-config.sh exited with "
            "${_APC_CONFIG_RESULT}). External plugins will NOT be scanned.\n"
            "  - Run `/setup` to configure APC, OR\n"
            "  - Set the APC_PLUGINS_DIR env var.")
    endif()
endif()
if(EXISTS "${APC_PLUGINS_DIR}")
    message(STATUS "Scanning for plugins (external): ${APC_PLUGINS_DIR}")
    file(GLOB EXTERNAL_PLUGIN_DIRS "${APC_PLUGINS_DIR}/*")
else()
    set(EXTERNAL_PLUGIN_DIRS "")
endif()

# Combine plugin list (external only; legacy plugins/ removed)
set(PLUGIN_DIRS ${EXTERNAL_PLUGIN_DIRS})

set(APC_PLUGIN_COUNT 0)

foreach(PLUGIN_DIR ${PLUGIN_DIRS})
    get_filename_component(DIR_NAME ${PLUGIN_DIR} NAME)
    
    if(IS_DIRECTORY "${PLUGIN_DIR}")
        if(EXISTS "${PLUGIN_DIR}/CMakeLists.txt")
            message(STATUS " -> FOUND: ${DIR_NAME}")
            # Use binary_dir for out-of-tree plugins (APC_PLUGINS_DIR)
            add_subdirectory("${PLUGIN_DIR}" "${CMAKE_BINARY_DIR}/external/${DIR_NAME}")
            math(EXPR APC_PLUGIN_COUNT "${APC_PLUGIN_COUNT} + 1")
        else()
            message(STATUS " -> SKIPPING: ${DIR_NAME} (No CMakeLists.txt)")
        endif()
    endif()
endforeach()

message(STATUS "Total plugins found: ${APC_PLUGIN_COUNT}")
message(STATUS "--- END ---")
