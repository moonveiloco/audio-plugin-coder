#include "PluginProcessor.h"
#include "PluginEditor.h"

#include <cmath>

static constexpr float kTwoPi = 6.28318530718f;

void Voice::reset()
{
    active = false;
    note = 60;
    velocity = 0.8f;
    phase = 0.0f;
    subPhase = 0.0f;
    envLevel = 0.0f;
    envStage = 0;
}

float Voice::renderEnvelope(double sr)
{
    switch (envStage)
    {
    case 0:
        envLevel += 1.0f / static_cast<float>(envAttack * sr);
        if (envLevel >= 1.0f) { envLevel = 1.0f; envStage = 1; }
        break;
    case 1:
        envLevel -= (1.0f - envSustain) / static_cast<float>(envDecay * sr);
        if (envLevel <= envSustain) { envLevel = envSustain; envStage = 2; }
        break;
    case 2:
        break;
    case 3:
        envLevel -= envSustain / static_cast<float>(envRelease * sr);
        if (envLevel <= 0.0f) { envLevel = 0.0f; active = false; }
        break;
    }
    return envLevel;
}

BasicSynthTestAudioProcessor::BasicSynthTestAudioProcessor()
    : AudioProcessor(BusesProperties().withOutput("Output", juce::AudioChannelSet::stereo(), true)),
      apvts(*this, nullptr, "PARAMETERS", createParameterLayout())
{
    buildWavetables();
}

BasicSynthTestAudioProcessor::~BasicSynthTestAudioProcessor() = default;

