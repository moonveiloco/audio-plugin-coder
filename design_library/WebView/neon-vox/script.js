/**
 * Neon Vox - Interaction Logic
 * Knobs, strip faders, mini meters, horizontal trims, static EQ analyzer,
 * static ducking bars and I/O meters (fixed values, no animation loop),
 * bypass / power / routing toggles.
 */

/* ───────────────────────────── KNOB ───────────────────────────── */

const KNOB_TRACK = 'M12.201 51.799 A28 28 0 1 1 51.799 51.799';

class Knob {
  constructor(el) {
    this.el = el;
    this.value = parseFloat(el.dataset.value ?? 0.5);
    this.size = parseInt(el.dataset.size ?? 72, 10);
    this.color = el.dataset.color || 'var(--acc-cyan)';
    this.big = el.classList.contains('big');
    this.format = el.dataset.format || null;
    this.chip = el.parentElement?.querySelector('.value-chip b');

    el.innerHTML = `
      <svg viewBox="0 0 64 64" width="${this.size}" height="${this.size}" style="color:${this.color}">
        <path d="${KNOB_TRACK}" fill="none" stroke="rgba(255,255,255,0.10)"
              stroke-width="${this.big ? 5 : 6}" stroke-linecap="round"/>
        <circle class="knob-arc" cx="32" cy="32" r="28" fill="none" stroke="currentColor"
                stroke-width="${this.big ? 5 : 6}" stroke-linecap="round" transform="rotate(135 32 32)"/>
        <g class="knob-pointer">
          <line x1="32" y1="32" x2="32" y2="${this.big ? 9 : 11}" stroke="#E8EAF0"
                stroke-width="${this.big ? 3 : 2.4}" stroke-linecap="round"/>
        </g>
        ${this.big ? '<circle cx="32" cy="32" r="21" fill="none" stroke="rgba(255,255,255,0.06)" stroke-width="1"/>' : ''}
      </svg>`;

    this.arc = el.querySelector('.knob-arc');
    this.pointer = el.querySelector('.knob-pointer');

    el.addEventListener('mousedown', this.onDown.bind(this));
    window.addEventListener('mousemove', this.onMove.bind(this));
    window.addEventListener('mouseup', this.onUp.bind(this));
    el.addEventListener('dblclick', () => { this.value = 0.5; this.update(); });

    this.update();
  }

  onDown(e) {
    e.preventDefault();
    this.dragging = true;
    this.startY = e.clientY;
    this.startVal = this.value;
    document.body.style.cursor = 'ns-resize';
  }

  onMove(e) {
    if (!this.dragging) return;
    const delta = this.startY - e.clientY;
    this.value = Math.min(Math.max(this.startVal + delta * 0.005, 0), 1);
    this.update();
  }

  onUp() {
    this.dragging = false;
    document.body.style.cursor = 'default';
  }

  update() {
    const circumference = 2 * Math.PI * 28;
    const arcLen = circumference * 0.75;
    this.arc.style.strokeDasharray = `${arcLen} ${circumference}`;
    this.arc.style.strokeDashoffset = arcLen - this.value * arcLen;
    this.pointer.setAttribute('transform', `rotate(${-135 + this.value * 270} 32 32)`);
    if (this.chip && this.format) this.chip.textContent = Knob.format(this.format, this.value);
  }

  static format(kind, v) {
    switch (kind) {
      case 'percent': return `${Math.round(v * 200)}%`;
      case 'khz':     return `${(2 + v * 8).toFixed(1)} kHz`;
      case 'sec':     return `${(0.1 + v * 9.9).toFixed(1)} s`;
      case 'rate':    return ['1/4', '1/8', '1/8d', '1/16', '1/16d'][Math.min(4, Math.floor(v * 5))];
      default:        return v.toFixed(2);
    }
  }
}

/* ───────────────────── MINI METER (GATE / GR / DS) ───────────────────── */

class MiniMeter {
  constructor(el) {
    this.el = el;
    this.value = parseFloat(el.dataset.value ?? 0.5);
    this.color = el.dataset.color || 'var(--acc-cyan)';

    this.fill = document.createElement('div');
    this.fill.className = 'mm-fill';
    this.fill.style.background = this.color;
    this.handle = document.createElement('div');
    this.handle.className = 'mm-handle';
    el.append(this.fill, this.handle);

    el.addEventListener('mousedown', this.onDown.bind(this));
    window.addEventListener('mousemove', this.onMove.bind(this));
    window.addEventListener('mouseup', this.onUp.bind(this));

    this.update();
  }

  onDown(e) {
    e.preventDefault();
    this.dragging = true;
    this.startY = e.clientY;
    this.startVal = this.value;
  }

