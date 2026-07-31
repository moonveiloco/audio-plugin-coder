#pragma once

#include <juce_audio_processors/juce_audio_processors.h>
#include <juce_audio_basics/juce_audio_basics.h>
#include <juce_dsp/juce_dsp.h>

#include <array>
#include <cmath>

constexpr int kMaxVoices = 16;
constexpr int kWavetableSize = 2048;

enum class WavetableType { Sine, Triangle, Saw, Square, PWM };

struct Voice
{
    bool active = false;
    int note = 60;
    int unisonIndex = 0;
    float velocity = 0.8f;
    float phase1 = 0.0f;
    float phase2 = 0.0f;
    float envLevel = 0.0f;
    int envStage = 0;
    float noteFrequency = 440.0f;

    void reset();
    float renderEnvelope(double sampleRate, float attack, float decay, float sustain, float release);
};

//==============================================================================
class BasicSynthWebviewAudioProcessor : public juce::AudioProcessor
{
public:
    BasicSynthWebviewAudioProcessor();
    ~BasicSynthWebviewAudioProcessor() override;

    void prepareToPlay(double sampleRate, int samplesPerBlock) override;
    void releaseResources() override;

    bool isBusesLayoutSupported(const BusesLayout& layouts) const override;

    void processBlock(juce::AudioBuffer<float>&, juce::MidiBuffer&) override;
    using AudioProcessor::processBlock;

    juce::AudioProcessorEditor* createEditor() override;
    bool hasEditor() const override;

    const juce::String getName() const override;
    bool acceptsMidi() const override;
    bool producesMidi() const override;
    bool isMidiEffect() const override;
    double getTailLengthSeconds() const override;

    int getNumPrograms() override;
    int getCurrentProgram() override;
    void setCurrentProgram(int index) override;
    const juce::String getProgramName(int index) override;
    void changeProgramName(int index, const juce::String& newName) override;

    void getStateInformation(juce::MemoryBlock& destData) override;
    void setStateInformation(const void* data, int sizeInBytes) override;

    juce::AudioProcessorValueTreeState apvts;

    float renderOscillator(float phase, WavetableType type) const;
    float renderNoise(uint32_t& seed) const;

private:
    juce::AudioProcessorValueTreeState::ParameterLayout createParameterLayout();

    void handleMidiNoteOn(int note, float velocity);
    void handleMidiNoteOff(int note, bool allNotes = false);
    int allocateVoice();
    void buildWavetables();

    std::array<std::array<float, kWavetableSize>, 5> wavetables{};
    std::array<Voice, kMaxVoices> voices;

    juce::dsp::StateVariableTPTFilter<float> filterLeft;
    juce::dsp::StateVariableTPTFilter<float> filterRight;
    juce::Reverb reverb;

    juce::SmoothedValue<float> masterVolSmooth;
    juce::SmoothedValue<float> cutoffSmooth;
    juce::SmoothedValue<float> resonanceSmooth;

    double sampleRate = 44100.0;

    int voiceMode = 0;
    int maxPolyphony = 8;
    int lastMonoNote = -1;

    // Unison state
    static constexpr int kUnisonVoices = 3;
    float unisonDetune[3] = { 0.0f, 7.0f, -7.0f };
    float unisonPan[3]    = { 0.0f, -0.5f, 0.5f };

    // Noise state
    uint32_t noiseSeed = 12345;

    // Shimmer state
    float shimmerPhase = 0.0f;
    float shimmerDelayL = 0.0f;
    float shimmerDelayR = 0.0f;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(BasicSynthWebviewAudioProcessor)
};
