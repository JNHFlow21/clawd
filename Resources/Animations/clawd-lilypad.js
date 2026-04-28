const cv = document.getElementById('c');
const ctx = cv.getContext('2d');

// ─── PALETTE ─────────────────────────────────────────────────
const PALETTE = {
  clawd: { body: '#CD6E58', bodyDark: '#B85E4A', eye: '#000000' },
  water: {
    bg: '#3CD9AB', bgAlt: '#36CFA2',
    light: '#5EEDC2', mid: '#44DEAF',
    dark: '#2DB893', deep: '#1B9E7A',
    ripple: '#239B7C', drop: '#1B8A6E',
    foam: '#8EECD8',
  },
  leaf: {
    main: '#2ECC71', dark: '#27AE60',
    light: '#58D68D', edge: '#1E8449',
    vein: '#239B56',
  },
  hat: {
    main: '#F0C078', light: '#FADBA0', dark: '#D4A050',
    band: '#C0392B', bandDark: '#A93226',
    highlight: '#FFF3D6',
  },
  ui: { white: '#FFFFFF', black: '#000000' },
};

// ─── PIXEL GRID (higher res: 144×144, 5px per cell) ─────────
const PX = 5;
const GW = cv.width / PX;   // 144
const GH = cv.height / PX;  // 144

function px(gx, gy, col) {
  ctx.fillStyle = col;
  ctx.fillRect(Math.floor(gx) * PX, Math.floor(gy) * PX, PX, PX);
}

// Fill a rectangle in grid coords
function pxRect(gx, gy, w, h, col) {
  ctx.fillStyle = col;
  ctx.fillRect(Math.floor(gx) * PX, Math.floor(gy) * PX, w * PX, h * PX);
}

// ─── CLAWD BODY (14×8 sprite, scaled 3x = 42×24 screen pixels) ───
const SCALE = 3;
const CLAWD_BODY = {
  width: 14, height: 8,
  data: [
    [0,0,0,1,1,1,1,1,1,1,1,0,0,0],
    [0,0,0,1,1,1,1,1,1,1,1,0,0,0],
    [0,1,1,1,1,1,1,1,1,1,1,1,1,0],
    [0,1,1,1,1,1,1,1,1,1,1,1,1,0],
    [0,0,0,1,1,1,1,1,1,1,1,0,0,0],
    [0,0,0,1,1,1,1,1,1,1,1,0,0,0],
    [0,0,0,1,0,1,0,0,1,0,1,0,0,0],
    [0,0,0,1,0,1,0,0,1,0,1,0,0,0]
  ],
  anchors: {
    eyeLeft:  { x: 4, y: 1 },
    eyeRight: { x: 9, y: 1 },
    hatTop:   { x: 7, y: -1 },
  }
};

const EYES = {
  forward:    { left: {dx:0,dy:0}, right: {dx:0,dy:0} },
  look_right: { left: {dx:1,dy:0}, right: {dx:1,dy:0} },
  look_left:  { left: {dx:-1,dy:0}, right: {dx:-1,dy:0} },
  look_down:  { left: {dx:0,dy:1}, right: {dx:0,dy:1} },
  blink:      { type: 'hidden' },
};

function drawClawd(ox, oy, eyeVariant) {
  const ev = eyeVariant || 'forward';
  for (let r = 0; r < CLAWD_BODY.height; r++) {
    for (let c = 0; c < CLAWD_BODY.width; c++) {
      if (CLAWD_BODY.data[r][c] === 1) {
        pxRect(ox + c * SCALE, oy + r * SCALE, SCALE, SCALE, PALETTE.clawd.body);
      }
    }
  }
  // Eyes (SCALE-matched: 3×3 pixels each, with highlight)
  const eyeData = EYES[ev];
  if (eyeData && eyeData.type !== 'hidden') {
    const el = CLAWD_BODY.anchors.eyeLeft;
    const er = CLAWD_BODY.anchors.eyeRight;
    const elx = ox + (el.x + eyeData.left.dx) * SCALE;
    const ely = oy + (el.y + eyeData.left.dy) * SCALE;
    const erx = ox + (er.x + eyeData.right.dx) * SCALE;
    const ery = oy + (er.y + eyeData.right.dy) * SCALE;
    // 3×3 pure black eye
    pxRect(elx, ely, 3, 3, PALETTE.clawd.eye);
    pxRect(erx, ery, 3, 3, PALETTE.clawd.eye);
  } else if (eyeData && eyeData.type === 'hidden') {
    // Blink: horizontal line 4px wide, 1px tall
    const el = CLAWD_BODY.anchors.eyeLeft;
    const er = CLAWD_BODY.anchors.eyeRight;
    pxRect(ox + el.x * SCALE, oy + el.y * SCALE + 1, 4, 1, PALETTE.clawd.eye);
    pxRect(ox + er.x * SCALE, oy + er.y * SCALE + 1, 4, 1, PALETTE.clawd.eye);
  }
}

