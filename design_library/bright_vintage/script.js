/**
 * VST Style Forge - Interaction Logic
 * BRIGHT VINTAGE — generic wooden knobs + vintage faders
 */

class WoodenKnob {
  constructor(element) {
    this.element = element;
    this.value = 0.5;
    this.default = 0.5;
    this.isDragging = false;
    this.startY = 0;
    this.startVal = 0;

    this.pointer = element.querySelector('.knob-pointer');
    this.valueEl = element.parentElement.querySelector('.knob-value');

    element.addEventListener('mousedown', this.onMouseDown.bind(this));
    window.addEventListener('mousemove', this.onMouseMove.bind(this));
    window.addEventListener('mouseup', this.onMouseUp.bind(this));
    element.addEventListener('dblclick', () => { this.setValue(this.default); });

    this.update();
  }

  onMouseDown(e) {
    e.preventDefault();
    this.isDragging = true;
    this.startY = e.clientY;
    this.startVal = this.value;
    document.body.style.cursor = 'ns-resize';
  }

  onMouseMove(e) {
    if (!this.isDragging) return;
    const delta = this.startY - e.clientY;
    const sensitivity = 0.005;
    this.setValue(this.startVal + delta * sensitivity);
  }

  onMouseUp() {
    this.isDragging = false;
    document.body.style.cursor = 'default';
  }

  setValue(v) {
    this.value = Math.min(Math.max(v, 0), 1);
    this.update();
  }

  update() {
    const angle = -135 + this.value * 270;
    if (this.pointer) this.pointer.style.transform = `rotate(${angle}deg)`;
    if (this.valueEl) this.valueEl.textContent = this.value.toFixed(2);
    this.element.dataset.value = this.value.toFixed(3);
  }
}

class Fader {
  constructor(element) {
    this.element = element;
    this.value = 0.5;
    this.default = 0.5;
    this.isDragging = false;
    this.startY = 0;
    this.startVal = 0;

    this.handle = element.querySelector('.fader-handle');
    this.fill = element.querySelector('.fader-fill');

    if (this.handle) this.handle.addEventListener('mousedown', this.onMouseDown.bind(this));
    window.addEventListener('mousemove', this.onMouseMove.bind(this));
    window.addEventListener('mouseup', this.onMouseUp.bind(this));
    element.addEventListener('dblclick', () => { this.setValue(this.default); });

    this.update();
  }

  onMouseDown(e) {
    e.stopPropagation();
    e.preventDefault();
    this.isDragging = true;
    this.startY = e.clientY;
    this.startVal = this.value;
    document.body.style.cursor = 'ns-resize';
  }

  onMouseMove(e) {
    if (!this.isDragging) return;
    const delta = this.startY - e.clientY;
    const pixelRange = this.element.clientHeight - 40;
    const valDelta = delta / pixelRange;
    this.setValue(this.startVal + valDelta);
  }

  onMouseUp() {
    this.isDragging = false;
    document.body.style.cursor = 'default';
  }

  setValue(v) {
    this.value = Math.min(Math.max(v, 0), 1);
    this.update();
  }

  update() {
    if (this.handle) this.handle.style.top = `calc(${(1 - this.value) * 100}% - 13px)`;
    if (this.fill) this.fill.style.height = `${this.value * 100}%`;
  }
}

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.knob').forEach((el) => new WoodenKnob(el));
  document.querySelectorAll('.fader-container').forEach((el) => new Fader(el));
});
