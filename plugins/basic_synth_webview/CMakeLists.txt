cmake_minimum_required(VERSION 3.22)

# Plugin definition with WebView support
juce_add_plugin(basic_synth_webview
    COMPANY_NAME "BasicSynth"
    PLUGIN_MANUFACTURER_CODE "Bsyn"
    PLUGIN_CODE "Bswv"
    FORMATS VST3 Standalone
    PRODUCT_NAME "basic_synth_webview"
    NEEDS_WEB_BROWSER TRUE
)

# Embed web UI files into binary
juce_add_binary_data(basic_synth_webview_WebUI
    SOURCES
        Source/ui/public/index.html
        Source/ui/public/js/index.js
        Source/ui/public/js/juce/index.js
)

# Source files
target_sources(basic_synth_webview
    PRIVATE
        Source/PluginProcessor.cpp
        Source/PluginEditor.cpp
)

# Include paths
target_include_directories(basic_synth_webview
    PRIVATE
        Source
)

# Required JUCE modules
target_link_libraries(basic_synth_webview
    PRIVATE
        basic_synth_webview_WebUI
        juce::juce_audio_basics
        juce::juce_audio_devices
        juce::juce_audio_formats
        juce::juce_audio_plugin_client
        juce::juce_audio_processors
        juce::juce_audio_utils
        juce::juce_core
        juce::juce_data_structures
        juce::juce_dsp
        juce::juce_events
        juce::juce_graphics
        juce::juce_gui_basics
        juce::juce_gui_extra
    PUBLIC
        juce::juce_recommended_config_flags
        juce::juce_recommended_lto_flags
        juce::juce_recommended_warning_flags
)

# Compile definitions
target_compile_definitions(basic_synth_webview
    PUBLIC
        JUCE_VST3_CAN_REPLACE_VST2=0
        JUCE_USE_CURL=0
        _USE_MATH_DEFINES=1
)
