#include "PluginProcessor.h"
#include "PluginEditor.h"

#include <cmath>

static constexpr float kTwoPi = 6.28318530718f;

//==============================================================================
void Voice::reset()
{
    active = false;
    note = 60;
    unisonIndex = 0;
    velocity = 0.8f;
    phase1 = 0.0f;
    phase2 = 0.0f;
    envLevel = 0.0f;
    envStage = 0;
    noteFrequency = 440.0f;
}

float Voice::renderEnvelope(double sr, float attack, float decay, float sustain, float release)
{
    switch (envStage)
    {
    case 0: // Attack
        envLevel += 1.0f / static_cast<float>(attack * sr);
        if (envLevel >= 1.0f) { envLevel = 1.0f; envStage = 1; }
        break;
    case 1: // Decay
        envLevel -= (1.0f - sustain) / static_cast<float>(decay * sr);
        if (envLevel <= sustain) { envLevel = sustain; envStage = 2; }
        break;
    case 2: // Sustain
        break;
    case 3: // Release
        envLevel -= sustain / static_cast<float>(release * sr);
        if (envLevel <= 0.0f) { envLevel = 0.0f; active = false; }
        break;
    }
    return envLevel;
}

//==============================================================================
BasicSynthWebviewAudioProcessor::BasicSynthWebviewAudioProcessor()
    : AudioProcessor(BusesProperties().withOutput("Output", juce::AudioChannelSet::stereo(), true)),
      apvts(*this, nullptr, "PARAMETERS", createParameterLayout())
{
    buildWavetables();
}

BasicSynthWebviewAudioProcessor::~BasicSynthWebviewAudioProcessor() = default;

//==============================================================================
juce::AudioProcessorValueTreeState::ParameterLayout BasicSynthWebviewAudioProcessor::createParameterLayout()
{
    std::vector<std::unique_ptr<juce::RangedAudioParameter>> params;

    // OSC
    params.push_back(std::make_unique<juce::AudioParameterChoice>(
        ParameterIDs::OSC1_WAVEFORM, "OSC 1 Waveform",
        juce::StringArray{"Sine", "Triangle", "Saw", "Square", "PWM"}, 0));
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        ParameterIDs::OSC1_DETUNE, "OSC 1 Detune", -50.0f, 50.0f, 0.0f));
    params.push_back(std::make_unique<juce::AudioParameterChoice>(
        ParameterIDs::OSC2_WAVEFORM, "OSC 2 Waveform",
        juce::StringArray{"Sine", "Triangle", "Saw", "Square", "PWM"}, 1));
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        ParameterIDs::OSC2_DETUNE, "OSC 2 Detune", -50.0f, 50.0f, 5.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        ParameterIDs::OSC_MIX, "OSC Mix", 0.0f, 1.0f, 0.5f));
    params.push_back(std::make_unique<juce::AudioParameterChoice>(
        ParameterIDs::VOICE_MODE, "Voice Mode",
        juce::StringArray{"Poly", "Mono", "Unison"}, 0));
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        ParameterIDs::NOISE_LEVEL, "Noise Level", 0.0f, 1.0f, 0.0f));

    // Filter
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        ParameterIDs::FILTER_CUTOFF, "Cutoff", 20.0f, 20000.0f, 18000.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        ParameterIDs::FILTER_RESONANCE, "Resonance", 0.0f, 1.0f, 0.2f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        ParameterIDs::FILTER_ENV_AMOUNT, "Env Amount", -1.0f, 1.0f, 0.5f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        ParameterIDs::FILTER_KEYTRACK, "Key Track", 0.0f, 1.0f, 0.5f));

    // Envelope
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        ParameterIDs::ATTACK, "Attack", 0.001f, 10.0f, 1.0f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        ParameterIDs::DECAY, "Decay", 0.001f, 10.0f, 0.8f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        ParameterIDs::SUSTAIN, "Sustain", 0.0f, 1.0f, 0.7f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        ParameterIDs::RELEASE, "Release", 0.001f, 15.0f, 3.0f));

    // Reverb
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        ParameterIDs::REVERB_MIX, "Reverb Mix", 0.0f, 1.0f, 0.35f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        ParameterIDs::REVERB_SIZE, "Reverb Size", 0.0f, 1.0f, 0.65f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        ParameterIDs::REVERB_DECAY, "Reverb Decay", 0.0f, 1.0f, 0.6f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        ParameterIDs::REVERB_DAMPING, "Reverb Damping", 0.0f, 1.0f, 0.5f));
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        ParameterIDs::REVERB_SHIMMER, "Shimmer", 0.0f, 1.0f, 0.2f));

    // Master
    params.push_back(std::make_unique<juce::AudioParameterFloat>(
        ParameterIDs::VOLUME, "Volume", 0.0f, 1.0f, 0.75f));
    params.push_back(std::make_unique<juce::AudioParameterChoice>(
        ParameterIDs::POLYPHONY, "Polyphony",
        juce::StringArray{"1", "2", "4", "8", "12", "16"}, 3));

    return { params.begin(), params.end() };
}

