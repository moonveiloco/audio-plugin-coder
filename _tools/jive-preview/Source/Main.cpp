/*
    jive-preview — APC preview tool for JIVE markup files.

    Renders a JIVE XML markup file in a native window. Watches the file
    and re-interprets it on every change (live reload).

    Usage:
        jive-preview <file.xml> [--width N] [--height N]

    Notes:
        - The markup root <Window> is rewritten to <Component> before
          interpretation: the tool provides its own host DocumentWindow so
          the native close button quits the app (jive's own Window item
          does not wire closeButtonPressed).
        - Width/height default to the markup root attributes, overridable
          via CLI flags.
        - A failed re-load (mid-save parse error, bad property, ...) keeps
          the last good UI on screen and reports the problem on stderr.
*/

#include <juce_gui_basics/juce_gui_basics.h>

#include <jive_layouts/jive_layouts.h>


namespace
{
    constexpr auto fallbackBackground = 0xff16181d;
    constexpr int defaultWidth = 640;
    constexpr int defaultHeight = 420;
    constexpr int pollIntervalMs = 500;
    constexpr const char* windowTag = "Window";
    constexpr const char* hostTag = "Component";
    constexpr const char* separator = " \xE2\x80\x94 jive-preview"; // em-dash

    struct Spec
    {
        juce::File file;
        juce::File screenshotOut;
        int width = 0;
        int height = 0;
        bool raw = false;
    };

    [[nodiscard]] juce::File resolvePath(const juce::String& raw)
    {
        auto expanded = raw;

        if (expanded.startsWith("~"))
            expanded = juce::File::getSpecialLocation(juce::File::userHomeDirectory).getFullPathName()
                       + expanded.fromFirstOccurrenceOf("~", false, false);

        auto file = juce::File::getCurrentWorkingDirectory().getChildFile(expanded);

        if (file.existsAsFile())
            return file;

        return {};
    }

    [[nodiscard]] std::optional<Spec> parseSpec(const juce::StringArray& args)
    {
        Spec spec;

        for (auto i = 0; i < args.size(); ++i)
        {
            const auto& token = args[i];

            if (token == "--width" && i + 1 < args.size())
            {
                spec.width = args[++i].getIntValue();
            }
            else if (token == "--height" && i + 1 < args.size())
            {
                spec.height = args[++i].getIntValue();
            }
            else if (token == "--help" || token == "-h")
            {
                return std::nullopt;
            }
            else if (token == "--raw")
            {
                spec.raw = true;
            }
            else if (token == "--screenshot" && i + 1 < args.size())
            {
                spec.screenshotOut = juce::File::getCurrentWorkingDirectory().getChildFile(args[++i]);
            }
            else if (!token.startsWith("-") && spec.file == juce::File{})
            {
                spec.file = resolvePath(token);
            }
        }

        if (spec.file == juce::File{})
            return std::nullopt;

        return spec;
    }

    [[nodiscard]] juce::String usageText()
    {
        return "Usage: jive-preview <file.xml> [--width N] [--height N] [--screenshot out.png] [--raw]\n"
               "Renders a JIVE XML markup file and live-reloads it on change.\n"
               "--screenshot renders off-screen once to out.png and exits (headless/CI friendly).\n";
    }

    // Extracts window size / title from the markup root and rewrites the
    // root tag so interpretation yields a plain content component instead
    // of a second, nested DocumentWindow.
    void prepareRoot(juce::XmlElement& root, const Spec& spec, juce::String& title, int& width, int& height)
    {
        const auto isWindowRoot = root.getTagName() == windowTag;

        if (spec.width > 0)
            width = spec.width;
        else
            width = root.getIntAttribute("width", defaultWidth);

        if (spec.height > 0)
            height = spec.height;
        else
            height = root.getIntAttribute("height", defaultHeight);

        title = root.getStringAttribute("name", {});

        if (title.isEmpty())
            title = "jive-preview";

        if (isWindowRoot)
            root.setTagName(hostTag);

        if (spec.width > 0)
            root.setAttribute("width", spec.width);

        if (spec.height > 0)
            root.setAttribute("height", spec.height);
    }
} // namespace

