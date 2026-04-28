const cv = document.getElementById('c');
const ctx = cv.getContext('2d');

// ─── PALETTE ─────────────────────────────────────────────────
const PALETTE = {
  background: { bg: '#F9F7F4', dot: '#E0DDD8' },
  stars:      { dark: '#333333', mid: '#888888', light: '#BBBBBB' },
  clawd:      { body: '#CD6E58', eye: '#000000' },
  kiss:       { pink: '#F06090', light: '#FAC8D8', deep: '#C84060' },
  ui:         { white: '#FFFFFF' }
};

// ─── CANVAS SIZING ──────────────────────────────────────────
function resizeCanvas() {
  cv.width = window.innerWidth;
  cv.height = window.innerHeight;
}
resizeCanvas();
window.addEventListener('resize', resizeCanvas);

// ─── PIXEL GRID ──────────────────────────────────────────────
const PX = 20;

function px(gx, gy, col) {
  ctx.fillStyle = col;
  ctx.fillRect(gx * PX, gy * PX, PX, PX);
}

// ─── CLAWD BODY ──────────────────────────────────────────────
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
    eyeLeft:   { x: 4,  y: 1 },
    eyeRight:  { x: 9,  y: 1 },
    hatTop:    { x: 7,  y: -1 },
    handLeft:  { x: 0,  y: 2 },
    handRight: { x: 13, y: 2 },
    sitBottom: { x: 7,  y: 8 }
  }
};

const EYES = {
  forward:    { left: {dx:0,dy:0}, right: {dx:0,dy:0} },
  look_right: { left: {dx:1,dy:0}, right: {dx:1,dy:0} },
  look_left:  { left: {dx:-1,dy:0}, right: {dx:-1,dy:0} },
  look_down:  { left: {dx:0,dy:1}, right: {dx:0,dy:1} },
  blink:      { type: 'hidden' }
};

// Heart sprite (5×4)
const HEART = [
  [1,0,1,0,0],
  [1,1,1,1,0],
  [0,1,1,1,0],
  [0,0,1,0,0]
];

// Kiss mark sprite (4×4)
const LIPMARK = [
  [0,1,0,1],
  [1,1,1,1],
  [0,1,1,0],
  [0,0,1,0]
];

// ─── BACKGROUND ──────────────────────────────────────────────
function generateStars() {
  const stars = [];
  const gw = Math.ceil(cv.width / PX);
  const gh = Math.ceil(cv.height / PX);
  let seed = 12345;
  function rand() { seed = (seed * 16807 + 0) % 2147483647; return seed / 2147483647; }
  const count = Math.max(30, Math.floor(gw * gh / 50));
  const types = ['dark', 'dark', 'dark', 'mid', 'mid', 'light'];
  for (let i = 0; i < count; i++) {
    stars.push({
      x: Math.floor(rand() * gw),
      y: Math.floor(rand() * gh),
      type: types[Math.floor(rand() * types.length)]
    });
  }
  return stars;
}
let STAR_POSITIONS = generateStars();
window.addEventListener('resize', () => { STAR_POSITIONS = generateStars(); });

function drawBg() {
  ctx.clearRect(0, 0, cv.width, cv.height);
}

function drawStars(f) {
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  for (const s of STAR_POSITIONS) {
    const twinkle = Math.sin(f * 0.08 + s.x * 0.5 + s.y * 0.3);
    let col;
    if (s.type === 'dark') col = twinkle > 0 ? PALETTE.stars.dark : PALETTE.stars.mid;
    else if (s.type === 'mid') col = twinkle > 0.3 ? PALETTE.stars.mid : PALETTE.stars.light;
    else col = twinkle > 0 ? PALETTE.stars.light : PALETTE.background.dot;
    ctx.fillStyle = col;
    ctx.font = `bold ${s.type === 'dark' ? 14 : 10}px serif`;
    ctx.fillText('✳', s.x * PX + PX/2, s.y * PX + PX/2);
  }
}

// ─── DRAW FUNCTIONS ──────────────────────────────────────────

// Clawd 没有嘴巴——情绪靠眼睛、腮红、粒子、气泡表达
function drawClawd(ox, oy, opts = {}) {
  const eyeVariant = opts.eyes || 'forward';
  const bodyCol = PALETTE.clawd.body;
  const eyeCol = PALETTE.clawd.eye;

  for (let r = 0; r < CLAWD_BODY.height; r++) {
    for (let c = 0; c < CLAWD_BODY.width; c++) {
      if (CLAWD_BODY.data[r][c] === 1) px(ox + c, oy + r, bodyCol);
    }
  }

  const ev = EYES[eyeVariant];
  if (ev && ev.type !== 'hidden') {
    const el = CLAWD_BODY.anchors.eyeLeft;
    const er = CLAWD_BODY.anchors.eyeRight;
    px(ox + el.x + ev.left.dx, oy + el.y + ev.left.dy, eyeCol);
    px(ox + er.x + ev.right.dx, oy + er.y + ev.right.dy, eyeCol);
  }
}

