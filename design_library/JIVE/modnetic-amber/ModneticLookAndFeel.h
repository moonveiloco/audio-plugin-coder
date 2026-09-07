/*
    ModneticLookAndFeel — APC design library asset (JIVE/modnetic-amber)

    Custom JUCE LookAndFeel reproducing the "Modnetic" reference aesthetic
    for a JIVE-declared UI (JIVE controls placement/sizes/text via markup;
    this class owns the widget CHROME, which JIVE markup cannot style):

      - Knob/rotary: dark grey dial with vertical gradient, thin white
        pointer, amber value arc hugging the rim, amber end-dot, tick-dot
        ring on large dials (>= 90 px).
      - Linear slider: hairline dark track, amber fill from the start,
        small pale thumb (horizontal), round thumb (vertical).
      - TextButton: flat dark chip, subtle border; toggled = brighter.
      - ComboBox: flat dark chip + chevron; dark popup with amber highlight.
      - ToggleButton (Checkbox): small square, amber fill + dark tick.

    Usage in a plugin (after the JIVE bootstrap, e.g. in PluginEditor):

        #include "ModneticLookAndFeel.h"
        ModneticLookAndFeel laf;               // member, outlives the editor
        setLookAndFeel(&laf);                  // Component::setLookAndFeel

    Usage in jive-preview:

        jive-preview layout.xml --laf modnetic [--screenshot out.png]
*/

#pragma once

#include <juce_gui_basics/juce_gui_basics.h>

class ModneticLookAndFeel final : public juce::LookAndFeel_V4
{
public:
    ModneticLookAndFeel()
    {
        setColour(juce::TextButton::buttonColourId, juce::Colour{ 0xff242424 });
        setColour(juce::TextButton::buttonOnColourId, juce::Colour{ 0xff3a3a3a });
        setColour(juce::TextButton::textColourOffId, juce::Colour{ 0xffc8c4b8 });
        setColour(juce::TextButton::textColourOnId, juce::Colour{ 0xfff2efe6 });

        setColour(juce::ComboBox::backgroundColourId, juce::Colour{ 0xff242424 });
        setColour(juce::ComboBox::textColourId, juce::Colour{ 0xffe8e4d8 });
        setColour(juce::ComboBox::arrowColourId, juce::Colour{ 0xff9a968a });
        setColour(juce::ComboBox::outlineColourId, juce::Colour{ 0xff3a3a3a });
        setColour(juce::ComboBox::buttonColourId, juce::Colour{ 0xff242424 });

        setColour(juce::PopupMenu::backgroundColourId, juce::Colour{ 0xff1e1e1e });
        setColour(juce::PopupMenu::textColourId, juce::Colour{ 0xffd8d4c8 });
        setColour(juce::PopupMenu::headerTextColourId, juce::Colour{ 0xff9a968a });
        setColour(juce::PopupMenu::highlightedBackgroundColourId, juce::Colour{ 0xffe8a33d });
        setColour(juce::PopupMenu::highlightedTextColourId, juce::Colour{ 0xff141414 });

        setColour(juce::Label::textColourId, juce::Colour{ 0xffe8e4d8 });
    }

