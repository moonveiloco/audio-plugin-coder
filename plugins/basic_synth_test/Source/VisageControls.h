#pragma once

#include <visage/ui.h>
#include <visage/graphics.h>
#include "BinaryData.h"

#include <algorithm>
#include <cmath>

static const auto kBgColor = visage::Color(0xff0d0d1a);
static const auto kNeonPink = visage::Color(0xffff0088);
static const auto kNeonCyan = visage::Color(0xff00ccff);
static const auto kNeonPurple = visage::Color(0xff9900ff);
static const auto kPanelBg = visage::Color(0xff1a1a2e);
static const auto kTextDim = visage::Color(0xff666688);
static const auto kKnobTrack = visage::Color(0xff333355);

static constexpr float kArcStart = -2.35619f;
static constexpr float kArcRange = 4.71239f;

class VisageMainView : public visage::Frame
{
public:
    VisageMainView() = default;

    void init() override
    {
        updateFonts();
    }

    void dpiChanged() override
    {
        updateFonts();
    }

    void resized() override
    {
        w = width();
        h = height();
        waveformH = 56.0f;
        adsrH = 50.0f;
        topBarY = 4.0f;
        waveformY = topBarY + 20.0f;
        sectionsY = waveformY + waveformH + 8.0f;
        adsrY = h - adsrH - 4.0f;
        secW = w / 5.0f;
        knobSize = std::min(secW * 0.42f, (adsrY - sectionsY) * 0.32f);
    }

    void draw(visage::Canvas& canvas) override
    {
        canvas.setColor(kBgColor);
        canvas.fill(0, 0, w, h);

        drawTitle(canvas);
        drawWaveformDisplay(canvas);
        drawSections(canvas);
        drawADSREnvelope(canvas);
    }

    float getParam(int idx) const { return idx < 15 ? paramValues[idx] : 0.0f; }
    void setParam(int idx, float val) { if (idx < 15) paramValues[idx] = val; }
    float lfoPhase = 0.0f;

private:
    void drawTitle(visage::Canvas& canvas)
    {
        canvas.setColor(kNeonCyan);
        canvas.text("basic_synth_test", titleFont, visage::Font::kLeft,
                    10, topBarY, w - 20, 18);
    }

    void drawWaveformDisplay(visage::Canvas& canvas)
    {
        float wfY = waveformY;
        float wfH = waveformH;

        canvas.setColor(kPanelBg);
        canvas.fill(6, wfY, w - 12, wfH);

        canvas.setColor(kTextDim);
        canvas.text("OSCILLATOR", labelFont, visage::Font::kLeft,
                    12, wfY + 4, 100, 14);

        int waveIdx = (int)paramValues[2];
        float samples = 128.0f;
        float step = (w - 48.0f) / samples;
        float centerY = wfY + wfH * 0.5f;
        float amp = wfH * 0.35f;

        canvas.setColor(kNeonCyan);
        float lastX = 24.0f;
        float lastY = 0.0f;
        for (int i = 0; i <= (int)samples; ++i)
        {
            float p = (float)i / samples;
            float val = 0.0f;
            switch (waveIdx)
            {
            case 0: val = std::sin(6.28318530718f * p); break;
            case 1: val = 2.0f * p - 1.0f; break;
            case 2: val = p < 0.5f ? 1.0f : -1.0f; break;
            case 3: val = 2.0f * std::abs(2.0f * p - 1.0f) - 1.0f; break;
            }
            float x = 24.0f + i * step;
            float y = centerY - val * amp;
            if (i > 0)
                canvas.segment(lastX, lastY, x, y, 1.5f, false);
            lastX = x;
            lastY = y;
        }

        float sepX = 24.0f + paramValues[2] * step * 4.0f;
        canvas.setColor(kNeonPink.withAlpha(0.3f));
        canvas.segment(sepX, wfY + 4, sepX, wfY + wfH - 4, 1.0f, false);
    }

    void drawSections(visage::Canvas& canvas)
    {
        const char* secNames[] = { "MASTER", "OSCILLATOR", "FILTER", "ENVELOPE", "LFO" };
        int secCounts[] = { 2, 3, 3, 4, 3 };

        for (int s = 0; s < 5; ++s)
        {
            float x = s * secW;
            float secWidth = (s < 4) ? secW : w - s * secW;

            canvas.setColor(kPanelBg);
            canvas.fill(x + 4, sectionsY, secWidth - 8, adsrY - sectionsY);

            canvas.setColor(kNeonPurple);
            canvas.text(secNames[s], sectionFont, visage::Font::kCenter,
                        x + 8, sectionsY + 4, secWidth - 16, 16);

            float spacing = secWidth / (float)(secCounts[s] + 1);
            float startX = x + spacing;
            float knobCY = sectionsY + 28.0f + knobSize * 0.5f;

            int paramStart = 0;
            for (int i = 0; i < s; ++i) paramStart += secCounts[i];

            for (int p = 0; p < secCounts[s]; ++p)
            {
                float cx = startX + p * spacing;
                float val = paramValues[paramStart + p];
                drawKnob(canvas, cx, knobCY, knobSize, val, kNeonCyan);
            }
        }
    }