// 腮红：眼睛下方两侧的粉色像素，表达害羞/亲亲的甜蜜感
function drawBlush(ox, oy, alpha) {
  ctx.globalAlpha = Math.max(0, Math.min(1, alpha));
  px(ox + 3, oy + 2, PALETTE.kiss.light);
  px(ox + 10, oy + 2, PALETTE.kiss.light);
  ctx.globalAlpha = 1;
}

function drawHeart(hx, hy, col) {
  for (let r = 0; r < HEART.length; r++) {
    for (let c = 0; c < HEART[r].length; c++) {
      if (HEART[r][c] === 1) px(hx + c - 1, hy + r, col);
    }
  }
}

function drawKissMark(kx, ky, alpha) {
  ctx.globalAlpha = Math.max(0, Math.min(1, alpha));
  for (let r = 0; r < LIPMARK.length; r++) {
    for (let c = 0; c < LIPMARK[r].length; c++) {
      if (LIPMARK[r][c]) px(kx + c, ky + r, PALETTE.kiss.pink);
    }
  }
  ctx.globalAlpha = 1;
}

function drawMwahText(nx, ny, alpha) {
  ctx.globalAlpha = Math.max(0, Math.min(1, alpha));
  ctx.fillStyle = PALETTE.kiss.deep;
  ctx.font = 'bold 20px Courier New';
  ctx.textAlign = 'left';
  ctx.textBaseline = 'top';
  ctx.fillText('Mwah~', nx * PX, ny * PX);
  ctx.globalAlpha = 1;
}

// ─── PARTICLE SYSTEM ─────────────────────────────────────────
let particles = [];

function addParticle(x, y, col) {
  particles.push({
    x, y,
    vx: (Math.random() - 0.5) * 0.8,
    vy: -Math.random() * 0.8 - 0.3,
    life: 1.0,
    col
  });
}

function tickParticles() {
  for (let i = particles.length - 1; i >= 0; i--) {
    const p = particles[i];
    p.x += p.vx;
    p.y += p.vy;
    p.vy += 0.04;
    p.life -= 0.02;
    if (p.life <= 0) { particles.splice(i, 1); continue; }
    if (p.life > 0.15) px(Math.round(p.x), Math.round(p.y), p.col);
  }
}

// ─── EASING ──────────────────────────────────────────────────
function easeOut(t) { return 1 - Math.pow(1 - t, 3); }
function easeInOut(t) { return t < 0.5 ? 4*t*t*t : 1 - Math.pow(-2*t+2, 3) / 2; }
function lerp(a, b, t) { return a + (b - a) * t; }

// ─── ANIMATION ───────────────────────────────────────────────
const FPS = 30;
const DUR = 5;
const TOTAL = FPS * DUR;

function getPhase(t) {
  if (t < 0.15) return { ph: 'enter',  pt: t / 0.15 };
  if (t < 0.30) return { ph: 'look',   pt: (t - 0.15) / 0.15 };
  if (t < 0.48) return { ph: 'lean',   pt: (t - 0.30) / 0.18 };
  if (t < 0.63) return { ph: 'kiss',   pt: (t - 0.48) / 0.15 };
  if (t < 0.80) return { ph: 'happy',  pt: (t - 0.63) / 0.17 };
  return                 { ph: 'settle', pt: (t - 0.80) / 0.20 };
}

