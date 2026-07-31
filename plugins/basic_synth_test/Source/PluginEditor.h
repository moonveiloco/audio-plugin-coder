#pragma once

#include <juce_gui_basics/juce_gui_basics.h>
#include "PluginProcessor.h"
#include "VisageControls.h"
#include "VisageJuceHost.h"

class BasicSynthTestAudioProcessorEditor : public VisagePluginEditor
{
public:
    BasicSynthTestAudioProcessorEditor(BasicSynthTestAudioProcessor&);
    ~BasicSynthTestAudioProcessorEditor() override;

    void onInit() override;
    void onRender() override;
    void onDestroy() override;
    void onResize(int w, int h) override;

private:
    BasicSynthTestAudioProcessor& audioProcessor;
    std::unique_ptr<VisageMainView> mainView;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(BasicSynthTestAudioProcessorEditor)
};