    void drawKnob(visage::Canvas& canvas, float cx, float cy, float size, float value, const visage::Color& color)
    {
        float radius = size * 0.42f;
        float angle = kArcStart + value * kArcRange;

        canvas.setColor(kKnobTrack);
        canvas.circle(cx - (radius + 1.0f), cy - (radius + 1.0f), (radius + 1.0f) * 2.0f);

        float thickness = 2.5f;
        canvas.setColor(kKnobTrack);
        canvas.arc(cx - radius, cy - radius, radius * 2.0f, thickness, 0.0f, kArcRange);

        canvas.setColor(color);
        canvas.arc(cx - radius, cy - radius, radius * 2.0f, thickness,
                   kArcStart + value * kArcRange * 0.5f, value * kArcRange);

        float dotX = cx + std::cos(angle) * (radius - 3.0f);
        float dotY = cy + std::sin(angle) * (radius - 3.0f);
        canvas.setColor(color);
        canvas.circle(dotX - 2.5f, dotY - 2.5f, 5.0f);
    }

    void drawADSREnvelope(visage::Canvas& canvas)
    {
        float ay = adsrY;
        float ah = adsrH;

        canvas.setColor(kPanelBg);
        canvas.fill(6, ay, w - 12, ah);

        float attack = paramValues[8];
        float decay = paramValues[9];
        float sustain = paramValues[10];
        float release = paramValues[11];

        float total = attack + decay + release;
        if (total < 0.01f) total = 0.01f;
        float aNorm = attack / total;
        float dNorm = decay / total;
        float rNorm = release / total;

        float graphW = w - 40.0f;
        float graphX = 20.0f;
        float topY = ay + 6.0f;
        float botY = ay + ah - 6.0f;

        float ax = graphX + aNorm * graphW;
        float dx = ax + dNorm * graphW;
        float rx = graphX + (1.0f - rNorm) * graphW;
        float susY = topY - (topY - botY) * sustain;

        canvas.setColor(kNeonPink);
        canvas.segment(graphX, botY, ax, topY, 1.5f, false);
        canvas.segment(ax, topY, dx, susY, 1.5f, false);
        canvas.segment(dx, susY, rx, susY, 1.5f, false);
        canvas.segment(rx, susY, graphX + graphW, botY, 1.5f, false);

        canvas.setColor(kNeonPurple);
        canvas.text("A", valueFont, visage::Font::kCenter, ax - 10, topY - 14, 20, 12);
        canvas.text("D", valueFont, visage::Font::kCenter, dx - 10, susY - 14, 20, 12);
        canvas.text("S", valueFont, visage::Font::kCenter, rx - 10, susY - 14, 20, 12);
        canvas.text("R", valueFont, visage::Font::kCenter, graphX + graphW - 10, botY + 2, 20, 12);

        canvas.setColor(kNeonCyan);
        canvas.text("ENVELOPE", labelFont, visage::Font::kLeft, graphX, ay + 2, 80, 14);
    }

    void updateFonts()
    {
        const float dpi = std::max(1.0f, dpiScale());
        const auto* fontData = reinterpret_cast<const unsigned char*>(basic_synth_test_BinaryData::LatoRegular_ttf);
        titleFont = visage::Font(16.0f, fontData, basic_synth_test_BinaryData::LatoRegular_ttfSize, dpi);
        sectionFont = visage::Font(11.0f, fontData, basic_synth_test_BinaryData::LatoRegular_ttfSize, dpi);
        labelFont = visage::Font(10.0f, fontData, basic_synth_test_BinaryData::LatoRegular_ttfSize, dpi);
        valueFont = visage::Font(9.0f, fontData, basic_synth_test_BinaryData::LatoRegular_ttfSize, dpi);
    }

    float w = 800.0f, h = 500.0f;
    float secW = 160.0f;
    float waveformH = 56.0f, adsrH = 50.0f;
    float topBarY = 4.0f, waveformY = 24.0f, sectionsY = 88.0f, adsrY = 446.0f;
    float knobSize = 50.0f;
    float paramValues[15] = { 0.75f, 0.5f, 0.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f,
                              0.01f, 0.3f, 0.7f, 0.5f, 0.1f, 0.0f, 0.0f };

    visage::Font titleFont;
    visage::Font sectionFont;
    visage::Font labelFont;
    visage::Font valueFont;
};