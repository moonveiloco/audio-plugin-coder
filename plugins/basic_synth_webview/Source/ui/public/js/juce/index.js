/*
  Combined JUCE frontend library for WebView integration.
  Merged from check_native_interop.js + index.js (no ES module imports).
*/

(function() {
  "use strict";

  // ─── Native interop check ───
  if (typeof window.__JUCE__ === "undefined") {
    console.warn("window.__JUCE__ is undefined. Native integration features will not work.");
    window.__JUCE__ = { postMessage: function() {} };
  }

  if (typeof window.__JUCE__.initialisationData === "undefined") {
    window.__JUCE__.initialisationData = {
      __juce__platform: [],
      __juce__functions: [],
      __juce__registeredGlobalEventIds: [],
      __juce__sliders: [],
      __juce__toggles: [],
      __juce__comboBoxes: [],
    };
  }

  class ListenerList {
    constructor() {
      this.listeners = new Map();
      this.listenerId = 0;
    }
    addListener(fn) {
      const id = this.listenerId++;
      this.listeners.set(id, fn);
      return id;
    }
    removeListener(id) {
      this.listeners.delete(id);
    }
    callListeners(payload) {
      for (const [, fn] of this.listeners) fn(payload);
    }
  }

  class EventListenerList {
    constructor() { this.eventListeners = new Map(); }
    addEventListener(eventId, fn) {
      if (!this.eventListeners.has(eventId))
        this.eventListeners.set(eventId, new ListenerList());
      return this.eventListeners.get(eventId).addListener(fn);
    }
    removeEventListener([eventId, id]) {
      if (this.eventListeners.has(eventId))
        this.eventListeners.get(eventId).removeListener(id);
    }
    emitEvent(eventId, object) {
      if (this.eventListeners.has(eventId))
        this.eventListeners.get(eventId).callListeners(object);
    }
  }

  class Backend {
    constructor() { this.listeners = new EventListenerList(); }
    addEventListener(eventId, fn) { return this.listeners.addEventListener(eventId, fn); }
    removeEventListener([eventId, id]) { this.listeners.removeEventListener([eventId, id]); }
    emitEvent(eventId, object) {
      window.__JUCE__.postMessage(JSON.stringify({ eventId: eventId, payload: object }));
    }
    emitByBackend(eventId, object) {
      this.listeners.emitEvent(eventId, JSON.parse(object));
    }
  }

  if (typeof window.__JUCE__.backend === "undefined")
    window.__JUCE__.backend = new Backend();

  // ─── Promise Handler ───
  class PromiseHandler {
    constructor() {
      this.lastPromiseId = 0;
      this.promises = new Map();
      window.__JUCE__.backend.addEventListener("__juce__complete", ({ promiseId, result }) => {
        if (this.promises.has(promiseId)) {
          this.promises.get(promiseId).resolve(result);
          this.promises.delete(promiseId);
        }
      });
    }
    createPromise() {
      const promiseId = this.lastPromiseId++;
      const result = new Promise((resolve, reject) => {
        this.promises.set(promiseId, { resolve, reject });
      });
      return [promiseId, result];
    }
  }

  const promiseHandler = new PromiseHandler();

  // ─── Native function bridge ───
  function getNativeFunction(name) {
    if (!window.__JUCE__.initialisationData.__juce__functions.includes(name))
      console.warn("Creating native function binding for '" + name + "', unknown to backend");
    return function() {
      const [promiseId, result] = promiseHandler.createPromise();
      window.__JUCE__.backend.emitEvent("__juce__invoke", {
        name: name,
        params: Array.prototype.slice.call(arguments),
        resultId: promiseId,
      });
      return result;
    };
  }

  // ─── Event ID constants ───
  const valueChangedEventId = "valueChanged";
  const propertiesChangedId = "propertiesChanged";
  const sliderDragStartedEventId = "sliderDragStarted";
  const sliderDragEndedEventId = "sliderDragEnded";

  // ─── SliderState ───
  class SliderState {
    constructor(name) {
      if (!window.__JUCE__.initialisationData.__juce__sliders.includes(name))
        console.warn("Creating SliderState for '" + name + "', unknown to backend");
      this.name = name;
      this.identifier = "__juce__slider" + this.name;
      this.scaledValue = 0;
      this.properties = { start: 0, end: 1, skew: 1, name: "", label: "", numSteps: 100, interval: 0, parameterIndex: -1 };
      this.valueChangedEvent = new ListenerList();
      this.propertiesChangedEvent = new ListenerList();
      window.__JUCE__.backend.addEventListener(this.identifier, (event) => this.handleEvent(event));
      window.__JUCE__.backend.emitEvent(this.identifier, { eventType: "requestInitialUpdate" });
    }
    setNormalisedValue(newValue) {
      this.scaledValue = this.snapToLegalValue(this.normalisedToScaledValue(newValue));
      window.__JUCE__.backend.emitEvent(this.identifier, { eventType: valueChangedEventId, value: this.scaledValue });
    }
    sliderDragStarted() {
      window.__JUCE__.backend.emitEvent(this.identifier, { eventType: sliderDragStartedEventId });
    }
    sliderDragEnded() {
      window.__JUCE__.backend.emitEvent(this.identifier, { eventType: sliderDragEndedEventId });
    }
    handleEvent(event) {
      if (event.eventType === valueChangedEventId) {
        this.scaledValue = event.value;
        this.valueChangedEvent.callListeners();
      }
      if (event.eventType === propertiesChangedId) {
        const { eventType: _, ...rest } = event;
        this.properties = rest;
        this.propertiesChangedEvent.callListeners();
      }
    }
    getScaledValue() { return this.scaledValue; }
    getNormalisedValue() {
      return Math.pow(
        (this.scaledValue - this.properties.start) / (this.properties.end - this.properties.start),
        this.properties.skew
      );
    }
    normalisedToScaledValue(normalisedValue) {
      return Math.pow(normalisedValue, 1 / this.properties.skew) *
        (this.properties.end - this.properties.start) + this.properties.start;
    }
    snapToLegalValue(value) {
      const interval = this.properties.interval;
      if (interval === 0) return value;
      const start = this.properties.start;
      const clamp = (val, min, max) => Math.max(min, Math.min(max, val));
      return clamp(
        start + interval * Math.floor((value - start) / interval + 0.5),
        this.properties.start,
        this.properties.end
      );
    }
  }

  const sliderStates = new Map();
  for (const name of window.__JUCE__.initialisationData.__juce__sliders)
    sliderStates.set(name, new SliderState(name));

  function getSliderState(name) {
    if (!sliderStates.has(name)) sliderStates.set(name, new SliderState(name));
    return sliderStates.get(name);
  }

  // ─── ToggleState ───
  class ToggleState {
    constructor(name) {
      if (!window.__JUCE__.initialisationData.__juce__toggles.includes(name))
        console.warn("Creating ToggleState for '" + name + "', unknown to backend");
      this.name = name;
      this.identifier = "__juce__toggle" + this.name;
      this.value = false;
      this.properties = { name: "", parameterIndex: -1 };
      this.valueChangedEvent = new ListenerList();
      this.propertiesChangedEvent = new ListenerList();
      window.__JUCE__.backend.addEventListener(this.identifier, (event) => this.handleEvent(event));
      window.__JUCE__.backend.emitEvent(this.identifier, { eventType: "requestInitialUpdate" });
    }
    getValue() { return this.value; }
    setValue(newValue) {
      this.value = newValue;
      window.__JUCE__.backend.emitEvent(this.identifier, { eventType: valueChangedEventId, value: this.value });
    }
    handleEvent(event) {
      if (event.eventType === valueChangedEventId) { this.value = event.value; this.valueChangedEvent.callListeners(); }
      if (event.eventType === propertiesChangedId) { const { eventType: _, ...rest } = event; this.properties = rest; this.propertiesChangedEvent.callListeners(); }
    }
  }

  const toggleStates = new Map();
  for (const name of window.__JUCE__.initialisationData.__juce__toggles)
    toggleStates.set(name, new ToggleState(name));

  function getToggleState(name) {
    if (!toggleStates.has(name)) toggleStates.set(name, new ToggleState(name));
    return toggleStates.get(name);
  }

  // ─── ComboBoxState ───
  class ComboBoxState {
    constructor(name) {
      if (!window.__JUCE__.initialisationData.__juce__comboBoxes.includes(name))
        console.warn("Creating ComboBoxState for '" + name + "', unknown to backend");
      this.name = name;
      this.identifier = "__juce__comboBox" + this.name;
      this.value = 0.0;
      this.properties = { name: "", parameterIndex: -1, choices: [] };
      this.valueChangedEvent = new ListenerList();
      this.propertiesChangedEvent = new ListenerList();
      window.__JUCE__.backend.addEventListener(this.identifier, (event) => this.handleEvent(event));
      window.__JUCE__.backend.emitEvent(this.identifier, { eventType: "requestInitialUpdate" });
    }
    getChoiceIndex() {
      return Math.round(this.value * (this.properties.choices.length - 1));
    }
    setChoiceIndex(index) {
      const numItems = this.properties.choices.length;
      this.value = numItems > 1 ? index / (numItems - 1) : 0.0;
      window.__JUCE__.backend.emitEvent(this.identifier, { eventType: valueChangedEventId, value: this.value });
    }
    handleEvent(event) {
      if (event.eventType === valueChangedEventId) { this.value = event.value; this.valueChangedEvent.callListeners(); }
      if (event.eventType === propertiesChangedId) { const { eventType: _, ...rest } = event; this.properties = rest; this.propertiesChangedEvent.callListeners(); }
    }
  }

  const comboBoxStates = new Map();
  for (const name of window.__JUCE__.initialisationData.__juce__comboBoxes)
    comboBoxStates.set(name, new ComboBoxState(name));

  function getComboBoxState(name) {
    if (!comboBoxStates.has(name)) comboBoxStates.set(name, new ComboBoxState(name));
    return comboBoxStates.get(name);
  }

  // ─── Backend resource address helper ───
  function getBackendResourceAddress(path) {
    const platform = window.__JUCE__.initialisationData.__juce__platform.length > 0
      ? window.__JUCE__.initialisationData.__juce__platform[0] : "";
    if (platform === "windows" || platform === "android")
      return "https://juce.backend/" + path;
    if (platform === "macos" || platform === "ios" || platform === "linux")
      return "juce://juce.backend/" + path;
    console.warn("getBackendResourceAddress() called, but no JUCE native backend detected.");
    return path;
  }

  // ─── ControlParameterIndexUpdater (for DAW automation hover) ───
  class ControlParameterIndexUpdater {
    constructor(annotation) {
      this.annotation = annotation;
      this.lastElement = null;
      this.lastIndex = null;
    }
    handleMouseMove(event) {
      const el = document.elementFromPoint(event.clientX, event.clientY);
      if (el === this.lastElement) return;
      this.lastElement = el;
      let idx = -1;
      if (el !== null) {
        let e = el;
        while (e && e !== document.documentElement) {
          if (e.hasAttribute(this.annotation)) { idx = e.getAttribute(this.annotation); break; }
          e = e.parentElement;
        }
      }
      if (idx === this.lastIndex) return;
      this.lastIndex = idx;
      window.__JUCE__.backend.emitEvent("__juce__controlParameterIndexChanged", idx);
    }
  }

  // ─── Export globals ───
  window.getNativeFunction = getNativeFunction;
  window.getSliderState = getSliderState;
  window.getToggleState = getToggleState;
  window.getComboBoxState = getComboBoxState;
  window.getBackendResourceAddress = getBackendResourceAddress;
  window.ControlParameterIndexUpdater = ControlParameterIndexUpdater;
})();