//==============================================================================
void BasicSynthWebviewAudioProcessor::buildWavetables()
{
    for (int i = 0; i < kWavetableSize; ++i)
    {
        float p = static_cast<float>(i) / static_cast<float>(kWavetableSize);

        // Sine
        wavetables[0][i] = std::sin(kTwoPi * p);

        // Triangle
        wavetables[1][i] = std::abs(4.0f * p - 2.0f) - 1.0f;

        // Saw
        wavetables[2][i] = 2.0f * p - 1.0f;

        // Square
        wavetables[3][i] = p < 0.5f ? 1.0f : -1.0f;

        // PWM (25% duty)
        wavetables[4][i] = p < 0.25f ? 1.0f : -1.0f;
    }
}

float BasicSynthWebviewAudioProcessor::renderOscillator(float phase, WavetableType type) const
{
    int idx = static_cast<int>(type);
    phase = phase - std::floor(phase);
    float fIndex = phase * static_cast<float>(kWavetableSize);
    int i0 = static_cast<int>(fIndex) % kWavetableSize;
    int i1 = (i0 + 1) % kWavetableSize;
    float frac = fIndex - static_cast<float>(i0);
    return wavetables[idx][i0] + frac * (wavetables[idx][i1] - wavetables[idx][i0]);
}

float BasicSynthWebviewAudioProcessor::renderNoise(uint32_t& seed) const
{
    seed = seed * 1103515245u + 12345u;
    return static_cast<float>(static_cast<int32_t>(seed)) * (1.0f / 2147483648.0f);
}

//==============================================================================
void BasicSynthWebviewAudioProcessor::prepareToPlay(double sr, int samplesPerBlock)
{
    sampleRate = sr;

    for (auto& v : voices)
        v.reset();

    juce::dsp::ProcessSpec spec;
    spec.sampleRate = sr;
    spec.maximumBlockSize = static_cast<juce::uint32>(samplesPerBlock);
    spec.numChannels = 2;

    filterLeft.prepare(spec);
    filterRight.prepare(spec);
    filterLeft.setType(juce::dsp::StateVariableTPTFilterType::lowpass);
    filterRight.setType(juce::dsp::StateVariableTPTFilterType::lowpass);

    reverb.reset();

    masterVolSmooth.reset(sr, 0.02);
    cutoffSmooth.reset(sr, 0.02);
    resonanceSmooth.reset(sr, 0.02);

    masterVolSmooth.setCurrentAndTargetValue(0.75f);
    cutoffSmooth.setCurrentAndTargetValue(18000.0f);
    resonanceSmooth.setCurrentAndTargetValue(0.2f);

    shimmerPhase = 0.0f;
}

void BasicSynthWebviewAudioProcessor::releaseResources() {}