juce::AudioProcessorValueTreeState::ParameterLayout BasicSynthTestAudioProcessor::createParameterLayout()
{
    std::vector<std::unique_ptr<juce::RangedAudioParameter>> params;

    params.push_back(std::make_unique<juce::AudioParameterFloat>("master_volume", "Volume", 0.0f, 1.0f, 0.75f));
    params.push_back(std::make_unique<juce::AudioParameterInt>("voice_count", "Voices", 1, kMaxVoices, 8));

    params.push_back(std::make_unique<juce::AudioParameterChoice>("osc_waveform", "Waveform",
        juce::StringArray{"Sine", "Saw", "Square", "Triangle"}, 0));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("osc_detune", "Detune", -50.0f, 50.0f, 0.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("osc_sub_mix", "Sub Mix", 0.0f, 1.0f, 0.0f));

    params.push_back(std::make_unique<juce::AudioParameterFloat>("filter_cutoff", "Cutoff", 20.0f, 20000.0f, 20000.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("filter_resonance", "Resonance", 0.0f, 1.0f, 0.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("filter_envelope", "Env Amt", -1.0f, 1.0f, 0.0f));

    params.push_back(std::make_unique<juce::AudioParameterFloat>("env_attack", "Attack", 0.001f, 10.0f, 0.01f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("env_decay", "Decay", 0.001f, 10.0f, 0.3f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("env_sustain", "Sustain", 0.0f, 1.0f, 0.7f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("env_release", "Release", 0.001f, 10.0f, 0.5f));

    params.push_back(std::make_unique<juce::AudioParameterFloat>("lfo_rate", "LFO Rate", 0.1f, 20.0f, 2.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>("lfo_depth", "LFO Depth", 0.0f, 1.0f, 0.0f));
    params.push_back(std::make_unique<juce::AudioParameterChoice>("lfo_waveform", "LFO Wave",
        juce::StringArray{"Sine", "Triangle", "Square"}, 0));

    return { params.begin(), params.end() };
}

void BasicSynthTestAudioProcessor::buildWavetables()
{
    for (int i = 0; i < kWavetableSize; ++i)
    {
        float p = static_cast<float>(i) / static_cast<float>(kWavetableSize);
        wavetables[0][i] = std::sin(kTwoPi * p);
        wavetables[1][i] = 2.0f * p - 1.0f;
        wavetables[2][i] = p < 0.5f ? 1.0f : -1.0f;
        wavetables[3][i] = std::abs(4.0f * p - 2.0f) - 1.0f;
    }
}

float BasicSynthTestAudioProcessor::renderOscillator(float phase, WavetableType wavetype) const
{
    int idx = static_cast<int>(wavetype);
    phase = phase - std::floor(phase);
    float fIndex = phase * static_cast<float>(kWavetableSize);
    int i0 = static_cast<int>(fIndex) % kWavetableSize;
    int i1 = (i0 + 1) % kWavetableSize;
    float frac = fIndex - static_cast<float>(i0);
    return wavetables[idx][i0] + frac * (wavetables[idx][i1] - wavetables[idx][i0]);
}

float BasicSynthTestAudioProcessor::renderLFO(float phase, int waveform) const
{
    switch (waveform)
    {
    case 0: return std::sin(kTwoPi * phase);
    case 1: return std::abs(2.0f * phase - 1.0f) * 2.0f - 1.0f;
    case 2: return phase < 0.5f ? 1.0f : -1.0f;
    default: return 0.0f;
    }
}

void BasicSynthTestAudioProcessor::prepareToPlay(double sr, int samplesPerBlock)
{
    sampleRate = sr;
    lfoPhase = 0.0f;

    for (auto& v : voices)
        v.reset();

    juce::dsp::ProcessSpec spec;
    spec.sampleRate = sr;
    spec.maximumBlockSize = static_cast<juce::uint32>(samplesPerBlock);
    spec.numChannels = 2;

    filter.prepare(spec);
    filter.setType(juce::dsp::StateVariableTPTFilterType::lowpass);

    masterVolSmooth.reset(sr, 0.02);
    cutoffSmooth.reset(sr, 0.02);
    resonanceSmooth.reset(sr, 0.02);
    detuneSmooth.reset(sr, 0.05);
    subMixSmooth.reset(sr, 0.02);

    masterVolSmooth.setCurrentAndTargetValue(0.75f);
    cutoffSmooth.setCurrentAndTargetValue(20000.0f);
    resonanceSmooth.setCurrentAndTargetValue(0.0f);
    detuneSmooth.setCurrentAndTargetValue(0.0f);
    subMixSmooth.setCurrentAndTargetValue(0.0f);
}

void BasicSynthTestAudioProcessor::releaseResources() {}

bool BasicSynthTestAudioProcessor::isBusesLayoutSupported(const BusesLayout& layouts) const
{
    return layouts.getMainOutputChannelSet() == juce::AudioChannelSet::stereo();
}

void BasicSynthTestAudioProcessor::processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages)
{
    juce::ScopedNoDenormals noDenormals;
    auto numSamples = buffer.getNumSamples();
    auto numChannels = buffer.getNumChannels();

    for (int ch = 0; ch < numChannels; ++ch)
        buffer.clear(ch, 0, numSamples);

    auto* volRaw = apvts.getRawParameterValue("master_volume");
    auto* oscWaveformRaw = apvts.getRawParameterValue("osc_waveform");
    auto* oscDetuneRaw = apvts.getRawParameterValue("osc_detune");
    auto* oscSubMixRaw = apvts.getRawParameterValue("osc_sub_mix");
    auto* filterCutoffRaw = apvts.getRawParameterValue("filter_cutoff");
    auto* filterResonanceRaw = apvts.getRawParameterValue("filter_resonance");
    auto* filterEnvelopeRaw = apvts.getRawParameterValue("filter_envelope");
    auto* envAttackRaw = apvts.getRawParameterValue("env_attack");
    auto* envDecayRaw = apvts.getRawParameterValue("env_decay");
    auto* envSustainRaw = apvts.getRawParameterValue("env_sustain");
    auto* envReleaseRaw = apvts.getRawParameterValue("env_release");
    auto* lfoRateRaw = apvts.getRawParameterValue("lfo_rate");
    auto* lfoDepthRaw = apvts.getRawParameterValue("lfo_depth");
    auto* lfoWaveformRaw = apvts.getRawParameterValue("lfo_waveform");

    for (const auto metadata : midiMessages)
    {
        auto msg = metadata.getMessage();
        if (msg.isNoteOn())
            handleMidiNoteOn(msg.getNoteNumber(), msg.getVelocity() / 127.0f);
        else if (msg.isNoteOff())
            handleMidiNoteOff(msg.getNoteNumber());
    }

    float invSr = 1.0f / static_cast<float>(sampleRate);

    masterVolSmooth.setTargetValue(volRaw->load());
    cutoffSmooth.setTargetValue(filterCutoffRaw->load());
    resonanceSmooth.setTargetValue(filterResonanceRaw->load());
    detuneSmooth.setTargetValue(oscDetuneRaw->load());
    subMixSmooth.setTargetValue(oscSubMixRaw->load());

    float envAttackVal = envAttackRaw->load();
    float envDecayVal = envDecayRaw->load();
    float envSustainVal = envSustainRaw->load();
    float envReleaseVal = envReleaseRaw->load();

    int curWaveform = static_cast<int>(oscWaveformRaw->load());
    int lfoWaveform = static_cast<int>(lfoWaveformRaw->load());

    for (int s = 0; s < numSamples; ++s)
    {
        lfoPhase += lfoRateRaw->load() * invSr;
        if (lfoPhase >= 1.0f)
            lfoPhase -= 1.0f;

        float lfoValue = renderLFO(lfoPhase, lfoWaveform);
        float lfoMod = lfoValue * lfoDepthRaw->load();

        float outputL = 0.0f, outputR = 0.0f;

        for (int v = 0; v < kMaxVoices; ++v)
        {
            auto& voice = voices[v];
            if (!voice.active)
                continue;

            voice.envAttack = envAttackVal;
            voice.envDecay = envDecayVal;
            voice.envSustain = envSustainVal;
            voice.envRelease = envReleaseVal;

            float freq = voice.noteFrequency;
            float detuneRatio = std::pow(2.0f, detuneSmooth.getNextValue() / 1200.0f);
            float oscFreq = freq * detuneRatio;

            float delta = oscFreq * invSr;
            voice.phase += delta;
            if (voice.phase >= 1.0f)
                voice.phase -= 1.0f;

            voice.subPhase += oscFreq * 0.5f * invSr;
            if (voice.subPhase >= 1.0f)
                voice.subPhase -= 1.0f;

            float oscSample = renderOscillator(voice.phase, static_cast<WavetableType>(curWaveform));
            float subSample = renderOscillator(voice.subPhase, WavetableType::Square);
            float sample = oscSample + subSample * subMixSmooth.getNextValue();

            float env = voice.renderEnvelope(sampleRate);
            if (!voice.active)
                continue;

            sample *= env * voice.velocity;

            outputL += sample;
            outputR += sample;
        }

        float cutoffMod = cutoffSmooth.getNextValue() * std::pow(2.0f, lfoMod * 4.0f);
        float envMod = filterEnvelopeRaw->load();
        if (envMod >= 0.0f)
            cutoffMod += envMod * 10000.0f;
        else
            cutoffMod *= std::pow(2.0f, envMod * 4.0f);

        cutoffMod = juce::jlimit(20.0f, 20000.0f, cutoffMod);

        filter.setCutoffFrequency(cutoffMod);
        filter.setResonance(resonanceSmooth.getNextValue());

        outputL = filter.processSample(0, outputL);
        outputR = filter.processSample(1, outputR);

        float vol = masterVolSmooth.getNextValue();
        outputL *= vol;
        outputR *= vol;

        buffer.addSample(0, s, outputL);
        if (numChannels > 1)
            buffer.addSample(1, s, outputR);
        else
            buffer.addSample(0, s, outputR);
    }
}

void BasicSynthTestAudioProcessor::handleMidiNoteOn(int note, float velocity)
{
    auto idx = allocateVoice();
    if (idx < 0) return;

    auto& voice = voices[static_cast<size_t>(idx)];
    voice.active = true;
    voice.note = note;
    voice.velocity = velocity;
    voice.phase = 0.0f;
    voice.subPhase = 0.0f;
    voice.envLevel = 0.0f;
    voice.envStage = 0;
    voice.noteFrequency = 440.0f * std::pow(2.0f, (note - 69) / 12.0f);
}

void BasicSynthTestAudioProcessor::handleMidiNoteOff(int note)
{
    for (auto& voice : voices)
    {
        if (voice.active && voice.note == note)
            voice.envStage = 3;
    }
}

int BasicSynthTestAudioProcessor::allocateVoice()
{
    int oldest = -1;
    for (size_t i = 0; i < kMaxVoices; ++i)
    {
        if (!voices[i].active)
        {
            if (i < 8)
                return static_cast<int>(i);
        }
    }
    for (size_t i = 0; i < kMaxVoices; ++i)
    {
        if (!voices[i].active)
            return static_cast<int>(i);
        if (oldest < 0 || voices[i].note < voices[static_cast<size_t>(oldest)].note)
            oldest = static_cast<int>(i);
    }
    return oldest;
}

juce::AudioProcessorEditor* BasicSynthTestAudioProcessor::createEditor()
{
    return new BasicSynthTestAudioProcessorEditor(*this);
}

bool BasicSynthTestAudioProcessor::hasEditor() const { return true; }

const juce::String BasicSynthTestAudioProcessor::getName() const { return "basic_synth_test"; }
bool BasicSynthTestAudioProcessor::acceptsMidi() const { return true; }
bool BasicSynthTestAudioProcessor::producesMidi() const { return false; }
bool BasicSynthTestAudioProcessor::isMidiEffect() const { return false; }
double BasicSynthTestAudioProcessor::getTailLengthSeconds() const { return 0.0; }

int BasicSynthTestAudioProcessor::getNumPrograms() { return 1; }
int BasicSynthTestAudioProcessor::getCurrentProgram() { return 0; }
void BasicSynthTestAudioProcessor::setCurrentProgram(int) {}
const juce::String BasicSynthTestAudioProcessor::getProgramName(int) { return {}; }
void BasicSynthTestAudioProcessor::changeProgramName(int, const juce::String&) {}

void BasicSynthTestAudioProcessor::getStateInformation(juce::MemoryBlock& destData)
{
    auto state = apvts.copyState();
    std::unique_ptr<juce::XmlElement> xml(state.createXml());
    copyXmlToBinary(*xml, destData);
}

void BasicSynthTestAudioProcessor::setStateInformation(const void* data, int sizeInBytes)
{
    std::unique_ptr<juce::XmlElement> xml(getXmlFromBinary(data, sizeInBytes));
    if (xml)
        apvts.replaceState(juce::ValueTree::fromXml(*xml));
}

juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
    return new BasicSynthTestAudioProcessor();
}