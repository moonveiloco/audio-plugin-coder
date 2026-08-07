# WebView Known Issues & Solutions
**Comprehensive guide for future AI developers**

**Last Updated:** 2026-01-26
**Based On:** CloudWash Plugin Development

---

## 🚨 Critical Issues (Must Know)

### 1. ES6 Modules Don't Work
**Severity:** CRITICAL
**Issue ID:** webview-008

**Problem:**
```html
<!-- ❌ THIS FAILS SILENTLY -->
<script type="module" src="js/index.js"></script>
```

**Symptoms:**
- Knobs show only dots (no arcs)
- No animations
- No interactivity
- CORS errors in browser tests

**Solution:**
ALL JavaScript must be inline in index.html (900+ lines typical).

**Reference:**
- `.kilocode/troubleshooting/resolutions/webview-es6-modules-fail.md`
- `.kilocode/skills/skill_design_webview/WEBVIEW-PRODUCTION-GUIDE.md`
- Working example: `examples/CloudWash/Source/ui/public/index.html`

---

### 2. Member Declaration Order
**Severity:** CRITICAL
**Issue ID:** webview-002

**Problem:**
Wrong order causes DAW crashes on plugin unload.

**Correct Order (PluginEditor.h):**
```cpp
private:
    // 1. Relays FIRST (destroyed last)
    juce::WebSliderRelay gainRelay { "gain" };

    // 2. WebView SECOND (destroyed middle)
    std::unique_ptr<juce::WebBrowserComponent> webView;

    // 3. Attachments LAST (destroyed first)
    std::unique_ptr<juce::WebSliderParameterAttachment> gainAttachment;
```

**Reference:**
- `.kilocode/troubleshooting/resolutions/webview-member-order-crash.md`

---

### 3. JUCE 9 API Changes
**Severity:** HIGH
**Issue ID:** webview-005, webview-006

**Changes:**
1. `withUserDataFolder()` moved to nested class
2. `Resource` uses `std::vector<std::byte>` not `MemoryBlock`

**Correct JUCE 9 Pattern:**
```cpp
webView = std::make_unique<juce::WebBrowserComponent>(
    juce::WebBrowserComponent::Options{}
        .withBackend(juce::WebBrowserComponent::Options::Backend::webview2)
        .withWinWebView2Options(
            juce::WebBrowserComponent::Options::WinWebView2{}
                .withUserDataFolder(juce::File::getSpecialLocation(...))
        )
        .withNativeIntegrationEnabled()
);
```

**Reference:**
- `.kilocode/troubleshooting/resolutions/webview-juce8-api-changes.md`

---

## ⚠️ Common Issues

### 4. Knob Rendering Glitches
**Severity:** MEDIUM

**Problem:**
Knobs appear jumpy/glitchy when dragging.

**Cause:**
CSS transitions on SVG paths.

**Solution:**
```css
.knob-arc {
    /* NO transition - causes glitches */
    transition: none;
}
```

**Status:** FIXED in CloudWash (2026-01-26)

---

### 5. Meters Show Random Values
**Severity:** MEDIUM

**Problem:**
Meters animated with `Math.random()` instead of real audio levels.

**Cause:**
No connection between C++ audio processing and JavaScript meters.

**Solution:**
See "Audio Meter Connection" section in `WEBVIEW-PRODUCTION-GUIDE.md`.

**Quick Fix:**
1. Add `std::atomic<float> inputPeak` in PluginProcessor
2. Update in processBlock()
3. Send to WebView via Timer callback
4. Call `window.updateMeters(inputLevel, outputLevel)` from C++

**Status:** Documented in CloudWash (implementation pending)

---

### 6. Parameters Have No Effect on Audio
**Severity:** MEDIUM

**Problem:**
Some knobs move but don't affect audio processing.

**Cause:**
DSP not implemented for that parameter in PluginProcessor::processBlock().

**Diagnosis:**
1. Check PluginProcessor.cpp
2. Find parameter: `apvts.getRawParameterValue("param_name")`
3. Verify it's used in audio processing

**Solution:**
Implement DSP for that parameter.

**Example (CloudWash):**
- Mode 0 (Granular): ✅ Fully implemented
- Modes 1-3: ⚠️ Placeholders (awaiting Phase 4.1.2)