bool BasicSynthWebviewAudioProcessor::isBusesLayoutSupported(const BusesLayout& layouts) const
{
    return layouts.getMainOutputChannelSet() == juce::AudioChannelSet::stereo();
}

//==============================================================================
void BasicSynthWebviewAudioProcessor::processBlock(juce::AudioBuffer<float>& buffer, juce::MidiBuffer& midiMessages)
{
    juce::ScopedNoDenormals noDenormals;
    auto numSamples = buffer.getNumSamples();
    auto numChannels = buffer.getNumChannels();

    for (int ch = 0; ch < numChannels; ++ch)
        buffer.clear(ch, 0, numSamples);

    // Read all parameters
    auto* volRaw          = apvts.getRawParameterValue(ParameterIDs::VOLUME);
    auto* osc1WaveRaw     = apvts.getRawParameterValue(ParameterIDs::OSC1_WAVEFORM);
    auto* osc1DetuneRaw   = apvts.getRawParameterValue(ParameterIDs::OSC1_DETUNE);
    auto* osc2WaveRaw     = apvts.getRawParameterValue(ParameterIDs::OSC2_WAVEFORM);
    auto* osc2DetuneRaw   = apvts.getRawParameterValue(ParameterIDs::OSC2_DETUNE);
    auto* oscMixRaw       = apvts.getRawParameterValue(ParameterIDs::OSC_MIX);
    auto* noiseLevelRaw   = apvts.getRawParameterValue(ParameterIDs::NOISE_LEVEL);
    auto* voiceModeRaw    = apvts.getRawParameterValue(ParameterIDs::VOICE_MODE);
    auto* filterCutoffRaw = apvts.getRawParameterValue(ParameterIDs::FILTER_CUTOFF);
    auto* filterResRaw    = apvts.getRawParameterValue(ParameterIDs::FILTER_RESONANCE);
    auto* filterEnvRaw    = apvts.getRawParameterValue(ParameterIDs::FILTER_ENV_AMOUNT);
    auto* filterKeyRaw    = apvts.getRawParameterValue(ParameterIDs::FILTER_KEYTRACK);
    auto* attackRaw       = apvts.getRawParameterValue(ParameterIDs::ATTACK);
    auto* decayRaw        = apvts.getRawParameterValue(ParameterIDs::DECAY);
    auto* sustainRaw      = apvts.getRawParameterValue(ParameterIDs::SUSTAIN);
    auto* releaseRaw      = apvts.getRawParameterValue(ParameterIDs::RELEASE);
    auto* reverbMixRaw    = apvts.getRawParameterValue(ParameterIDs::REVERB_MIX);
    auto* reverbSizeRaw   = apvts.getRawParameterValue(ParameterIDs::REVERB_SIZE);
    [[maybe_unused]] auto* reverbDecayRaw  = apvts.getRawParameterValue(ParameterIDs::REVERB_DECAY);
    auto* reverbDampRaw   = apvts.getRawParameterValue(ParameterIDs::REVERB_DAMPING);
    auto* reverbShimRaw   = apvts.getRawParameterValue(ParameterIDs::REVERB_SHIMMER);
    auto* polyphonyRaw    = apvts.getRawParameterValue(ParameterIDs::POLYPHONY);

    // Process MIDI
    for (const auto metadata : midiMessages)
    {
        auto msg = metadata.getMessage();
        if (msg.isNoteOn())
            handleMidiNoteOn(msg.getNoteNumber(), msg.getVelocity() / 127.0f);
        else if (msg.isNoteOff())
            handleMidiNoteOff(msg.getNoteNumber());
        else if (msg.isAllNotesOff() || msg.isAllSoundOff())
            handleMidiNoteOff(-1, true);
    }

    // Cache mode/polyphony
    voiceMode = static_cast<int>(voiceModeRaw->load());
    {
        int polyIdx = static_cast<int>(polyphonyRaw->load());
        static constexpr int polyChoices[] = { 1, 2, 4, 8, 12, 16 };
        maxPolyphony = polyChoices[std::min(polyIdx, 5)];
    }

    float invSr = 1.0f / static_cast<float>(sampleRate);

    masterVolSmooth.setTargetValue(volRaw->load());
    cutoffSmooth.setTargetValue(filterCutoffRaw->load());
    resonanceSmooth.setTargetValue(filterResRaw->load());

    int osc1Type = static_cast<int>(osc1WaveRaw->load());
    int osc2Type = static_cast<int>(osc2WaveRaw->load());

    float attackVal   = attackRaw->load();
    float decayVal    = decayRaw->load();
    float sustainVal  = sustainRaw->load();
    float releaseVal  = releaseRaw->load();

    float oscMix    = oscMixRaw->load();
    float noiseLvl  = noiseLevelRaw->load();
    float detune1   = osc1DetuneRaw->load();
    float detune2   = osc2DetuneRaw->load();

    float envAmt    = filterEnvRaw->load();
    float keyTrk    = filterKeyRaw->load();

    // Reverb parameters
    juce::Reverb::Parameters reverbParams;
    reverbParams.roomSize   = reverbSizeRaw->load();
    reverbParams.damping    = reverbDampRaw->load();
    reverbParams.wetLevel   = reverbMixRaw->load();
    reverbParams.dryLevel   = 1.0f - reverbMixRaw->load();
    reverbParams.width      = 1.0f;
    reverbParams.freezeMode = 0.0f;
    reverb.setParameters(reverbParams);

    float reverbShimmerGain = reverbShimRaw->load();
    float reverbMix         = reverbMixRaw->load();

    // We'll apply master volume at end, so advanced smooth value
    masterVolSmooth.setTargetValue(volRaw->load());

    for (int s = 0; s < numSamples; ++s)
    {
        float outputL = 0.0f, outputR = 0.0f;
        int voiceCount = 0;
        float avgEnv = 0.0f;
        int envCount = 0;

        for (int v = 0; v < kMaxVoices; ++v)
        {
            auto& voice = voices[v];
            if (!voice.active)
                continue;

            voiceCount++;

            // Calculate frequency with detune
            float baseFreq = voice.noteFrequency;

            // Assign detune based on voice's unison index
            float detuneAmt = (voice.unisonIndex == 0) ? detune1 : detune2;
            float detuneRatio = std::pow(2.0f, detuneAmt / 1200.0f);

            // Unison additional detune
            float unisonRatio = 1.0f;
            if (voiceMode == 2 && voice.unisonIndex < kUnisonVoices)
                unisonRatio = std::pow(2.0f, unisonDetune[voice.unisonIndex] / 1200.0f);

            float oscFreq = baseFreq * detuneRatio * unisonRatio;

            // Phase update
            float delta = oscFreq * invSr;
            voice.phase1 += delta;
            voice.phase2 += delta;
            if (voice.phase1 >= 1.0f) voice.phase1 -= 1.0f;
            if (voice.phase2 >= 1.0f) voice.phase2 -= 1.0f;

            // Render oscillators
            float osc1Sample = renderOscillator(voice.phase1, static_cast<WavetableType>(osc1Type));
            float osc2Sample = renderOscillator(voice.phase2, static_cast<WavetableType>(osc2Type));

            // Mix oscillators
            float sample = osc1Sample * (1.0f - oscMix) + osc2Sample * oscMix;

            // Add noise
            if (noiseLvl > 0.0f)
                sample += renderNoise(noiseSeed) * noiseLvl;

            // Apply envelope
            float env = voice.renderEnvelope(sampleRate, attackVal, decayVal, sustainVal, releaseVal);
            if (!voice.active)
            {
                voiceCount--;
                continue;
            }

            avgEnv += voice.envLevel;
            envCount++;

            sample *= env * voice.velocity;

            // Voice panning for unison
            float panL = 1.0f, panR = 1.0f;
            if (voiceMode == 2 && voice.unisonIndex < kUnisonVoices)
            {
                float p = unisonPan[voice.unisonIndex];
                panL = std::sqrt(1.0f - std::max(0.0f, p));
                panR = std::sqrt(1.0f + std::min(0.0f, p));
            }

            outputL += sample * panL;
            outputR += sample * panR;
        }

        // Scale by voice count to prevent overload
        if (voiceCount > 1)
        {
            float scale = 1.0f / std::sqrt(static_cast<float>(voiceCount));
            outputL *= scale;
            outputR *= scale;
        }

        // Filter with envelope + keytrack modulation
        float cutoff  = cutoffSmooth.getNextValue();
        float resonance = resonanceSmooth.getNextValue();

        float modCutoff = cutoff;
        if (envCount > 0)
        {
            avgEnv /= static_cast<float>(envCount);

            if (envAmt >= 0.0f)
                modCutoff += envAmt * avgEnv * 15000.0f;
            else
                modCutoff *= std::pow(2.0f, envAmt * avgEnv * 4.0f);

            // Keytrack: use first active voice's note
            for (auto& voice : voices)
            {
                if (voice.active)
                {
                    float noteFloat = static_cast<float>(voice.note - 69) / 12.0f;
                    modCutoff *= std::pow(2.0f, noteFloat * keyTrk * 0.5f);
                    break;
                }
            }
        }

        modCutoff = juce::jlimit(20.0f, 20000.0f, modCutoff);

        filterLeft.setCutoffFrequency(modCutoff);
        filterRight.setCutoffFrequency(modCutoff);
        filterLeft.setResonance(resonance);
        filterRight.setResonance(resonance);

        outputL = filterLeft.processSample(0, outputL);
        outputR = filterRight.processSample(1, outputR);

        // Reverb + Shimmer
        shimmerPhase += 0.002f;
        if (shimmerPhase >= 1.0f) shimmerPhase -= 1.0f;

        float reverbInL = outputL + shimmerDelayL * reverbShimmerGain * 0.3f;
        float reverbInR = outputR + shimmerDelayR * reverbShimmerGain * 0.3f;

        float reverbOutL = reverbInL;
        float reverbOutR = reverbInR;
        reverb.processStereo(&reverbOutL, &reverbOutR, 1);

        shimmerDelayL = reverbOutL * reverbMix;
        shimmerDelayR = reverbOutR * reverbMix;

        // Dry/wet mix
        outputL = outputL * (1.0f - reverbMix) + reverbOutL * reverbMix;
        outputR = outputR * (1.0f - reverbMix) + reverbOutR * reverbMix;

        // Master volume
        float vol = masterVolSmooth.getNextValue();
        outputL *= vol;
        outputR *= vol;

        // Soft clip
        auto softClip = [](float x) -> float
        {
            if (x > 1.0f) return 1.0f;
            if (x < -1.0f) return -1.0f;
            return x - (x * x * x) / 3.0f;
        };
        outputL = softClip(outputL);
        outputR = softClip(outputR);

        buffer.addSample(0, s, outputL);
        if (numChannels > 1)
            buffer.addSample(1, s, outputR);
        else
            buffer.addSample(0, s, outputR);
    }
}