  onMove(e) {
    if (!this.dragging) return;
    const range = this.el.clientHeight - 8;
    this.value = Math.min(Math.max(this.startVal + (this.startY - e.clientY) / range, 0), 1);
    this.update();
  }

  onUp() { this.dragging = false; }

  update() {
    this.fill.style.height = `calc(${this.value * 100}% - 2px)`;
    this.handle.style.bottom = `calc(${this.value * 100}% - 2px)`;
  }
}

/* ───────────────────── STRIP FADER (LOW/MID/HIGH/AIR) ───────────────────── */

class StripFader {
  constructor(el) {
    this.el = el;
    this.value = parseFloat(el.dataset.value ?? 0.5);
    this.color = el.dataset.color || 'var(--acc-cyan)';

    el.innerHTML += `
      <div class="sf-track" style="color:${this.color}">
        <div class="sf-fill" style="background:${this.color}"></div>
        <div class="sf-handle"></div>
      </div>`;

    this.fill = el.querySelector('.sf-fill');
    this.handle = el.querySelector('.sf-handle');

    el.addEventListener('mousedown', this.onDown.bind(this));
    window.addEventListener('mousemove', this.onMove.bind(this));
    window.addEventListener('mouseup', this.onUp.bind(this));

    this.update();
  }

  onDown(e) {
    e.preventDefault();
    this.dragging = true;
    this.startY = e.clientY;
    this.startVal = this.value;
  }

  onMove(e) {
    if (!this.dragging) return;
    const range = this.el.clientHeight - 12;
    this.value = Math.min(Math.max(this.startVal + (this.startY - e.clientY) / range, 0), 1);
    this.update();
  }

  onUp() { this.dragging = false; }

  update() {
    this.fill.style.height = `${this.value * 100}%`;
    this.handle.style.bottom = `${this.value * 100}%`;
  }
}

/* ───────────────────── HORIZONTAL TRIM SLIDER ───────────────────── */

class HSlider {
  constructor(el) {
    this.el = el;
    this.value = parseFloat(el.dataset.value ?? 0.5);
    this.color = el.dataset.color || 'var(--acc-cyan)';

    const ticks = Array.from({ length: 9 }, () => '<i></i>').join('');
    el.innerHTML = `
      <div class="hs-track">
        <div class="hs-fill" style="background:${this.color}"></div>
        <div class="hs-ticks">${ticks}</div>
      </div>
      <div class="hs-handle"></div>`;

    this.fill = el.querySelector('.hs-fill');
    this.handle = el.querySelector('.hs-handle');

    el.addEventListener('mousedown', this.onDown.bind(this));
    window.addEventListener('mousemove', this.onMove.bind(this));
    window.addEventListener('mouseup', this.onUp.bind(this));

    this.update();
  }

  onDown(e) {
    e.preventDefault();
    this.dragging = true;
    this.startX = e.clientX;
    this.startVal = this.value;
  }

  onMove(e) {
    if (!this.dragging) return;
    const range = this.el.clientWidth - 16;
    this.value = Math.min(Math.max(this.startVal + (e.clientX - this.startX) / range, 0), 1);
    this.update();
  }

  onUp() { this.dragging = false; }

  update() {
    this.fill.style.width = `${this.value * 100}%`;
    this.handle.style.left = `${this.value * 100}%`;
  }
}

/* ───────────────────── EQ ANALYZER CANVAS ───────────────────── */

class EqAnalyzer {
  constructor(canvas) {
    this.cv = canvas;
    this.cx = canvas.getContext('2d');
    // Base curve: control points [x(0..1), y(0..1)] — HP slope, low-mid dip, presence bell, air shelf
    this.points = [
      [0.00, 0.95], [0.10, 0.90], [0.18, 0.62], [0.26, 0.55],
      [0.36, 0.62], [0.48, 0.55], [0.60, 0.42], [0.72, 0.35],
      [0.84, 0.28], [0.93, 0.25], [1.00, 0.27],
    ];
  }