class JivePreviewApplication final : public juce::JUCEApplication,
                                     private juce::Timer
{
public:
    JivePreviewApplication() = default;

    const juce::String getApplicationName() final
    {
        return JUCE_APPLICATION_NAME;
    }

    const juce::String getApplicationVersion() final
    {
        return JUCE_APPLICATION_VERSION;
    }

    bool moreThanOneInstanceAllowed() final
    {
        return true;
    }

    void initialise(const juce::String&) final
    {
        const auto spec = parseSpec(JUCEApplicationBase::getCommandLineParameterArray());

        if (!spec.has_value())
        {
            std::cerr << usageText().toRawUTF8();
            quit();
            return;
        }

        host = std::make_unique<HostWindow>();
        currentSpec = *spec;

        if (currentSpec.screenshotOut != juce::File{})
        {
            const auto ok = renderScreenshot(currentSpec);
            quit();
            return;
        }

        if (!loadAndShow(currentSpec.file))
        {
            quit();
            return;
        }

        lastModified = currentSpec.file.getLastModificationTime();
        startTimer(pollIntervalMs);
    }

    void shutdown() final
    {
        stopTimer();
        currentItem = nullptr;
        host = nullptr;
    }

    void timerCallback() final
    {
        if (!currentSpec.file.existsAsFile())
            return;

        const auto modified = currentSpec.file.getLastModificationTime();

        if (modified == lastModified)
            return;

        lastModified = modified;

        if (!loadAndShow(currentSpec.file))
            std::cerr << "jive-preview: kept last good UI (load failed)\n";
    }

private:
    class HostWindow final : public juce::DocumentWindow
    {
    public:
        HostWindow()
            : juce::DocumentWindow("jive-preview",
                                   juce::Colour{ fallbackBackground },
                                   juce::DocumentWindow::allButtons)
        {
            setUsingNativeTitleBar(true);
        }

        void closeButtonPressed() final
        {
            juce::JUCEApplicationBase::quit();
        }

        JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(HostWindow)
    };

    // Off-screen render: interpret the markup, paint the resulting component
    // tree into an image at the requested size and save it as PNG. No window
    // is created, so tiling window managers cannot alter the geometry.
    bool renderScreenshot(const Spec& spec)
    {
        if (!spec.file.existsAsFile())
            return screenshotFail(spec, "File not found: " + spec.file.getFullPathName());

        auto xml = juce::parseXML(spec.file);

        if (xml == nullptr)
            return screenshotFail(spec, "Cannot parse XML: " + spec.file.getFullPathName());

        juce::String title;
        int width = defaultWidth;
        int height = defaultHeight;
        prepareRoot(*xml, spec, title, width, height);

        try
        {
            auto item = interpreter.interpret(*xml);

            if (item == nullptr || item->getComponent() == nullptr)
                return screenshotFail(spec, "Interpreter produced no component");

            auto& component = *item->getComponent();

            // Let jive flush its deferred property/layout updates before
            // grabbing the snapshot: the first pass of message dispatching
            // settles the tree, then the snapshot runs on the message thread.
            juce::MessageManager::callAsync([this, &component, &item, width, height]
                                            {
                                                screenshotSucceeded =
                                                    writeSnapshot(component, item, width, height);
                                                juce::JUCEApplicationBase::quit();
                                            });
            juce::MessageManager::getInstance()->runDispatchLoop();
            return screenshotSucceeded;
        }
        catch (const std::exception& err)
        {
            return screenshotFail(spec, juce::String("Interpretation failed: ") + err.what());
        }
        catch (...)
        {
            return screenshotFail(spec, "Interpretation failed with an unknown error");
        }
    }

    bool writeSnapshot(juce::Component& component,
                       std::unique_ptr<jive::GuiItem>& /*item*/,
                       int width,
                       int height)
    {
        const auto spec = currentSpec;
        const auto snapshot = component.createComponentSnapshot({ width, height }, false);

        if (snapshot.isNull())
            return screenshotFail(spec, "Snapshot rendering failed");

        juce::FileOutputStream stream(spec.screenshotOut);

        if (!stream.openedOk())
            return screenshotFail(spec, "Cannot write: " + spec.screenshotOut.getFullPathName());

        juce::PNGImageFormat png;

        if (!png.writeImageToStream(snapshot, stream))
            return screenshotFail(spec, "PNG encoding failed");

        stream.flush();
        std::cerr << "jive-preview: wrote " << spec.screenshotOut.getFullPathName()
                  << " (" << width << "x" << height << ")\n";
        return true;
    }

    [[nodiscard]] static bool screenshotFail(const Spec& /*spec*/, const juce::String& message)
    {
        std::cerr << "jive-preview: " << message << "\n";
        return false;
    }

    // Returns true when the screen is showing a valid UI. A first load that
    // fails returns false (the app then quits); a failed reload keeps the
    // last good content and still returns true if something was showing.
    [[nodiscard]] bool loadAndShow(const juce::File& file)
    {
        if (!file.existsAsFile())
            return fail("File not found: " + file.getFullPathName());

        auto xml = juce::parseXML(file);

        if (xml == nullptr)
            return fail("Cannot parse XML: " + file.getFullPathName());

        int width = defaultWidth;
        int height = defaultHeight;
        juce::String title;

        if (currentSpec.raw)
        {
            // Demo-runner pattern: interpret the markup untouched and let
            // jive's own Window item manage the top-level window.
            try
            {
                auto item = interpreter.interpret(xml->toString());

                if (item == nullptr || item->getComponent() == nullptr)
                    return fail("Interpreter produced no component");

                currentItem = std::move(item);
                showingUi = true;
                return true;
            }
            catch (const std::exception& err)
            {
                return fail(juce::String("Interpretation failed: ") + err.what());
            }
        }

        prepareRoot(*xml, currentSpec, title, width, height);

        try
        {
            auto item = interpreter.interpret(*xml);

            if (item == nullptr || item->getComponent() == nullptr)
                return fail("Interpreter produced no component");

            host->setName(title + separator);
            host->setContentNonOwned(item->getComponent().get(), true);
            host->setVisible(true);

            currentItem = std::move(item);
            showingUi = true;
            lastError.clear();
            return true;
        }
        catch (const std::exception& err)
        {
            return fail(juce::String("Interpretation failed: ") + err.what());
        }
        catch (...)
        {
            return fail("Interpretation failed with an unknown error");
        }
    }

    [[nodiscard]] bool fail(const juce::String& message)
    {
        lastError = message;
        std::cerr << "jive-preview: " << message << "\n";

        if (!showingUi)
        {
            juce::AlertWindow::showMessageBoxAsync(juce::MessageBoxIconType::WarningIcon,
                                                   "jive-preview",
                                                   message + "\n\n" + usageText(),
                                                   "OK");
        }

        return showingUi;
    }

    jive::Interpreter interpreter;
    std::unique_ptr<jive::GuiItem> currentItem;
    std::unique_ptr<HostWindow> host;
    juce::Time lastModified;
    Spec currentSpec;
    juce::String lastError;
    bool showingUi = false;
    bool screenshotSucceeded = false;

    JUCE_DECLARE_NON_COPYABLE_WITH_LEAK_DETECTOR(JivePreviewApplication)
};

START_JUCE_APPLICATION(JivePreviewApplication)