//==============================================================================
void BasicSynthWebviewAudioProcessor::handleMidiNoteOn(int note, float velocity)
{
    if (voiceMode == 1) // Mono
    {
        for (auto& v : voices)
            if (v.active)
                v.envStage = 3;

        lastMonoNote = note;

        auto idx = allocateVoice();
        if (idx < 0) return;

        auto& voice = voices[static_cast<size_t>(idx)];
        voice.reset();
        voice.active = true;
        voice.note = note;
        voice.velocity = velocity;
        voice.envStage = 0;
        voice.noteFrequency = 440.0f * std::pow(2.0f, (note - 69) / 12.0f);
    }
    else if (voiceMode == 2) // Unison
    {
        for (int u = 0; u < kUnisonVoices; ++u)
        {
            auto idx = allocateVoice();
            if (idx < 0) break;

            auto& voice = voices[static_cast<size_t>(idx)];
            voice.reset();
            voice.active = true;
            voice.note = note;
            voice.velocity = velocity;
            voice.envStage = 0;
            voice.unisonIndex = u;
            voice.phase1 = static_cast<float>(u) * 0.333f; // spread phases
            voice.phase2 = static_cast<float>(u) * 0.333f;
            voice.noteFrequency = 440.0f * std::pow(2.0f, (note - 69) / 12.0f);
        }
    }
    else // Poly
    {
        auto idx = allocateVoice();
        if (idx < 0) return;

        auto& voice = voices[static_cast<size_t>(idx)];
        voice.reset();
        voice.active = true;
        voice.note = note;
        voice.velocity = velocity;
        voice.envStage = 0;
        voice.noteFrequency = 440.0f * std::pow(2.0f, (note - 69) / 12.0f);
    }
}