---

### 7. BinaryData Resource Loading
**Severity:** HIGH
**Issue ID:** webview-007

**Problem:**
Plugin shows black screen - resources not loading.

**Cause:**
Resource provider tries to load from file system instead of embedded BinaryData.

**Solution:**
```cpp
std::optional<WebBrowserComponent::Resource> getResource(const String& url)
{
    // Map URL to BinaryData variable
    if (path == "index.html")
    {
        resourceData = BinaryData::index_html;
        resourceSize = BinaryData::index_htmlSize;
        mimeType = "text/html";
    }

    // Convert to std::vector<std::byte>
    std::vector<std::byte> data(resourceSize);
    std::memcpy(data.data(), resourceData, resourceSize);

    return WebBrowserComponent::Resource{ std::move(data), mimeType };
}
```

**Reference:**
- `.kilocode/troubleshooting/resolutions/webview-black-screen-resources.md`

---

## 📋 Development Checklist

### Before Building Plugin

- [ ] ALL JavaScript is inline in index.html
- [ ] No `<script type="module">` tags
- [ ] No `import` / `export` statements
- [ ] test-local.html created and tested in browser
- [ ] All knobs render with arcs in browser test
- [ ] No CORS errors in browser console

### C++ Side

- [ ] Member order: Relays → WebView → Attachments
- [ ] JUCE 9 API used (WinWebView2 nested class)
- [ ] Resource provider returns embedded BinaryData
- [ ] All relays registered with `.withOptionsFrom()`

### JavaScript Side

- [ ] JUCE library inlined (~500 lines)
- [ ] UI code inlined (~400 lines)
- [ ] `juceAvailable` check before JUCE calls
- [ ] Try/catch around all JUCE API calls
- [ ] No CSS transitions on `.knob-arc`
- [ ] `setNormalisedValue()` used (not `setValue()`)
- [ ] `sliderDragStarted/Ended()` called

### CMakeLists.txt

```cmake
juce_add_binary_data(YourPlugin_WebUI
    SOURCES
        Source/ui/public/index.html  # ONLY HTML!
)

juce_add_plugin(YourPlugin
    NEEDS_WEBVIEW2 TRUE
    # ...
)

target_compile_definitions(YourPlugin
    PUBLIC
        JUCE_WEB_BROWSER=1
        JUCE_USE_WIN_WEBVIEW2_WITH_STATIC_LINKING=1
)
```

---

## 🔍 Debugging Steps

### Issue: UI Doesn't Load At All

1. **Check browser test first:**
   ```bash
   # Open test-local.html in Chrome/Edge
   $APC_PLUGINS_DIR/YourPlugin/Source/ui/public/test-local.html
   ```

2. **Look for ES6 module errors:**
   - Open browser console (F12)
   - Look for: "Cross-Origin Request blocked"
   - If found → ES6 modules issue (webview-008)

3. **Check resource provider:**
   - Verify BinaryData.h exists in build folder
   - Check getResource() maps URLs correctly
   - Verify MIME types

### Issue: Knobs Don't Render

1. **Check browser test:**
   - If works in browser → BinaryData issue
   - If fails in browser → JavaScript error

2. **Check console:**
   ```javascript
   // Should see:
   "Initializing 10 knobs..."
   "  ✓ Knob: position"
   // ... all 10 knobs
   ```

3. **Check SVG paths:**
   - Use browser inspector
   - Look at `<path class="knob-arc">`
   - Should have `d="M x y A ..."` attribute

### Issue: Parameters Don't Sync

1. **Check parameter IDs match:**
   ```cpp
   // C++
   juce::WebSliderRelay positionRelay { "position" };
   ```
   ```javascript
   // JavaScript
   const state = Juce.getSliderState("position");
   ```

2. **Check attachment creation:**
   ```cpp
   // AFTER webView creation
   positionAttachment = std::make_unique<WebSliderParameterAttachment>(
       *apvts.getParameter("position"),
       positionRelay,
       nullptr
   );
   ```

3. **Check JUCE console warnings:**
   - "Creating SliderState for 'position', which is unknown to the backend"
   - Means parameter ID mismatch

---