  draw() {
    const { cx, cv } = this;
    const W = cv.width, H = cv.height;

    cx.clearRect(0, 0, W, H);

    // Grid
    cx.strokeStyle = 'rgba(255,255,255,0.06)';
    cx.lineWidth = 1;
    for (let i = 1; i < 4; i++) {
      cx.beginPath(); cx.moveTo(0, (H / 4) * i); cx.lineTo(W, (H / 4) * i); cx.stroke();
    }
    for (let i = 1; i < 6; i++) {
      cx.beginPath(); cx.moveTo((W / 6) * i, 0); cx.lineTo((W / 6) * i, H); cx.stroke();
    }

    // Curve
    const pts = this.points.map(([px, py]) => [px * W, py * H]);

    const path = new Path2D();
    path.moveTo(pts[0][0], pts[0][1]);
    for (let i = 1; i < pts.length; i++) {
      const [x0, y0] = pts[i - 1], [x1, y1] = pts[i];
      path.quadraticCurveTo(x0, y0, (x0 + x1) / 2, (y0 + y1) / 2);
    }
    path.lineTo(pts[pts.length - 1][0], pts[pts.length - 1][1]);

    // Gradient fill under curve
    const fill = new Path2D(path);
    fill.lineTo(W, H); fill.lineTo(0, H); fill.closePath();
    const grad = cx.createLinearGradient(0, 0, 0, H);
    grad.addColorStop(0, 'rgba(53,208,245,0.22)');
    grad.addColorStop(1, 'rgba(53,208,245,0.01)');
    cx.fillStyle = grad;
    cx.fill(fill);

    // Glow stroke
    cx.save();
    cx.shadowColor = '#35D0F5';
    cx.shadowBlur = 8;
    cx.strokeStyle = '#7CE7FF';
    cx.lineWidth = 2;
    cx.stroke(path);
    cx.restore();

    // Handles (band nodes)
    [[0.18, 0], [0.48, 1], [0.84, 2]].forEach(([px], bi) => {
      const i = Math.round(px * (this.points.length - 1));
      const [x, y] = pts[i];
      cx.beginPath();
      cx.arc(x, y, 4, 0, Math.PI * 2);
      cx.fillStyle = bi === 1 ? '#E8EAF0' : '#35D0F5';
      cx.shadowColor = '#35D0F5';
      cx.shadowBlur = 6;
      cx.fill();
      cx.shadowBlur = 0;
    });
  }
}

/* ───────────────────── I/O SEGMENTED METERS ───────────────────── */

class IoMeter {
  constructor(el, segments = 44) {
    this.el = el;
    this.level = parseFloat(el.dataset.value ?? 0.6);
    for (let i = 0; i < segments; i++) {
      const seg = document.createElement('i');
      const pos = i / segments;
      seg.dataset.color = pos < 0.62 ? '#35D0F5' : pos < 0.85 ? '#A855F7' : '#FF3D71';
      el.appendChild(seg);
    }
    this.segs = [...el.children];
    this.render();
  }

  render() {
    const lit = Math.round(this.level * this.segs.length);
    this.segs.forEach((s, i) => {
      if (i < lit) {
        s.style.background = s.dataset.color;
        s.style.boxShadow = i > lit - 3 ? `0 0 4px ${s.dataset.color}` : 'none';
      } else {
        s.style.background = 'rgba(255,255,255,0.08)';
        s.style.boxShadow = 'none';
      }
    });
  }
}

/* ───────────────────── TOGGLES ───────────────────── */

function initToggles() {
  const bypass = document.getElementById('bypass-btn');
  bypass.addEventListener('click', () => {
    bypass.classList.toggle('on');
    document.querySelector('.plugin-container').classList.toggle('bypassed');
  });

  document.querySelectorAll('.power-btn').forEach(btn => {
    btn.addEventListener('click', () => btn.classList.toggle('on'));
  });

  document.querySelectorAll('.routing-btn').forEach(btn => {
    btn.addEventListener('click', () => btn.classList.toggle('on'));
  });

  // Module preset arrows cycle the active dot
  document.querySelectorAll('.module-card').forEach(card => {
    const dots = [...card.querySelectorAll('.module-dots i')];
    let idx = dots.findIndex(d => d.classList.contains('on'));
    card.querySelectorAll('.module-arrow').forEach((arrow, ai) => {
      arrow.addEventListener('click', () => {
        idx = (idx + (ai === 0 ? dots.length - 1 : 1)) % dots.length;
        dots.forEach((d, di) => d.classList.toggle('on', di <= idx));
      });
    });
  });
}

/* ───────────────────── BOOT ───────────────────── */

document.addEventListener('DOMContentLoaded', () => {
  document.querySelectorAll('.knob').forEach(el => new Knob(el));
  document.querySelectorAll('.mini-meter').forEach(el => new MiniMeter(el));
  document.querySelectorAll('.strip-fader').forEach(el => new StripFader(el));
  document.querySelectorAll('.h-slider').forEach(el => new HSlider(el));
  initToggles();

  // Static render: meters and analyzer drawn once (graphic preset)
  const analyzer = new EqAnalyzer(document.getElementById('eq-canvas'));
  analyzer.draw();
  new IoMeter(document.getElementById('meter-in'));
  new IoMeter(document.getElementById('meter-out'));
});