// ─── FARMER HAT (Shin-chan style, compact) ───────────────────
function drawHat(ox, oy) {
  // ox, oy = Clawd's top-left
  const S = SCALE; // 3
  // Brim: 14 sprite units wide (slightly wider than 14-wide body)
  const brimW = 14 * S;
  const brimH = Math.round(1.5 * S);
  const brimX = ox;
  const brimY = oy - Math.round(1.5 * S);

  // Crown: 8 units wide, centered
  const crownW = 8 * S;
  const crownX = ox + 3 * S;
  const crownY = brimY - 3 * S;

  // Top dome (rounded)
  for (let r = 0; r < S; r++) {
    const inset = Math.max(0, Math.floor((S - r) * 1.5));
    for (let c = inset; c < crownW - inset; c++) {
      const gx = crownX + c;
      const gy = crownY + r;
      const isHL = (c > inset + 1 && c < inset + S * 2);
      px(gx, gy, isHL ? PALETTE.hat.highlight : PALETTE.hat.light);
    }
  }

  // Mid crown
  for (let r = 0; r < Math.round(1.5 * S); r++) {
    for (let c = 0; c < crownW; c++) {
      const gx = crownX + c;
      const gy = crownY + S + r;
      const isHL = (c < S);
      px(gx, gy, isHL ? PALETTE.hat.light : PALETTE.hat.main);
    }
  }

  // Hat band (red ribbon) - 2px tall
  const bandY = brimY - 2;
  for (let r = 0; r < 2; r++) {
    for (let c = 0; c < crownW + S; c++) {
      const gx = crownX - Math.floor(S / 2) + c;
      const gy = bandY + r;
      const isEdge = (c < 1 || c >= crownW + S - 1);
      px(gx, gy, isEdge ? PALETTE.hat.bandDark : PALETTE.hat.band);
    }
  }

  // Brim
  for (let r = 0; r < brimH; r++) {
    for (let c = 0; c < brimW; c++) {
      const gx = brimX + c;
      const gy = brimY + r;
      const distFromCenter = Math.abs(c - brimW / 2) / (brimW / 2);
      let col = PALETTE.hat.main;
      if (r === 0 && distFromCenter < 0.4) col = PALETTE.hat.light;
      if (distFromCenter > 0.85) col = PALETTE.hat.dark;
      if (r === brimH - 1) col = PALETTE.hat.dark;
      px(gx, gy, col);
    }
  }
}

// ─── WATER BACKGROUND (natural, calm, reference-matching) ────
// Pre-generate a subtle noise field for organic feel
const noiseField = [];
for (let i = 0; i < 256; i++) noiseField.push(Math.random());
function noise2d(x, y) {
  const ix = Math.floor(Math.abs(x * 7.3)) % 256;
  const iy = Math.floor(Math.abs(y * 11.1)) % 256;
  return noiseField[(ix + iy * 17) % 256];
}

// Water color interpolation
function lerpColor(a, b, t) {
  t = Math.max(0, Math.min(1, t));
  const ah = parseInt(a.slice(1), 16), bh = parseInt(b.slice(1), 16);
  const ar = (ah >> 16) & 0xFF, ag = (ah >> 8) & 0xFF, ab = ah & 0xFF;
  const br = (bh >> 16) & 0xFF, bg = (bh >> 8) & 0xFF, bb = bh & 0xFF;
  const rr = Math.round(ar + (br - ar) * t);
  const rg = Math.round(ag + (bg - ag) * t);
  const rb = Math.round(ab + (bb - ab) * t);
  return `rgb(${rr},${rg},${rb})`;
}

