#pragma once

#include <juce_audio_processors/juce_audio_processors.h>
#include <juce_dsp/juce_dsp.h>

#include <array>
#include <cmath>

constexpr int kMaxVoices = 16;
constexpr int kWavetableSize = 2048;

enum class WavetableType { Sine, Saw, Square, Triangle };

struct Voice {
    bool active = false;
    int note = 60;
    float velocity = 0.8f;
    float phase = 0.0f;
    float subPhase = 0.0f;
    float envLevel = 0.0f;
    float envAttack = 0.01f;
    float envDecay = 0.3f;
    float envSustain = 0.7f;
    float envRelease = 0.5f;
    int envStage = 0;
    float noteFrequency = 440.0f;

    void reset();
    float renderEnvelope(double sampleRate);
};

class BasicSynthTestAudioProcessor : public juce::AudioProcessor
{
public:
    BasicSynthTestAudioProcessor();
    ~BasicSynthTestAudioProcessor() override;

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

    float renderOscillator(float phase, WavetableType wavetype) const;
    float renderLFO(float phase, int waveform) const;

private:
    juce::AudioProcessorValueTreeState::ParameterLayout createParameterLayout();

    void handleMidiNoteOn(int note, float velocity);
    void handleMidiNoteOff(int note);
    int allocateVoice();
    void buildWavetables();

    std::array<std::array<float, kWavetableSize>, 4> wavetables{};
    std::array<Voice, kMaxVoices> voices;

    juce::dsp::StateVariableTPTFilter<float> filter;

    juce::SmoothedValue<float> masterVolSmooth;
    juce::SmoothedValue<float> cutoffSmooth;
    juce::SmoothedValue<float> resonanceSmooth;
    juce::SmoothedValue<float> detuneSmooth;
    juce::SmoothedValue<float> subMixSmooth;

    double sampleRate = 44100.0;
    float lfoPhase = 0.0f;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(BasicSynthTestAudioProcessor)
};