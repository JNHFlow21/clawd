const cv  = document.getElementById('c');
const ctx = cv.getContext('2d');
const PX  = 20;
const GW  = 36, GH = 36;

// ═══════════════════════════════════════════════
// COLORS
// ═══════════════════════════════════════════════
const COL = {
  skyTop:    '#87CEEB',
  skyBot:    '#B3E5FC',
  sea:       '#29B6F6',
  seaDark:   '#0288D1',
  seaFoam:   '#E3F2FD',
  sand:      '#F5DEB3',
  sandDark:  '#DEB887',
  sun:       '#FFD700',
  sunHalo:   '#FFF176',
  cloud:     '#FFFFFF',
  body:      '#CD6E58',
  bodyDark:  '#B85E4A',
  eye:       '#000000',
  coconut:   '#7D5A3C',
  coconutLt: '#A67B5B',
  liquid:    '#FFFDE7',
  straw:     '#EF5350',
  heart:     '#EC407A',
  heartLt:   '#F48FB1',
};

function px(x, y, col) {
  ctx.fillStyle = col;
  ctx.fillRect(Math.round(x) * PX, Math.round(y) * PX, PX, PX);
}

// ═══════════════════════════════════════════════
// BEACH BACKGROUND
// ═══════════════════════════════════════════════
const SEA_Y  = 22;
const SAND_Y = 26;

function drawBg() {
  ctx.clearRect(0, 0, cv.width, cv.height);
}

function drawSun() {
  const sx = 29, sy = 2;
  // Halo
  ctx.fillStyle = COL.sunHalo;
  ctx.fillRect((sx - 1) * PX, (sy - 1) * PX, 4 * PX, 4 * PX);
  // Core
  ctx.fillStyle = COL.sun;
  ctx.fillRect(sx * PX, sy * PX, 2 * PX, 2 * PX);
}

function drawWaves(f) {
  for (let gx = 0; gx < GW; gx++) {
    if (Math.sin(gx * 0.7 + f * 0.13) > 0.45) {
      px(gx, SEA_Y, COL.seaFoam);
    }
  }
}

function drawCloud(cx, cy) {
  const c = COL.cloud;
  px(cx+1,cy,c); px(cx+2,cy,c); px(cx+3,cy,c);
  px(cx,cy+1,c); px(cx+1,cy+1,c); px(cx+2,cy+1,c); px(cx+3,cy+1,c); px(cx+4,cy+1,c);
  px(cx+1,cy+2,c); px(cx+2,cy+2,c); px(cx+3,cy+2,c);
}

// ═══════════════════════════════════════════════
// CLAWD SPRITE
// ═══════════════════════════════════════════════
const BODY = [
  [0,0,0,1,1,1,1,1,1,1,1,0,0,0],  // 0 head
  [0,0,0,1,1,1,1,1,1,1,1,0,0,0],  // 1 eyes drawn on top
  [0,1,1,1,1,1,1,1,1,1,1,1,1,0],  // 2 arms
  [0,1,1,1,1,1,1,1,1,1,1,1,1,0],  // 3 arms
  [0,0,0,1,1,1,1,1,1,1,1,0,0,0],  // 4 belly
  [0,0,0,1,1,1,1,1,1,1,1,0,0,0],  // 5 belly
  [0,0,0,1,0,1,0,0,1,0,1,0,0,0],  // 6 legs
  [0,0,0,1,0,1,0,0,1,0,1,0,0,0],  // 7 legs
];

const EYES = {
  forward:    [[4,1],[9,1]],
  look_right: [[5,1],[10,1]],
  look_left:  [[3,1],[8,1]],
  blink:      [],
};

function drawClawd(ox, oy, { eyes = 'forward' } = {}) {
  for (let r = 0; r < BODY.length; r++)
    for (let c = 0; c < BODY[r].length; c++)
      if (BODY[r][c]) px(ox+c, oy+r, COL.body);
  for (const [ec, er] of (EYES[eyes] || []))
    px(ox+ec, oy+er, COL.eye);
}

// ═══════════════════════════════════════════════
// COCONUT DRINK — 8 wide × 9 tall
// 0=empty 1=shell 2=liquid 3=straw 4=shell highlight
// ═══════════════════════════════════════════════
const COCONUT = [
  [0,0,0,3,0,0,0,0],  // straw tip
  [0,0,0,3,0,0,0,0],  // straw
  [0,0,0,3,0,0,0,0],  // straw
  [0,1,2,2,2,2,1,0],  // top opening with liquid
  [1,1,2,2,2,2,1,1],  // upper body
  [1,4,1,1,1,1,4,1],  // mid with highlight
  [1,1,1,1,1,1,1,1],  // mid body
  [0,1,1,1,1,1,1,0],  // lower
  [0,0,1,1,1,1,0,0],  // bottom
];
const CPAL = { 1: COL.coconut, 2: COL.liquid, 3: COL.straw, 4: COL.coconutLt };

function drawCoconut(kx, ky) {
  for (let r = 0; r < COCONUT.length; r++)
    for (let c = 0; c < COCONUT[r].length; c++) {
      const v = COCONUT[r][c];
      if (v) px(kx+c, ky+r, CPAL[v]);
    }
}

// ═══════════════════════════════════════════════
// HEART + PARTICLES
// ═══════════════════════════════════════════════
function drawHeart(hx, hy, col) {
  px(hx,   hy,   col); px(hx+2, hy,   col);
  px(hx-1, hy+1, col); px(hx,   hy+1, col); px(hx+1, hy+1, col); px(hx+2, hy+1, col); px(hx+3, hy+1, col);
  px(hx,   hy+2, col); px(hx+1, hy+2, col); px(hx+2, hy+2, col);
  px(hx+1, hy+3, col);
}

