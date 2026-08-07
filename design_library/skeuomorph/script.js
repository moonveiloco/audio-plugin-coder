/* ==========================================================================
   SKEUOMORPH — interactive mockup behaviour
   Knobs, faders, VU meter, 7-seg display, switches, buttons.
   ========================================================================== */

(function () {
  'use strict';

  /* ----------------------------- utils ----------------------------- */
  function polar(cx, cy, deg, r) {
    const a = (deg * Math.PI) / 180;
    return { x: cx + r * Math.sin(a), y: cy - r * Math.cos(a) };
  }

  function clamp(v, min, max) {
    return Math.min(max, Math.max(min, v));
  }

  function formatValue(v) {
    return v.toFixed(2);
  }

  /* ----------------------------- 7-seg ----------------------------- */
  const SEG_PATTERNS = {
    0: ['a', 'b', 'c', 'd', 'e', 'f'],
    1: ['b', 'c'],
    2: ['a', 'b', 'g', 'e', 'd'],
    3: ['a', 'b', 'g', 'c', 'd'],
    4: ['f', 'g', 'b', 'c'],
    5: ['a', 'f', 'g', 'c', 'd'],
    6: ['a', 'f', 'g', 'e', 'c', 'd'],
    7: ['a', 'b', 'c'],
    8: ['a', 'b', 'c', 'd', 'e', 'f', 'g'],
    9: ['a', 'b', 'c', 'd', 'f', 'g']
  };

  function setDigit(svg, value) {
    const lit = SEG_PATTERNS[value] || [];
    svg.querySelectorAll('.seg').forEach(function (seg) {
      seg.classList.toggle('lit', lit.indexOf(seg.getAttribute('data-seg') || seg.classList[1]) !== -1);
    });
  }

  function renderValue(value) {
    const digits = document.querySelectorAll('.digit');
    const str = String(Math.round(value * 100)).padStart(3, '0');
    digits.forEach(function (svg, i) {
      setDigit(svg, parseInt(str[i], 10));
    });
  }

  /* ----------------------------- Knob ----------------------------- */
  class Knob {
    constructor(el, defaultVal) {
      this.el = el;
      this.defaultVal = defaultVal !== undefined ? defaultVal : 0.5;
      this.value = this.defaultVal;
      this.dragging = false;
      this.lastY = 0;
      this.sensitivity = 0.005;

      this.pointer = el.querySelector('.knob-pointer');
      this.valueEl = el.parentElement.querySelector('.knob-value');

      this.el.addEventListener('mousedown', this.onDown.bind(this));
      this.el.addEventListener('dblclick', this.reset.bind(this));
      document.addEventListener('mousemove', this.onMove.bind(this));
      document.addEventListener('mouseup', this.onUp.bind(this));

      this.render();
    }

    onDown(e) {
      this.dragging = true;
      this.lastY = e.clientY;
      e.preventDefault();
    }

    onMove(e) {
      if (!this.dragging) return;
      const delta = this.lastY - e.clientY;
      this.lastY = e.clientY;
      this.value = clamp(this.value + delta * this.sensitivity, 0, 1);
      this.render();
    }

    onUp() {
      this.dragging = false;
    }

    reset() {
      this.value = this.defaultVal;
      this.render();
    }

    render() {
      const angle = -135 + this.value * 270;
      if (this.pointer) {
        this.pointer.style.transform = 'rotate(' + angle + 'deg)';
      }
      if (this.valueEl) {
        this.valueEl.textContent = formatValue(this.value);
      }
    }
  }

  /* ----------------------------- Fader ----------------------------- */
  class Fader {
    constructor(el, defaultVal) {
      this.el = el;
      this.defaultVal = defaultVal !== undefined ? defaultVal : 0.5;
      this.value = this.defaultVal;
      this.dragging = false;
      this.lastY = 0;
      this.sensitivity = 0.005;

      this.track = el.querySelector('.fader-track');
      this.handle = el.querySelector('.fader-handle');
      this.fill = el.querySelector('.fader-fill');
      this.handleH = this.handle ? this.handle.offsetHeight : 20;

      this.el.addEventListener('mousedown', this.onDown.bind(this));
      this.el.addEventListener('dblclick', this.reset.bind(this));
      document.addEventListener('mousemove', this.onMove.bind(this));
      document.addEventListener('mouseup', this.onUp.bind(this));

      this.render();
    }

    onDown(e) {
      this.dragging = true;
      this.lastY = e.clientY;
      e.preventDefault();
    }

    onMove(e) {
      if (!this.dragging) return;
      const delta = this.lastY - e.clientY;
      this.lastY = e.clientY;
      this.value = clamp(this.value + delta * this.sensitivity, 0, 1);
      this.render();
    }

    onUp() {
      this.dragging = false;
    }

    reset() {
      this.value = this.defaultVal;
      this.render();
    }

    render() {
      if (!this.track) return;
      const pixelRange = this.track.clientHeight - this.handleH;
      const y = (1 - this.value) * pixelRange;
      if (this.handle) this.handle.style.top = y + 'px';
      if (this.fill) this.fill.style.height = (this.value * 100) + '%';
    }
  }

  /* ----------------------------- VU meter ----------------------------- */
  function buildVUMeter(container) {
    const CX = 120;
    const CY = 128;
    const R = 82;
    const NS = 48;

    let svg = '<svg class="vu-svg" viewBox="0 0 240 150">';

    svg += '<defs><linearGradient id="vuGlass" x1="0" y1="0" x2="1" y2="1">';
    svg += '<stop offset="0" stop-color="#ffffff" stop-opacity="0.22"/>';
    svg += '<stop offset="0.45" stop-color="#ffffff" stop-opacity="0.02"/>';
    svg += '<stop offset="1" stop-color="#000000" stop-opacity="0.25"/>';
    svg += '</linearGradient></defs>';

    svg += '<rect class="vu-bezel" x="4" y="4" width="232" height="142" rx="12"/>';
    svg += '<rect class="vu-face" x="12" y="12" width="216" height="126" rx="8"/>';

    // coloured zones
    const zones = [
      { from: -NS, to: -16, cls: 'vu-zone-green' },
      { from: -16, to: 4, cls: 'vu-zone-yellow' },
      { from: 4, to: NS, cls: 'vu-zone-red' }
    ];
    zones.forEach(function (z) {
      const p1 = polar(CX, CY, z.from, R - 4);
      const p2 = polar(CX, CY, z.to, R - 4);
      svg += '<path d="M ' + p1.x.toFixed(1) + ' ' + p1.y.toFixed(1) +
        ' A ' + (R - 4) + ' ' + (R - 4) + ' 0 0 1 ' + p2.x.toFixed(1) + ' ' + p2.y.toFixed(1) +
        '" class="' + z.cls + '"/>';
    });

    // ticks
    const labels = { '-48': '-20', '-36': '-10', '-24': '-5', '-12': '-3', '0': '0', '12': '+1', '24': '+3', '36': '+5', '48': '+6' };
    for (let deg = -NS; deg <= NS; deg += 4) {
      const major = deg % 12 === 0;
      const r1 = major ? R - 9 : R - 5;
      const r2 = R - 15;
      const p1 = polar(CX, CY, deg, r1);
      const p2 = polar(CX, CY, deg, r2);
      svg += '<line x1="' + p1.x.toFixed(1) + '" y1="' + p1.y.toFixed(1) +
        '" x2="' + p2.x.toFixed(1) + '" y2="' + p2.y.toFixed(1) +
        '" class="vu-tick' + (major ? ' major' : '') + '"/>';
      if (major && labels[String(deg)]) {
        const lp = polar(CX, CY, deg, R - 26);
        svg += '<text x="' + lp.x.toFixed(1) + '" y="' + lp.y.toFixed(1) +
          '" class="vu-label" text-anchor="middle">' + labels[String(deg)] + '</text>';
      }
    }

    // needle + pivot
    const nEnd = polar(CX, CY, 0, R - 6);
    svg += '<g class="vu-needle" id="vu-needle">';
    svg += '<line class="vu-needle-line" x1="' + CX + '" y1="' + CY +
      '" x2="' + nEnd.x.toFixed(1) + '" y2="' + nEnd.y.toFixed(1) + '"/>';
    svg += '</g>';
    svg += '<circle class="vu-pivot" cx="' + CX + '" cy="' + CY + '" r="4"/>';

    // glass overlay
    svg += '<path class="vu-glass" d="M 12 12 L 228 12 L 228 46 L 12 46 Z"/>';

    svg += '</svg>';

    container.innerHTML = svg;
  }

  function setNeedle(value) {
    const needle = document.getElementById('vu-needle');
    if (!needle) return;
    const deg = value * 96 - 48;
    needle.setAttribute('transform', 'rotate(' + deg + ' 120 128)');
  }

  /* ----------------------------- init ----------------------------- */
  document.addEventListener('DOMContentLoaded', function () {
    document.querySelectorAll('.knob').forEach(function (el) {
      new Knob(el);
    });
    document.querySelectorAll('.fader-container').forEach(function (el) {
      new Fader(el);
    });

    const vuWrap = document.getElementById('vu-wrap');
    if (vuWrap) buildVUMeter(vuWrap);
    setNeedle(0.35);
    renderValue(0.35);

    // power switch + LED
    const powerSwitch = document.getElementById('power-switch');
    const powerLed = document.getElementById('power-led');
    if (powerSwitch) {
      powerSwitch.addEventListener('click', function () {
        const on = powerSwitch.classList.toggle('on');
        powerSwitch.setAttribute('aria-checked', on ? 'true' : 'false');
        if (powerLed) powerLed.classList.toggle('on', on);
      });
    }

    // buttons
    document.querySelectorAll('.btn').forEach(function (btn) {
      btn.addEventListener('click', function () {
        const on = btn.classList.toggle('on');
        btn.setAttribute('aria-pressed', on ? 'true' : 'false');
      });
    });
  });
})();