function insideWaterPatch(x, y, cx, cy, hw, hh) {
  const nx = (x - cx) / hw;
  const ny = (y - cy) / hh;
  return nx * nx + ny * ny <= 1;
}

function drawWater(cx, cy, t) {
  const hw = 56;
  const hh = 31;
  const minX = Math.max(0, Math.floor(cx - hw));
  const maxX = Math.min(GW - 1, Math.ceil(cx + hw));
  const minY = Math.max(0, Math.floor(cy - hh));
  const maxY = Math.min(GH - 1, Math.ceil(cy + hh));

  for (let y = minY; y <= maxY; y++) {
    for (let x = minX; x <= maxX; x++) {
      const nx = (x - cx) / hw;
      const ny = (y - cy) / hh;
      const dist = nx * nx + ny * ny;
      if (dist > 1) continue;

      const n = noise2d(x + t * 0.18, y - t * 0.12);
      let col = lerpColor(PALETTE.water.bg, PALETTE.water.bgAlt, y / GH * 0.7 + n * 0.18);
      if (dist > 0.82) col = PALETTE.water.deep;
      else if (dist > 0.62) col = PALETTE.water.dark;
      else if (n > 0.82) col = PALETTE.water.light;

      const edgeAlpha = Math.min(1, Math.max(0, (1 - dist) * 8));
      ctx.globalAlpha = 0.78 * edgeAlpha;
      px(x, y, col);
    }
  }
  ctx.globalAlpha = 1;

  for (let s = 0; s < 4; s++) {
    const sy = cy - 17 + s * 10 + Math.sin(t * 0.5 + s * 2) * 2.4;
    const sx = cx - 31 + Math.sin(t * 0.3 + s) * 7;
    const sw = 20 + Math.sin(t * 0.4 + s * 1.5) * 7;
    ctx.fillStyle = 'rgba(142, 236, 216, 0.5)';
    for (let i = 0; i < sw; i++) {
      const gx = Math.floor(sx + i);
      const gy = Math.floor(sy + Math.sin(i * 0.28 + t + s) * 1.2);
      if (gx >= 0 && gx < GW && gy >= 0 && gy < GH && insideWaterPatch(gx, gy, cx, cy, hw, hh)) {
        ctx.fillRect(gx * PX, gy * PX, PX, PX);
      }
    }
  }
}

// ─── LILY PAD ────────────────────────────────────────────────
function drawLilyPad(cx, cy) {
  // Elliptical lily pad, ~36×14 grid cells
  const hw = 28;
  const hh = 11;

  for (let dy = -hh; dy <= hh; dy++) {
    for (let dx = -hw; dx <= hw; dx++) {
      const nx = dx / hw;
      const ny = dy / hh;
      const dist = nx * nx + ny * ny;
      if (dist > 1.0) continue;

      // V-notch at top
      if (dy <= 0 && Math.abs(dx) < (-dy * 1.8 + 1)) continue;

      let col = PALETTE.leaf.main;
      if (dist > 0.8) col = PALETTE.leaf.edge;
      else if (dist > 0.55) col = PALETTE.leaf.dark;
      else if (dist < 0.1) col = PALETTE.leaf.light;

      // Central vein lines
      if (Math.abs(dx) <= 1 && dy > 0) col = PALETTE.leaf.vein;
      // Radial veins
      const angle = Math.atan2(dy, dx);
      if (dy > 1 && dist > 0.15 && dist < 0.75) {
        const veinAngle = ((angle % (Math.PI / 4)) + Math.PI / 4) % (Math.PI / 4);
        if (veinAngle < 0.08 || veinAngle > Math.PI / 4 - 0.08) col = PALETTE.leaf.vein;
      }

      px(Math.floor(cx + dx), Math.floor(cy + dy), col);
    }
  }
}

// ─── WATER RIPPLES ───────────────────────────────────────────
function drawRipples(cx, cy, t) {
  for (let ring = 0; ring < 3; ring++) {
    const phase = (t * 0.8 + ring * 0.33) % 1.0;
    const radius = 22 + phase * 30;
    const alpha = (1.0 - phase) * 0.35;
    if (alpha <= 0.02) continue;

    const steps = Math.round(radius * 6);
    for (let i = 0; i < steps; i++) {
      const a = (i / steps) * Math.PI * 2;
      const rx = cx + Math.cos(a) * radius;
      const ry = cy + Math.sin(a) * radius * 0.35;
      if (rx >= 0 && rx < GW && ry >= 0 && ry < GH) {
        ctx.fillStyle = `rgba(30, 132, 73, ${alpha})`;
        ctx.fillRect(Math.floor(rx) * PX, Math.floor(ry) * PX, PX, PX);
      }
    }
  }
}