    // ─── Rotary knob ─────────────────────────────────────────────────────
    void drawRotarySlider(juce::Graphics& g,
                          int x, int y, int width, int height,
                          float sliderPosProportional,
                          float rotaryStartAngle,
                          float rotaryEndAngle,
                          juce::Slider&) final
    {
        const auto bounds = juce::Rectangle<float>{ (float) x, (float) y, (float) width, (float) height };
        const auto side = juce::jmin(width, height) * 0.84f;
        const auto dial = bounds.withSizeKeepingCentre(side, side);
        const auto centre = bounds.getCentre();
        const auto dialRadius = dial.getWidth() * 0.5f;
        const auto angle = rotaryStartAngle
                           + sliderPosProportional * (rotaryEndAngle - rotaryStartAngle);

        // Dial: dark grey with a subtle top-lit gradient and rim highlight.
        juce::ColourGradient gradient{ juce::Colour{ 0xff3f3f3f }, centre.x, dial.getY(),
                                       juce::Colour{ 0xff2b2b2b }, centre.x, dial.getBottom(), false };
        g.setGradientFill(gradient);
        g.fillEllipse(dial);
        g.setColour(juce::Colour{ 0xff484848 });
        g.drawEllipse(dial.reduced(0.75f), 1.25f);

        // Amber value arc, hugging the rim just outside the dial.
        const auto arcRadius = dialRadius + 3.5f;
        juce::Path arc;
        arc.addCentredArc(centre.x, centre.y, arcRadius, arcRadius, 0.f,
                          rotaryStartAngle, angle, true);
        g.setColour(accent);
        g.strokePath(arc, juce::PathStrokeType{ 3.25f, juce::PathStrokeType::curved,
                                                juce::PathStrokeType::rounded });

        // Amber dot capping the arc end.
        const auto dotRadius = 2.75f;
        g.fillEllipse(centre.x + std::sin(angle) * arcRadius - dotRadius,
                      centre.y - std::cos(angle) * arcRadius - dotRadius,
                      dotRadius * 2.f, dotRadius * 2.f);

        // Tick-dot ring on large dials (feature knobs such as Repeat).
        if (dialRadius >= 45.f)
        {
            constexpr int tickCount = 11;
            const auto tickRadius = arcRadius + 7.f;
            g.setColour(juce::Colour{ 0xff4a4a4a });

            for (int i = 0; i < tickCount; ++i)
            {
                const auto tickAngle = rotaryStartAngle
                                       + (float) i / (float) (tickCount - 1)
                                         * (rotaryEndAngle - rotaryStartAngle);
                g.fillEllipse(centre.x + std::sin(tickAngle) * tickRadius - 1.25f,
                              centre.y - std::cos(tickAngle) * tickRadius - 1.25f,
                              2.5f, 2.5f);
            }
        }

        // Pointer: thin pale line, from just off-centre to near the rim.
        juce::Line<float> pointer{ centre.x + std::sin(angle) * dialRadius * 0.12f,
                                   centre.y - std::cos(angle) * dialRadius * 0.12f,
                                   centre.x + std::sin(angle) * dialRadius * 0.68f,
                                   centre.y - std::cos(angle) * dialRadius * 0.68f };
        g.setColour(pointerColour);
        g.drawLine(pointer, 2.25f);
    }

    // ─── Linear slider ───────────────────────────────────────────────────
    void drawLinearSlider(juce::Graphics& g,
                          int x, int y, int width, int height,
                          float sliderPos,
                          float /*minSliderPos*/, float /*maxSliderPos*/,
                          const juce::Slider::SliderStyle style,
                          juce::Slider& slider) final
    {
        drawLinearSliderBackgroundAndThumb(g, x, y, width, height, sliderPos, style, slider);
    }

    void drawLinearSliderBackground(juce::Graphics& g,
                                    int x, int y, int width, int height,
                                    float /*sliderPos*/,
                                    float /*minSliderPos*/, float /*maxSliderPos*/,
                                    const juce::Slider::SliderStyle style,
                                    juce::Slider&) final
    {
        const auto trackThickness = 3.f;

        if (style == juce::Slider::LinearHorizontal || style == juce::Slider::LinearBar)
        {
            g.setColour(trackColour);
            g.fillRoundedRectangle((float) x, (float) y + (float) height * 0.5f - trackThickness * 0.5f,
                                   (float) width, trackThickness, trackThickness * 0.5f);
        }
        else
        {
            g.setColour(trackColour);
            g.fillRoundedRectangle((float) x + (float) width * 0.5f - trackThickness * 0.5f,
                                   (float) y, trackThickness, (float) height, trackThickness * 0.5f);
        }
    }

    void drawLinearSliderThumb(juce::Graphics& g,
                               int x, int y, int width, int height,
                               float sliderPos,
                               float /*minSliderPos*/, float /*maxSliderPos*/,
                               const juce::Slider::SliderStyle style,
                               juce::Slider&) final
    {
        if (style == juce::Slider::LinearHorizontal || style == juce::Slider::LinearBar)
        {
            // Amber fill from the start, then the thumb: wide sliders (such as
            // Spread) get the reference's pale vertical bar, narrow ones
            // (Noise/Width) a small round dot.
            g.setColour(accent);
            g.fillRoundedRectangle((float) x, (float) y + (float) height * 0.5f - 1.5f,
                                   sliderPos - (float) x, 3.f, 1.5f);
            g.setColour(thumbColour);

            if (width <= 180)
            {
                g.fillEllipse(sliderPos - 5.f, (float) y + (float) height * 0.5f - 5.f, 10.f, 10.f);
            }
            else
            {
                g.fillRoundedRectangle(sliderPos - 3.5f, (float) y + (float) height * 0.5f - 8.f,
                                       7.f, 16.f, 2.5f);
            }
        }
        else
        {
            // Vertical: sliderPos is a Y coordinate; the thumb is centred on X.
            g.setColour(thumbColour);
            g.fillEllipse((float) x + (float) width * 0.5f - 5.f,
                          sliderPos - 5.f, 10.f, 10.f);
        }
    }

private:
    void drawLinearSliderBackgroundAndThumb(juce::Graphics& g,
                                            int x, int y, int width, int height,
                                            float sliderPos,
                                            const juce::Slider::SliderStyle style,
                                            juce::Slider& slider)
    {
        drawLinearSliderBackground(g, x, y, width, height, sliderPos, 0.f, 1.f, style, slider);
        drawLinearSliderThumb(g, x, y, width, height, sliderPos, 0.f, 1.f, style, slider);
    }

public:
    // ─── Button ──────────────────────────────────────────────────────────
    void drawButtonBackground(juce::Graphics& g,
                              juce::Button& button,
                              const juce::Colour& backgroundColour,
                              bool shouldDrawButtonAsHighlighted,
                              bool shouldDrawButtonAsDown) final
    {
        juce::ignoreUnused(backgroundColour);
        auto bounds = button.getLocalBounds().toFloat().reduced(0.5f);
        const auto base = button.getToggleState()
                              ? juce::Colour{ 0xff383838 }
                              : juce::Colour{ 0xff232323 };
        const auto edge = button.getToggleState()
                              ? juce::Colour{ 0xff525252 }
                              : (shouldDrawButtonAsHighlighted ? juce::Colour{ 0xff454545 }
                                                               : juce::Colour{ 0xff333333 });

        g.setColour(shouldDrawButtonAsDown ? base.brighter(0.08f) : base);
        g.fillRoundedRectangle(bounds, 4.f);
        g.setColour(edge);
        g.drawRoundedRectangle(bounds.reduced(0.5f), 4.f, 1.f);
    }