let particles = [];
function addParticle(x, y, col) {
  particles.push({
    x, y,
    vx: (Math.random() - 0.5) * 0.5,
    vy: -Math.random() * 0.7 - 0.3,
    life: 1.0, col,
  });
}
function tickParticles() {
  for (let i = particles.length - 1; i >= 0; i--) {
    const p = particles[i];
    p.x += p.vx; p.y += p.vy; p.vy += 0.025; p.life -= 0.02;
    if (p.life <= 0) { particles.splice(i, 1); continue; }
    if (p.life > 0.15) drawHeart(Math.round(p.x), Math.round(p.y), p.col);
  }
}

function drawFloatingText(text, gx, gy, alpha) {
  ctx.globalAlpha = alpha;
  ctx.fillStyle = COL.heart;
  ctx.font = 'bold 18px Courier New';
  ctx.textAlign = 'center';
  ctx.fillText(text, gx * PX, gy * PX);
  ctx.globalAlpha = 1;
}

// ═══════════════════════════════════════════════
// ANIMATION
// ═══════════════════════════════════════════════
const FPS = 30, DUR = 5, TOTAL = FPS * DUR;

// Layout positions
const HOME_X = 2;
const NEAR_X = 11;
const CY     = 18;   // Clawd top Y (feet land at SAND_Y=26)
const KX     = 21;   // Coconut X
const KY     = 18;   // Coconut Y (bottom lands at row 26)

function getPhase(t) {
  if (t < 0.10) return { ph: 'enter',    pt:  t / 0.10 };
  if (t < 0.22) return { ph: 'spot',     pt: (t - 0.10) / 0.12 };
  if (t < 0.38) return { ph: 'approach', pt: (t - 0.22) / 0.16 };
  if (t < 0.48) return { ph: 'grab',     pt: (t - 0.38) / 0.10 };
  if (t < 0.65) return { ph: 'drink1',   pt: (t - 0.48) / 0.17 };
  if (t < 0.80) return { ph: 'drink2',   pt: (t - 0.65) / 0.15 };
  return               { ph: 'happy',    pt: (t - 0.80) / 0.20 };
}

function easeOut(t)   { return 1 - (1 - t) ** 3; }
function easeInOut(t) { return t < 0.5 ? 4 * t ** 3 : 1 - (-2 * t + 2) ** 3 / 2; }
function lerp(a, b, t) { return a + (b - a) * t; }

let startTime = null;

function render(f) {
  const t = f / TOTAL;
  const { ph, pt } = getPhase(t);

  // Scene
  drawBg();
  drawSun();
  drawWaves(f);
  drawCloud(2, 4);
  drawCloud(17, 5);

  // Clawd state
  let cx = HOME_X, bounce = 0;
  let eyes = 'forward';
  let showAhh = false, ahhAlpha = 0;

  switch (ph) {

    case 'enter':
      cx = Math.round(lerp(-14, HOME_X, easeOut(pt)));
      bounce = f % 10 < 5 ? -1 : 0;
      break;

    case 'spot':
      cx = HOME_X;
      if (pt > 0.3 && pt < 0.65) bounce = -1;
      if (pt > 0.65) bounce = -2;
      eyes = pt > 0.45 ? 'look_right' : 'forward';
      break;

    case 'approach':
      cx     = Math.round(lerp(HOME_X, NEAR_X, easeInOut(pt)));
      bounce = f % 10 < 5 ? -1 : 0;
      eyes   = 'look_right';
      break;

    case 'grab':
      cx     = NEAR_X;
      bounce = pt > 0.5 ? -1 : 0;
      eyes   = 'look_right';
      break;

    case 'drink1': {
      cx = NEAR_X;
      const s = Math.sin(f * 0.45);
      eyes   = s > 0.2 ? 'blink' : 'look_right';
      bounce = s > 0 ? -2 : -1;
      break;
    }

    case 'drink2': {
      cx = NEAR_X;
      const s2 = Math.sin(f * 0.4);
      eyes   = s2 > 0.3 ? 'blink' : 'look_right';
      bounce = s2 > 0 ? -2 : -1;
      if (pt > 0.5) {
        showAhh  = true;
        ahhAlpha = Math.min(1, (pt - 0.5) * 3);
      }
      break;
    }

    case 'happy': {
      cx = NEAR_X;
      const b = Math.sin(f * 0.5);
      eyes   = b > 0.4 ? 'blink' : 'forward';
      bounce = b > 0 ? -2 : 0;
      if (f % 7 === 0) {
        addParticle(cx + 5, CY - 1, COL.heart);
        addParticle(cx + 9, CY - 2, COL.heartLt);
      }
      break;
    }
  }

  // Draw coconut (behind Clawd so claw appears in front)
  drawCoconut(KX, KY);

  // Draw Clawd
  drawClawd(cx, CY + bounce, { eyes });

  // Overlays
  if (showAhh) drawFloatingText('AHH~ ♥', cx + 7, CY - 4, ahhAlpha);
  tickParticles();

  document.getElementById('info').textContent =
    `clawd at the beach — ${(f / FPS).toFixed(1)}s / ${DUR}.0s`;
}

// ═══════════════════════════════════════════════
// LOOP
// ═══════════════════════════════════════════════
function loop(ts) {
  if (!startTime) startTime = ts;
  const f = Math.floor(((ts - startTime) / 1000 % DUR) * FPS);
  if (f !== loop.prev) {
    if (f < (loop.prev ?? 999)) particles = [];
    loop.prev = f;
    render(f);
  }
  requestAnimationFrame(loop);
}

requestAnimationFrame(loop);