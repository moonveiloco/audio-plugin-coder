#include "PluginProcessor.h"
#include "PluginEditor.h"

BasicSynthTestAudioProcessorEditor::BasicSynthTestAudioProcessorEditor(BasicSynthTestAudioProcessor& p)
    : VisagePluginEditor(p), audioProcessor(p)
{
    setSize(800, 500);
}

BasicSynthTestAudioProcessorEditor::~BasicSynthTestAudioProcessorEditor() = default;

void BasicSynthTestAudioProcessorEditor::onInit()
{
    mainView = std::make_unique<VisageMainView>();
    addFrameToCanvas(mainView.get());
    mainView->setBounds(0, 0, getWidth(), getHeight());
}

void BasicSynthTestAudioProcessorEditor::onRender()
{
    if (mainView)
    {
        auto& lfoRate = *audioProcessor.apvts.getRawParameterValue("lfo_rate");
        auto& lfoDepth = *audioProcessor.apvts.getRawParameterValue("lfo_depth");
        auto& lfoWaveform = *audioProcessor.apvts.getRawParameterValue("lfo_waveform");
        auto& oscWaveform = *audioProcessor.apvts.getRawParameterValue("osc_waveform");

        mainView->lfoPhase += lfoRate.load() * 0.016f;
        if (mainView->lfoPhase >= 1.0f)
            mainView->lfoPhase -= 1.0f;

        mainView->setParam(0, audioProcessor.apvts.getRawParameterValue("master_volume")->load());
        mainView->setParam(1, audioProcessor.apvts.getRawParameterValue("voice_count")->load() / 16.0f);
        mainView->setParam(2, (float)oscWaveform.load());
        mainView->setParam(3, audioProcessor.apvts.getRawParameterValue("osc_detune")->load() / 50.0f * 0.5f + 0.5f);
        mainView->setParam(4, audioProcessor.apvts.getRawParameterValue("osc_sub_mix")->load());
        mainView->setParam(5, audioProcessor.apvts.getRawParameterValue("filter_cutoff")->load() / 20000.0f);
        mainView->setParam(6, audioProcessor.apvts.getRawParameterValue("filter_resonance")->load());
        mainView->setParam(7, audioProcessor.apvts.getRawParameterValue("filter_envelope")->load() * 0.5f + 0.5f);
        mainView->setParam(8, audioProcessor.apvts.getRawParameterValue("env_attack")->load() / 10.0f);
        mainView->setParam(9, audioProcessor.apvts.getRawParameterValue("env_decay")->load() / 10.0f);
        mainView->setParam(10, audioProcessor.apvts.getRawParameterValue("env_sustain")->load());
        mainView->setParam(11, audioProcessor.apvts.getRawParameterValue("env_release")->load() / 10.0f);
        mainView->setParam(12, audioProcessor.apvts.getRawParameterValue("lfo_rate")->load() / 20.0f);
        mainView->setParam(13, audioProcessor.apvts.getRawParameterValue("lfo_depth")->load());
        mainView->setParam(14, (float)lfoWaveform.load());

        mainView->redraw();
    }
}

void BasicSynthTestAudioProcessorEditor::onDestroy()
{
    if (mainView) {
        removeFrameFromCanvas(mainView.get());
        mainView.reset();
    }
}

void BasicSynthTestAudioProcessorEditor::onResize(int w, int h)
{
    if (mainView) {
        mainView->setBounds(0, 0, w, h);
        mainView->redraw();
    }
}