// ─── FLOATING FLOWER PETALS ─────────────────────────────────
const PETAL = {
  main: '#F5B0C0',
  light: '#FCDAE2',
  dark: '#E890A5',
  accent: '#FFD6E0',
};

// Petal shapes: 1=main, 2=light, 3=dark, 4=accent, 0=empty
const PETAL_SHAPES = [
  // Wide petal (5x3) — lying flat on water
  [
    [0,3,1,3,0],
    [3,1,2,4,3],
    [0,3,1,3,0],
  ],
  // Tall petal (3x5) — elongated
  [
    [0,3,0],
    [3,4,3],
    [1,2,1],
    [3,4,3],
    [0,3,0],
  ],
  // Curved petal (4x4) — slightly diagonal
  [
    [0,3,1,0],
    [3,2,4,3],
    [0,1,1,3],
    [0,0,3,0],
  ],
  // Small round petal (4x3)
  [
    [0,1,3,0],
    [3,2,4,3],
    [0,3,1,0],
  ],
];

const waterElements = [];
for (let i = 0; i < 8; i++) {
  const angle = Math.random() * Math.PI * 2;
  const radius = Math.sqrt(Math.random());
  waterElements.push({
    x: Math.cos(angle) * radius,
    y: Math.sin(angle) * radius,
    phase: Math.random() * Math.PI * 2,
    speed: 0.3 + Math.random() * 0.5,
    shape: Math.floor(Math.random() * PETAL_SHAPES.length),
  });
}

function drawWaterElements(cx, cy, t) {
  const colorMap = { 1: PETAL.main, 2: PETAL.light, 3: PETAL.dark, 4: PETAL.accent };
  for (const el of waterElements) {
    const bx = cx + el.x * 42 + Math.sin(t * el.speed + el.phase) * 4;
    const by = cy + el.y * 20 + Math.cos(t * el.speed * 0.6 + el.phase) * 2;
    const shape = PETAL_SHAPES[el.shape];
    for (let r = 0; r < shape.length; r++) {
      for (let c = 0; c < shape[r].length; c++) {
        const v = shape[r][c];
        if (v === 0) continue;
        px(Math.floor(bx + c), Math.floor(by + r), colorMap[v]);
      }
    }
  }
}

// ─── SPLASH PARTICLES ────────────────────────────────────────
let particles = [];

function addSplash(x, y, count) {
  for (let i = 0; i < count; i++) {
    particles.push({
      x, y,
      vx: (Math.random() - 0.5) * 0.6,
      vy: -Math.random() * 0.5 - 0.1,
      life: 1.0,
      col: PALETTE.water.foam,
    });
  }
}

function tickParticles() {
  for (let i = particles.length - 1; i >= 0; i--) {
    const p = particles[i];
    p.x += p.vx;
    p.y += p.vy;
    p.vy += 0.02;
    p.life -= 0.018;
    if (p.life <= 0) { particles.splice(i, 1); continue; }
    ctx.globalAlpha = Math.max(0, p.life);
    px(Math.round(p.x), Math.round(p.y), p.col);
  }
  ctx.globalAlpha = 1;
}

// ─── BUBBLE ──────────────────────────────────────────────────
function drawBubble(gx, gy, text, alpha) {
  ctx.globalAlpha = Math.max(0, Math.min(1, alpha));
  ctx.fillStyle = 'rgba(255,255,255,0.85)';
  ctx.font = '13px "PingFang SC", "Hiragino Sans GB", sans-serif';
  const metrics = ctx.measureText(text);
  const tw = metrics.width + 14;
  const th = 22;
  const sx = gx * PX - tw / 2;
  const sy = gy * PX - th;

  ctx.beginPath();
  ctx.roundRect(sx, sy, tw, th, 5);
  ctx.fill();

  // Tail
  ctx.beginPath();
  ctx.moveTo(gx * PX - 3, sy + th);
  ctx.lineTo(gx * PX, sy + th + 5);
  ctx.lineTo(gx * PX + 3, sy + th);
  ctx.fill();

  ctx.fillStyle = '#8AAA99';
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.fillText(text, gx * PX, sy + th / 2);
  ctx.globalAlpha = 1;
}