## 📚 Documentation Locations

### Skills
- **`.kilocode/skills/skill_design_webview/SKILL.md`**
  - Quick-start guide (may be outdated)

- **`.kilocode/skills/skill_design_webview/WEBVIEW-PRODUCTION-GUIDE.md`** ⭐
  - COMPLETE production guide
  - Use this for all new plugins
  - Based on CloudWash development

- **`.kilocode/skills/skill_design_webview/KNOWN-ISSUES-AND-SOLUTIONS.md`** ⭐
  - This file
  - Quick reference for common issues

### Troubleshooting
- **`.kilocode/troubleshooting/known-issues.yaml`**
  - Database of all known issues
  - Searchable by ID, category, symptoms

- **`.kilocode/troubleshooting/resolutions/`**
  - Detailed resolution documents
  - webview-001 through webview-008

### Working Examples
- **`examples/CloudWash/Source/ui/public/index.html`** ⭐
  - 978 lines, 34KB
  - COMPLETE working implementation
  - Use as template for all new plugins

- **`examples/AngelGrain/`**
  - Another working WebView plugin
  - Simpler than CloudWash

---

## 🎯 Quick Start for New Plugin

### 1. Copy CloudWash Template
```powershell
# Copy working implementation
cp examples/CloudWash/Source/ui/public/index.html $APC_PLUGINS_DIR/YourPlugin/Source/ui/public/
```

### 2. Modify for Your Plugin
1. Change title: "CLOUDWASH" → "YOUR PLUGIN"
2. Update parameter names in HTML data attributes
3. Update JavaScript parameter list
4. Modify knob labels, defaults, ranges
5. Adjust layout/styling

### 3. Test in Browser
```bash
# Save as test-local.html and open in browser
$APC_PLUGINS_DIR/YourPlugin/Source/ui/public/test-local.html
```

### 4. Update C++ Side
1. PluginEditor.h: Add relays for all parameters
2. PluginEditor.cpp: Register relays with `.withOptionsFrom()`
3. Create attachments (correct order!)

### 5. Build & Test
```powershell
.\scripts\build-and-install.ps1 -PluginName YourPlugin
```

---

## ⚡ Performance Tips

### Knob Rendering
- ✅ DO: Remove CSS transitions
- ✅ DO: Use `e.preventDefault()` on mousedown
- ❌ DON'T: Recalculate SVG paths unnecessarily

### Meter Updates
- ✅ DO: Use Timer at 30 FPS
- ✅ DO: Use `std::atomic` for thread safety
- ❌ DON'T: Call from processBlock() (too frequent)

### Memory
- ✅ DO: Embed all resources in BinaryData
- ✅ DO: Use inline JavaScript (single file)
- ❌ DON'T: Load external files at runtime

---

## 🔗 Related Files

### Must Read
1. **WEBVIEW-PRODUCTION-GUIDE.md** - Complete development guide
2. **webview-es6-modules-fail.md** - #1 issue explanation
3. **CloudWash index.html** - Working reference implementation

### Optional Reading
- webview-member-order-crash.md
- webview-juce8-api-changes.md
- webview-black-screen-resources.md

---

## 📝 Notes for AI Developers

### When User Reports WebView Issue

1. **First, check this file** for known solutions
2. **Then, search** `.kilocode/troubleshooting/known-issues.yaml`
3. **If found**, apply documented solution
4. **If new issue:**
   - After 3 attempts, trigger auto-capture
   - Document in known-issues.yaml
   - Create resolution document

### When Building New WebView Plugin

1. **Start with CloudWash template** (don't start from scratch)
2. **Test in browser first** (saves build cycles)
3. **Follow production checklist** (see above)
4. **Reference WEBVIEW-PRODUCTION-GUIDE.md** for details

### When User Says "GUI Not Working"

Ask clarifying questions:
- "Does it show in browser test (test-local.html)?"
- "Are knobs visible? Do they have arcs or just dots?"
- "Any console errors? (F12 in browser)"
- "Which controls specifically don't work?"

Then diagnose using "Debugging Steps" section above.

---

**Document Maintainer:** AI Assistant
**Status:** Living Document
**Updates:** Add new issues as discovered
**Version:** 1.0 (2026-01-26)
