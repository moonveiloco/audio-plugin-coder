#!/usr/bin/env bash
# Modnetic Amber — interactive JIVE preview (live-reload).
# Headless alternative: append --screenshot out.png
/home/moonveil/Projects/VST-PLUGINS/audio-plugin-coder/_tools/jive-preview/build/jive-preview_artefacts/Release/jive-preview \
    /home/moonveil/Projects/VST-PLUGINS/audio-plugin-coder/design_library/JIVE/modnetic-amber/layout.xml \
    --laf modnetic "$@"