function render(f) {
  const t = f / TOTAL;
  const { ph, pt } = getPhase(t);

  drawBg();
  // ── Layout (centered on screen) ──
  const gw = Math.ceil(cv.width / PX);
  const gh = Math.ceil(cv.height / PX);
  const centerX = Math.floor(gw / 2);
  const centerY = Math.floor(gh / 2);
  const homeX = centerX - 7;
  const homeY = centerY - 4;

  let cx = homeX, cy = homeY;
  let eyes = 'forward';
  let bounce = 0;
  let blushAlpha = 0;
  let kissAlpha = 0, kissX = 0, kissY = 0;
  let mwahAlpha = 0, mwahX = homeX + 10, mwahY = homeY - 5;
  let showSideHeart = false;

  // enter: 从左侧走进来，轻快步伐
  if (ph === 'enter') {
    cx = Math.round(lerp(-15, homeX, easeOut(pt)));
    bounce = Math.sin(pt * Math.PI * 5) * 0.5;
  }

  // look: 停下，眨眼
  else if (ph === 'look') {
    cx = homeX;
    bounce = Math.sin(pt * Math.PI * 2) * 0.2;
    eyes = (pt > 0.35 && pt < 0.62) ? 'blink' : 'forward';
  }

  // lean: 身体前倾，腮红渐现，眼神低下（害羞预备）
  else if (ph === 'lean') {
    cx = Math.round(lerp(homeX, homeX + 1, easeInOut(Math.min(1, pt * 2))));
    bounce = Math.sin(pt * Math.PI) * -0.5;
    eyes = pt < 0.5 ? 'forward' : 'look_down';
    blushAlpha = easeInOut(pt) * 0.7;
  }

  // kiss: 闭眼！腮红加深，爱心爆炸，Mwah~
  else if (ph === 'kiss') {
    cx = homeX + 1;
    bounce = -0.5 + Math.sin(pt * Math.PI * 3) * 0.15;
    eyes = 'blink';
    blushAlpha = 0.7 + pt * 0.3;

    if (pt < 0.55 && f % 2 === 0) {
      addParticle(cx + 9 + (Math.random() - 0.5) * 5, cy + 2, PALETTE.kiss.pink);
      addParticle(cx + 9 + (Math.random() - 0.5) * 5, cy + 2, PALETTE.kiss.light);
    }

    kissAlpha = Math.min(1, pt * 5);
    kissX = cx + 14 + Math.round(pt * 4);
    kissY = cy + 1 - Math.round(pt * 5);

    mwahAlpha = pt > 0.3 ? Math.min(1, (pt - 0.3) / 0.25) : 0;
    mwahX = homeX + 10;
    mwahY = homeY - 5;
  }

  // happy: 弹开，爱心飘散，腮红慢退
  else if (ph === 'happy') {
    cx = Math.round(lerp(homeX + 1, homeX, easeOut(Math.min(1, pt * 1.5))));
    bounce = Math.sin(pt * Math.PI * 4) * 0.9;
    eyes = 'forward';
    blushAlpha = Math.max(0, 0.9 - pt * 1.2);

    if (f % 3 === 0) {
      addParticle(cx + 7 + (Math.random() - 0.5) * 6, cy + 1, PALETTE.kiss.pink);
      addParticle(cx + 7 + (Math.random() - 0.5) * 6, cy + 1, PALETTE.kiss.light);
    }

    mwahAlpha = Math.max(0, 1 - pt * 3);
    mwahX = homeX + 10;
    mwahY = homeY - 5 - Math.round(pt * 2);
    kissAlpha = Math.max(0, 1 - pt * 4);
    kissX = homeX + 19 + Math.round(pt * 2);
    kissY = homeY - 4 - Math.round(pt * 2);

    showSideHeart = true;
  }

  // settle: 回原位，腮红消退
  else if (ph === 'settle') {
    cx = homeX;
    bounce = Math.sin(pt * Math.PI * 2) * 0.15;
    eyes = 'forward';
    blushAlpha = Math.max(0, 0.3 - pt * 0.3);
    showSideHeart = pt < 0.4;
  }

  // 绘制 Clawd（无嘴巴）
  drawClawd(cx, Math.round(cy + bounce), { eyes });

  // 腮红叠在身体色上
  drawBlush(cx, Math.round(cy + bounce), blushAlpha);

  // 粒子
  tickParticles();

  // 侧边浮动爱心
  if (showSideHeart) {
    const hbob = Math.sin(f * 0.25) * 0.4;
    drawHeart(cx + 15, Math.round(cy - 1 + hbob), PALETTE.kiss.pink);
    if (ph === 'happy' && pt > 0.25) {
      drawHeart(cx + 16, Math.round(cy - 4 + hbob * 1.3), PALETTE.kiss.light);
    }
  }

  // Kiss mark
  if (kissAlpha > 0) drawKissMark(kissX, kissY, kissAlpha);

  // Mwah~ 文字
  if (mwahAlpha > 0) drawMwahText(mwahX, mwahY, mwahAlpha);
}

// ─── LOOP ────────────────────────────────────────────────────
let startTime = null;

function loop(ts) {
  if (!startTime) startTime = ts;
  const elapsed = (ts - startTime) / 1000;
  const loopT = elapsed % DUR;
  const frame = Math.floor(loopT * FPS);

  if (loopT < 0.05) particles = [];

  render(frame);

  document.getElementById('info').textContent =
    `clawd 在亲亲 ♡  —  ${loopT.toFixed(1)}s / ${DUR}.0s  |  loop ${Math.floor(elapsed / DUR) + 1}`;

  requestAnimationFrame(loop);
}

requestAnimationFrame(loop);