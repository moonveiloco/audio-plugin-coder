/**
 * basic_synth_webview - UI Controller
 * Connects HTML knobs/dropdowns to JUCE native parameter relays.
 */
(function () {
  "use strict";

  // ─── KNOB SETUP ───
  document.querySelectorAll(".knob").forEach(function (knob) {
    var input = knob.querySelector("input[type=range]");
    var paramId = knob.dataset.param;
    var valueEl = document.getElementById("val-" + paramId);
    var arcEl = document.getElementById("arc-" + paramId);
    var svg = knob.querySelector("svg");
    var ind = svg ? svg.querySelector(".knob-ind") : null;

    if (!input || !valueEl || !arcEl) return;

    // Get SVG center
    var cx = 20,
        cy = 20;
    if (svg) {
      var vb = svg.getAttribute("viewBox").split(/\s+/).map(Number);
      if (vb.length === 4) { cx = vb[0] + vb[2] / 2; cy = vb[1] + vb[3] / 2; }
    }
    var r = parseFloat(arcEl.getAttribute("r"));
    var circ = 2 * Math.PI * r;

    // Connect to JUCE backend (may be unavailable in standalone preview)
    var sliderState = null;
    try { sliderState = getSliderState(paramId); } catch (e) {}

    function updateVisuals() {
      var v = parseFloat(input.value);
      var min = parseFloat(input.min);
      var max = parseFloat(input.max);
      var pct = Math.max(0, Math.min(1, (v - min) / (max - min)));

      // Arc fill (270° sweep)
      arcEl.style.strokeDashoffset = circ * (1 - pct * 0.75);

      // Indicator rotation
      if (ind) {
        var angle = (pct - 1) * 270;
        ind.setAttribute("transform", "rotate(" + angle + ", " + cx + ", " + cy + ")");
      }

      // Format display
      if (paramId === "filter_cutoff") {
        if (v >= 1000) valueEl.textContent = (v / 1000).toFixed(1) + "k";
        else if (v >= 100) valueEl.textContent = Math.round(v) + "";
        else valueEl.textContent = Math.round(v) + "";
      } else if (input.step.indexOf(".") === -1 || input.step === "1") {
        valueEl.textContent = Math.round(v) + "";
      } else {
        valueEl.textContent = v.toFixed(2);
      }
    }

    // Sync from JUCE backend
    if (sliderState) {
      sliderState.valueChangedEvent.addListener(function () {
        // Backend changed the value - update our input to match
        var sv = sliderState.getScaledValue();
        if (sv !== parseFloat(input.value)) {
          input.value = sv;
          updateVisuals();
        }
      });
      // Set initial value from backend
      var initial = sliderState.getScaledValue();
      if (!isNaN(initial) && initial !== parseFloat(input.value)) {
        input.value = initial;
      }
    }

    // Initial visual update
    updateVisuals();

    // Event handlers
    var isDragging = false;

    input.addEventListener("input", function () {
      updateVisuals();
      if (sliderState && isDragging) {
        var v = parseFloat(input.value);
        var min = parseFloat(input.min);
        var max = parseFloat(input.max);
        var pct = (v - min) / (max - min);
        sliderState.setNormalisedValue(pct);
      }
    });

    input.addEventListener("mousedown", function () {
      isDragging = true;
      if (sliderState) sliderState.sliderDragStarted();
    });

    input.addEventListener("mouseup", function () {
      isDragging = false;
      if (sliderState) {
        sliderState.sliderDragEnded();
        // Ensure final value is sent
        var v = parseFloat(input.value);
        var min = parseFloat(input.min);
        var max = parseFloat(input.max);
        var pct = (v - min) / (max - min);
        sliderState.setNormalisedValue(pct);
      }
    });
  });

  // ─── DROPDOWN SETUP ───
  document.querySelectorAll(".dropdown").forEach(function (drop) {
    var paramId = drop.dataset.param;
    var select = drop.querySelector(".dropdown-select");
    var options = drop.querySelectorAll(".dropdown-option");
    var display = drop.querySelector(".dropdown-display");
    var optsEl = drop.querySelector(".dropdown-options");

    // Connect to JUCE backend
    var comboState = null;
    try { comboState = getComboBoxState(paramId); } catch (e) {}

    // Sync from JUCE backend
    if (comboState) {
      comboState.valueChangedEvent.addListener(function () {
        var idx = comboState.getChoiceIndex();
        options.forEach(function (o, i) {
          o.classList.toggle("active", i === idx);
        });
        if (options[idx]) {
          display.textContent = options[idx].textContent;
        }
      });
    }

    // Set initial value from backend
    if (comboState) {
      var initialIdx = comboState.getChoiceIndex();
      if (options[initialIdx]) {
        options.forEach(function (o) { o.classList.remove("active"); });
        options[initialIdx].classList.add("active");
        if (display) display.textContent = options[initialIdx].textContent;
      }
    }

    // Toggle dropdown
    select.addEventListener("click", function (e) {
      e.stopPropagation();
      var isOpen = optsEl.classList.contains("open");
      // Close all other dropdowns
      document.querySelectorAll(".dropdown-options.open").forEach(function (el) {
        el.classList.remove("open");
      });
      optsEl.classList.toggle("open");
    });

    // Select option
    options.forEach(function (opt, idx) {
      opt.addEventListener("click", function (e) {
        e.stopPropagation();
        options.forEach(function (o) { o.classList.remove("active"); });
        opt.classList.add("active");
        if (display) display.textContent = opt.textContent;
        optsEl.classList.remove("open");

        if (comboState) {
          comboState.setChoiceIndex(idx);
        }
      });
    });
  });

  // ─── CLOSE ALL DROPDOWNS ───
  document.addEventListener("click", function () {
    document.querySelectorAll(".dropdown-options.open").forEach(function (el) {
      el.classList.remove("open");
    });
  });

})();