// ─── EASING ──────────────────────────────────────────────────
function easeInOut(t) { return t < 0.5 ? 4*t*t*t : 1 - Math.pow(-2*t+2,3)/2; }

// ─── ANIMATION ───────────────────────────────────────────────
const FPS = 30;
const DUR = 6;
const TOTAL = FPS * DUR;

// Base positions (in 144-grid coords)
const BASE_CX = 72;  // center of canvas
const BASE_CY = 78;  // slightly above center

function render(f, elapsed) {
  const t = elapsed;

  // Bob and sway
  const bobY = Math.sin(t * 1.6) * 3.5;
  const swayX = Math.sin(t * 0.9) * 2.0;
  const hatBob = Math.sin(t * 1.6 + 0.25) * 1.2;

  const cx = BASE_CX + swayX;
  const cy = BASE_CY + bobY;

  // Eye state
  const blinkCycle = Math.floor(t * 2) % 8;
  const lookVal = Math.sin(t * 0.45);
  let eyeState = 'forward';
  if (blinkCycle === 0) eyeState = 'blink';
  else if (lookVal > 0.7) eyeState = 'look_right';
  else if (lookVal < -0.7) eyeState = 'look_left';

  // Clear & draw a compact water patch.
  ctx.clearRect(0, 0, cv.width, cv.height);
  drawWater(cx, cy + 8, t);
  drawWaterElements(cx, cy + 8, t);

  // Ripples behind lily pad
  drawRipples(cx, cy + 6, t);

  // Lily pad
  drawLilyPad(Math.round(cx), Math.round(cy + 6));

  // Occasional splashes
  if (f % 45 === 0) {
    addSplash(cx + (Math.random() - 0.5) * 24, cy + 10, 4);
  }

  // Clawd position (centered on lily pad)
  const clawdW = CLAWD_BODY.width * SCALE; // 42
  const clawdH = CLAWD_BODY.height * SCALE; // 24
  const clawdX = Math.round(cx - clawdW / 2);
  const clawdY = Math.round(cy - clawdH + 4 + bobY * 0.1);

  // Draw Clawd
  drawClawd(clawdX, clawdY, eyeState);

  // Claw idle: left claw raises slightly at times
  const clawRaise = Math.sin(t * 3.0) > 0.85;
  if (clawRaise) {
    // Raise left claw pixels up by 1 SCALE unit
    for (let r = 0; r < 2; r++) {
      for (let c = 0; c < SCALE; c++) {
        // Erase old claw top-left area
        // Draw raised claw
      }
    }
    pxRect(clawdX, clawdY - SCALE, SCALE * 2, SCALE, PALETTE.clawd.body);
    pxRect(clawdX + SCALE, clawdY - SCALE, SCALE, SCALE, PALETTE.clawd.body);
  }

  // Hat on top of Clawd
  drawHat(clawdX, Math.round(clawdY + hatBob * 0.3));

  // Particles
  tickParticles();

  // Lazy bubble
  const bubblePhase = t % DUR;
  if (bubblePhase > 2.5 && bubblePhase < 5.5) {
    const bAlpha = 1.0 - Math.abs(bubblePhase - 4.0) / 1.6;
    const bFloatY = (bubblePhase - 2.5) * 2.5;
    drawBubble(cx + 20, clawdY - 8 - bFloatY, '~~安逸~~呷呷~', bAlpha);
  }
}

// ─── LOOP ────────────────────────────────────────────────────
let startTime = null;

function loop(ts) {
  if (!startTime) startTime = ts;
  const elapsed = (ts - startTime) / 1000;
  const loopT = elapsed % DUR;
  const frame = Math.floor(loopT * FPS);

  if (loopT < 0.05) particles = [];

  render(frame, elapsed);

  document.getElementById('info').textContent =
    `clawd 荷叶漂流 🍃  ${loopT.toFixed(1)}s / ${DUR}.0s  |  loop ${Math.floor(elapsed / DUR) + 1}`;

  requestAnimationFrame(loop);
}

requestAnimationFrame(loop);