void BasicSynthWebviewAudioProcessor::handleMidiNoteOff(int note, bool allNotes)
{
    if (allNotes)
    {
        for (auto& v : voices)
            if (v.active)
                v.envStage = 3;
        return;
    }

    for (auto& v : voices)
        if (v.active && v.note == note)
            v.envStage = 3;
}

int BasicSynthWebviewAudioProcessor::allocateVoice()
{
    for (size_t i = 0; i < static_cast<size_t>(maxPolyphony); ++i)
        if (!voices[i].active)
            return static_cast<int>(i);

    int best = -1;
    for (size_t i = 0; i < static_cast<size_t>(maxPolyphony); ++i)
    {
        if (best < 0)
        {
            best = static_cast<int>(i);
            continue;
        }
        if (voices[i].envStage == 3 && voices[static_cast<size_t>(best)].envStage != 3)
        {
            best = static_cast<int>(i);
            continue;
        }
        if (voices[i].note < voices[static_cast<size_t>(best)].note)
            best = static_cast<int>(i);
    }
    return best;
}

//==============================================================================
juce::AudioProcessorEditor* BasicSynthWebviewAudioProcessor::createEditor()
{
    return new BasicSynthWebviewAudioProcessorEditor(*this);
}

bool BasicSynthWebviewAudioProcessor::hasEditor() const { return true; }

