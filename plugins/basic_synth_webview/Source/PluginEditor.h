#pragma once

#include <juce_audio_processors/juce_audio_processors.h>
#include <juce_gui_extra/juce_gui_extra.h>
#include "PluginProcessor.h"
#include "ParameterIDs.hpp"

//==============================================================================
class BasicSynthWebviewAudioProcessorEditor : public juce::AudioProcessorEditor
{
public:
    BasicSynthWebviewAudioProcessorEditor(BasicSynthWebviewAudioProcessor&);
    ~BasicSynthWebviewAudioProcessorEditor() override;

    void paint(juce::Graphics&) override;
    void resized() override;

private:
    BasicSynthWebviewAudioProcessor& audioProcessor;

    // ═══════════════════════════════════════════════════════════════════
    // CRITICAL: Member Declaration Order
    // 1. RELAYS (destroyed last)
    // 2. WEBVIEW (destroyed middle)
    // 3. ATTACHMENTS (destroyed first)
    // ═══════════════════════════════════════════════════════════════════

    // ── Slider Relays ──
    juce::WebSliderRelay osc1DetuneRelay      { ParameterIDs::OSC1_DETUNE };
    juce::WebSliderRelay osc2DetuneRelay      { ParameterIDs::OSC2_DETUNE };
    juce::WebSliderRelay oscMixRelay           { ParameterIDs::OSC_MIX };
    juce::WebSliderRelay noiseLevelRelay       { ParameterIDs::NOISE_LEVEL };
    juce::WebSliderRelay filterCutoffRelay     { ParameterIDs::FILTER_CUTOFF };
    juce::WebSliderRelay filterResonanceRelay  { ParameterIDs::FILTER_RESONANCE };
    juce::WebSliderRelay filterEnvAmountRelay  { ParameterIDs::FILTER_ENV_AMOUNT };
    juce::WebSliderRelay filterKeytrackRelay   { ParameterIDs::FILTER_KEYTRACK };
    juce::WebSliderRelay attackRelay           { ParameterIDs::ATTACK };
    juce::WebSliderRelay decayRelay            { ParameterIDs::DECAY };
    juce::WebSliderRelay sustainRelay          { ParameterIDs::SUSTAIN };
    juce::WebSliderRelay releaseRelay          { ParameterIDs::RELEASE };
    juce::WebSliderRelay reverbMixRelay        { ParameterIDs::REVERB_MIX };
    juce::WebSliderRelay reverbSizeRelay       { ParameterIDs::REVERB_SIZE };
    juce::WebSliderRelay reverbDecayRelay      { ParameterIDs::REVERB_DECAY };
    juce::WebSliderRelay reverbDampingRelay    { ParameterIDs::REVERB_DAMPING };
    juce::WebSliderRelay reverbShimmerRelay    { ParameterIDs::REVERB_SHIMMER };
    juce::WebSliderRelay volumeRelay           { ParameterIDs::VOLUME };

    // ── ComboBox Relays ──
    juce::WebComboBoxRelay osc1WaveformRelay   { ParameterIDs::OSC1_WAVEFORM };
    juce::WebComboBoxRelay osc2WaveformRelay   { ParameterIDs::OSC2_WAVEFORM };
    juce::WebComboBoxRelay voiceModeRelay      { ParameterIDs::VOICE_MODE };
    juce::WebComboBoxRelay polyphonyRelay      { ParameterIDs::POLYPHONY };

    // ── WebView (destroyed after relays created, before attachments) ──
    std::unique_ptr<juce::WebBrowserComponent> webView;

    // ── Slider Attachments (destroyed first) ──
    juce::WebSliderParameterAttachment osc1DetuneAttachment;
    juce::WebSliderParameterAttachment osc2DetuneAttachment;
    juce::WebSliderParameterAttachment oscMixAttachment;
    juce::WebSliderParameterAttachment noiseLevelAttachment;
    juce::WebSliderParameterAttachment filterCutoffAttachment;
    juce::WebSliderParameterAttachment filterResonanceAttachment;
    juce::WebSliderParameterAttachment filterEnvAmountAttachment;
    juce::WebSliderParameterAttachment filterKeytrackAttachment;
    juce::WebSliderParameterAttachment attackAttachment;
    juce::WebSliderParameterAttachment decayAttachment;
    juce::WebSliderParameterAttachment sustainAttachment;
    juce::WebSliderParameterAttachment releaseAttachment;
    juce::WebSliderParameterAttachment reverbMixAttachment;
    juce::WebSliderParameterAttachment reverbSizeAttachment;
    juce::WebSliderParameterAttachment reverbDecayAttachment;
    juce::WebSliderParameterAttachment reverbDampingAttachment;
    juce::WebSliderParameterAttachment reverbShimmerAttachment;
    juce::WebSliderParameterAttachment volumeAttachment;

    // ── ComboBox Attachments ──
    juce::WebComboBoxParameterAttachment osc1WaveformAttachment;
    juce::WebComboBoxParameterAttachment osc2WaveformAttachment;
    juce::WebComboBoxParameterAttachment voiceModeAttachment;
    juce::WebComboBoxParameterAttachment polyphonyAttachment;

    // Resource provider
    std::optional<juce::WebBrowserComponent::Resource> getResource(const juce::String& url);
    static const char* getMimeForExtension(const juce::String& extension);

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(BasicSynthWebviewAudioProcessorEditor)
};
