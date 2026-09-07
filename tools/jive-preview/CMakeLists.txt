cmake_minimum_required(VERSION 3.22)

project(jive-preview VERSION 1.0.0 LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(NOT APC_TOOLS_DIR)
    message(FATAL_ERROR "APC_TOOLS_DIR must point to the APC repo root (the directory containing _tools/JUCE and _tools/JIVE)")
endif()

if(NOT EXISTS "${APC_TOOLS_DIR}/_tools/JUCE")
    message(FATAL_ERROR "JUCE missing at ${APC_TOOLS_DIR}/_tools/JUCE (run: git submodule update --init --recursive)")
endif()

if(NOT EXISTS "${APC_TOOLS_DIR}/_tools/JIVE")
    message(FATAL_ERROR "JIVE missing at ${APC_TOOLS_DIR}/_tools/JIVE (run: git submodule update --init --recursive)")
endif()

add_subdirectory("${APC_TOOLS_DIR}/_tools/JUCE" "${CMAKE_BINARY_DIR}/_tools/JUCE")
add_subdirectory("${APC_TOOLS_DIR}/_tools/JIVE" "${CMAKE_BINARY_DIR}/_tools/JIVE")

juce_add_gui_app(jive-preview
    PRODUCT_NAME "jive-preview"
    COMPANY_NAME "APC"
    BUNDLE_ID "apc.jive-preview"
)

target_sources(jive-preview
    PRIVATE
        Source/Main.cpp
)

target_compile_definitions(jive-preview
    PRIVATE
        JIVE_GUI_ITEMS_HAVE_STYLE_SHEETS=1
        JUCE_WEB_BROWSER=0
        JUCE_USE_CURL=0
        JUCE_APPLICATION_NAME="$<TARGET_PROPERTY:jive-preview,JUCE_PRODUCT_NAME>"
        JUCE_APPLICATION_VERSION="$<TARGET_PROPERTY:jive-preview,JUCE_VERSION>"
)

# NOTE: no LTO (juce_recommended_lto_flags) — GCC 16 (Arch) hits an LTO
# internal compiler error linking JUCE; LTO brings nothing to a preview tool.
target_link_libraries(jive-preview
    PRIVATE
        juce::juce_gui_basics
        jive::jive_layouts
        jive::jive_style_sheets
        juce::juce_recommended_config_flags
)