const juce::String BasicSynthWebviewAudioProcessor::getName() const { return "basic_synth_webview"; }
bool BasicSynthWebviewAudioProcessor::acceptsMidi() const { return true; }
bool BasicSynthWebviewAudioProcessor::producesMidi() const { return false; }
bool BasicSynthWebviewAudioProcessor::isMidiEffect() const { return false; }
double BasicSynthWebviewAudioProcessor::getTailLengthSeconds() const { return 0.0; }

int BasicSynthWebviewAudioProcessor::getNumPrograms() { return 1; }
int BasicSynthWebviewAudioProcessor::getCurrentProgram() { return 0; }
void BasicSynthWebviewAudioProcessor::setCurrentProgram(int) {}
const juce::String BasicSynthWebviewAudioProcessor::getProgramName(int) { return {}; }
void BasicSynthWebviewAudioProcessor::changeProgramName(int, const juce::String&) {}

void BasicSynthWebviewAudioProcessor::getStateInformation(juce::MemoryBlock& destData)
{
    auto state = apvts.copyState();
    std::unique_ptr<juce::XmlElement> xml(state.createXml());
    copyXmlToBinary(*xml, destData);
}

void BasicSynthWebviewAudioProcessor::setStateInformation(const void* data, int sizeInBytes)
{
    std::unique_ptr<juce::XmlElement> xml(getXmlFromBinary(data, sizeInBytes));
    if (xml)
        apvts.replaceState(juce::ValueTree::fromXml(*xml));
}

juce::AudioProcessor* JUCE_CALLTYPE createPluginFilter()
{
    return new BasicSynthWebviewAudioProcessor();
}