    // ─── Toggle button (Checkbox) ────────────────────────────────────────
    void drawToggleButton(juce::Graphics& g,
                          juce::ToggleButton& button,
                          bool shouldDrawButtonAsHighlighted,
                          bool /*shouldDrawButtonAsDown*/) final
    {
        const auto boxSize = juce::jmin(15.f, (float) button.getHeight() - 6.f);
        const auto box = juce::Rectangle<float>{ 4.f,
                                                 (float) button.getHeight() * 0.5f - boxSize * 0.5f,
                                                 boxSize, boxSize };

        g.setColour(juce::Colour{ 0xff1e1e1e });
        g.fillRoundedRectangle(box, 3.f);
        g.setColour(shouldDrawButtonAsHighlighted ? juce::Colour{ 0xff6a675f }
                                                  : juce::Colour{ 0xff4a4a4a });
        g.drawRoundedRectangle(box.reduced(0.5f), 3.f, 1.f);

        if (button.getToggleState())
        {
            g.setColour(accent);
            g.fillRoundedRectangle(box.reduced(1.5f), 2.f);
        }
    }

    // ─── ComboBox ────────────────────────────────────────────────────────
    void drawComboBox(juce::Graphics& g,
                      int width, int height,
                      bool /*isButtonDown*/,
                      int /*buttonWidth*/, int /*buttonHeight*/,
                      int /*textX*/, int /*textY*/,
                      juce::ComboBox& box) final
    {
        auto bounds = juce::Rectangle<float>{ 0.5f, 0.5f, (float) width - 1.f, (float) height - 1.f };
        const auto corner = juce::jmin(4.f, bounds.getHeight() * 0.25f);

        g.setColour(box.findColour(juce::ComboBox::backgroundColourId));
        g.fillRoundedRectangle(bounds, corner);
        g.setColour(box.findColour(juce::ComboBox::outlineColourId));
        g.drawRoundedRectangle(bounds.reduced(0.5f), corner, 1.f);

        // Chevron.
        const auto chevronSize = juce::jmin(9.f, (float) height * 0.32f);
        const auto chevronX = (float) width - chevronSize - 11.f;
        const auto chevronY = (float) height * 0.5f;
        juce::Path chevron;
        chevron.addTriangle(chevronX, chevronY - chevronSize * 0.3f,
                            chevronX + chevronSize, chevronY - chevronSize * 0.3f,
                            chevronX + chevronSize * 0.5f, chevronY + chevronSize * 0.45f);
        g.setColour(box.findColour(juce::ComboBox::arrowColourId));
        g.fillPath(chevron);
    }

    juce::Font getComboBoxFont(juce::ComboBox&) final
    {
        return juce::Font{ juce::FontOptions{ 12.5f } };
    }

    juce::Font getPopupMenuFont() final
    {
        return juce::Font{ juce::FontOptions{ 12.5f } };
    }

private:
    static inline const juce::Colour accent{ 0xffe8a33d };
    static inline const juce::Colour trackColour{ 0xff2e2e2e };
    static inline const juce::Colour thumbColour{ 0xffe8e4d8 };
    static inline const juce::Colour pointerColour{ 0xfff2efe6 };

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(ModneticLookAndFeel)
};
