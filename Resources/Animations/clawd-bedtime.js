const cv = document.getElementById('c');
const ctx = cv.getContext('2d');
const info = document.getElementById('info');

const BASE = 36;
let PX = 20;
let GW = BASE;
let GH = BASE;

function resizeCanvas() {
  cv.width = Math.max(1, Math.floor(window.innerWidth * window.devicePixelRatio));
  cv.height = Math.max(1, Math.floor(window.innerHeight * window.devicePixelRatio));
  cv.style.width = `${window.innerWidth}px`;
  cv.style.height = `${window.innerHeight}px`;
  PX = Math.max(8, Math.floor(Math.min(cv.width, cv.height) / BASE));
  GW = Math.ceil(cv.width / PX);
  GH = Math.ceil(cv.height / PX);
}
resizeCanvas();
window.addEventListener('resize', resizeCanvas);

const COL = {
  body: '#CD6E58',
  bodyDark: '#B85E4A',
  eye: '#000000',
  blush: '#F48FB1',
  white: '#FFFFFF',
  cream: '#FFF2C2',
  moon: '#FFE898',
  star: '#FFF2A8',
  wood: '#A86A42',
  woodDark: '#6B4429',
  woodLight: '#C8855A',
  sheet: '#F2EFE9',
  sheetDark: '#D6D0C7',
  pillow: '#FFF7DD',
  blanket: '#7AABBF',
  blanketLight: '#9DC4D4',
  blanketDark: '#5A8FA8',
  cap: '#78B7D6',
  capDark: '#248CC8',
  capBall: '#FFF2C2',
  shadow: '#2B241F',
  text: '#FFF2C2',
  textShadow: '#6B302B'
};

const BODY = [
  [0,0,0,1,1,1,1,1,1,1,1,0,0,0],
  [0,0,0,1,1,1,1,1,1,1,1,0,0,0],
  [0,1,1,1,1,1,1,1,1,1,1,1,1,0],
  [0,1,1,1,1,1,1,1,1,1,1,1,1,0],
  [0,0,0,1,1,1,1,1,1,1,1,0,0,0],
  [0,0,0,1,1,1,1,1,1,1,1,0,0,0],
  [0,0,0,1,0,1,0,0,1,0,1,0,0,0],
  [0,0,0,1,0,1,0,0,1,0,1,0,0,0]
];

const EYES = {
  forward: [[4,1],[9,1]],
  left: [[3,1],[8,1]],
  right: [[5,1],[10,1]],
  down: [[4,2],[9,2]]
};

function clear() {
  ctx.clearRect(0, 0, cv.width, cv.height);
}

function px(x, y, col, alpha = 1) {
  if (x < -4 || y < -4 || x > GW + 4 || y > GH + 4) return;
  ctx.globalAlpha = alpha;
  ctx.fillStyle = col;
  ctx.fillRect(Math.round(x) * PX, Math.round(y) * PX, PX, PX);
  ctx.globalAlpha = 1;
}

function rect(x, y, w, h, col, alpha = 1) {
  ctx.globalAlpha = alpha;
  ctx.fillStyle = col;
  ctx.fillRect(Math.round(x) * PX, Math.round(y) * PX, Math.round(w) * PX, Math.round(h) * PX);
  ctx.globalAlpha = 1;
}

function easeOut(t) { return 1 - (1 - t) ** 3; }
function easeInOut(t) { return t < 0.5 ? 4 * t ** 3 : 1 - (-2 * t + 2) ** 3 / 2; }
function lerp(a, b, t) { return a + (b - a) * t; }
function clamp01(t) { return Math.max(0, Math.min(1, t)); }

function drawClawd(ox, oy, opts = {}) {
  for (let r = 0; r < BODY.length; r++) {
    for (let c = 0; c < BODY[r].length; c++) {
      if (BODY[r][c]) px(ox + c, oy + r, COL.body);
    }
  }

  if (opts.pose === 'throw') {
    rect(ox + 13, oy + 1, 4, 1, COL.body);
    rect(ox + 16, oy, 2, 2, COL.body);
    rect(ox - 3, oy + 3, 4, 1, COL.body);
  } else if (opts.pose === 'run') {
    rect(ox + 13, oy + 2, 3, 1, COL.body);
    rect(ox - 2, oy + 2, 3, 1, COL.body);
    px(ox + 4, oy + 8, COL.bodyDark);
    px(ox + 10, oy + 8, COL.bodyDark);
  } else if (opts.pose === 'tuck') {
    rect(ox + 12, oy + 1, 3, 1, COL.body);
    rect(ox - 1, oy + 1, 2, 1, COL.body);
  }

  if (opts.blush) {
    px(ox + 3, oy + 2, COL.blush);
    px(ox + 10, oy + 2, COL.blush);
  }

  if (opts.eyes === 'closed') {
    rect(ox + 4, oy + 1, 2, 1, COL.eye);
    rect(ox + 9, oy + 1, 2, 1, COL.eye);
  } else {
    for (const [ex, ey] of (EYES[opts.eyes || 'forward'] || EYES.forward)) {
      px(ox + ex, oy + ey, COL.eye);
    }
  }

  if (opts.cap) drawSleepCap(ox + 4, oy - 4, opts.capTilt || 0);
}

function drawClawdHead(ox, oy, opts = {}) {
  for (let r = 0; r < 4; r++) {
    for (let c = 0; c < BODY[r].length; c++) {
      if (BODY[r][c]) px(ox + c, oy + r, COL.body);
    }
  }

  if (opts.blush) {
    px(ox + 3, oy + 2, COL.blush);
    px(ox + 10, oy + 2, COL.blush);
  }

  if (opts.eyes === 'closed') {
    rect(ox + 4, oy + 1, 2, 1, COL.eye);
    rect(ox + 9, oy + 1, 2, 1, COL.eye);
  } else {
    for (const [ex, ey] of (EYES[opts.eyes || 'forward'] || EYES.forward)) {
      px(ox + ex, oy + ey, COL.eye);
    }
  }

  if (opts.cap) drawSleepCap(ox + 4, oy - 4, opts.capTilt || 0);
}

function drawSleepCap(x, y, tilt = 0) {
  const dx = Math.round(tilt);
  rect(x + 1 + dx, y + 2, 8, 2, COL.capDark);
  rect(x + 2 + dx, y + 1, 7, 2, COL.cap);
  rect(x + 4 + dx, y, 5, 1, COL.cap);
  px(x + 9 + dx, y - 1, COL.capBall);
  px(x + 10 + dx, y - 1, COL.capBall);
  px(x + 9 + dx, y, COL.capBall);
}

function drawBed(x, y, opts = {}) {
  const shake = opts.shake || 0;
  const bx = Math.round(x + shake);
  const by = Math.round(y);
  const ghost = opts.alpha ?? 1;

  rect(bx, by + 2, 20, 10, COL.woodDark, ghost);
  rect(bx + 1, by + 3, 18, 7, COL.woodLight, ghost);
  rect(bx + 2, by + 4, 16, 5, COL.sheet, ghost);
  rect(bx + 3, by + 3, 6, 3, COL.pillow, ghost);
  rect(bx + 3, by + 5, 5, 1, COL.sheetDark, ghost);
  rect(bx + 8, by + 6, 10, 3, COL.blanket, ghost);
  rect(bx + 8, by + 6, 10, 1, COL.blanketLight, ghost);
  rect(bx + 17, by + 6, 1, 3, COL.blanketDark, ghost);
  rect(bx + 1, by + 11, 3, 3, COL.woodDark, ghost);
  rect(bx + 16, by + 11, 3, 3, COL.woodDark, ghost);
}

function drawSleepingInBed(x, y, f) {
  drawBed(x, y);
  drawClawdHead(x + 4, y + 4, { eyes: 'closed', cap: true, blush: true });
  rect(x + 5, y + 7, 13, 5, COL.blanket, 1);
  rect(x + 5, y + 7, 13, 1, COL.blanketLight, 1);
  rect(x + 17, y + 7, 1, 5, COL.blanketDark, 1);
  rect(x + 1, y + 11, 18, 1, COL.woodDark, 1);
  drawZzz(x + 16, y + 1, f);
}

function drawZzz(x, y, f) {
  const bob = Math.round(Math.sin(f * 0.08) * 1);
  drawPixelText('z', x, y + 3 + bob, 0.72, COL.sheetDark, COL.shadow, 0.88);
  drawPixelText('z', x + 2, y + 1 + bob, 0.86, COL.sheet, COL.shadow, 0.95);
  drawPixelText('Z', x + 4, y - 2 + bob, 1.06, COL.white, COL.shadow, 1);
}

function drawMoonAndStars(f) {
  const mx = Math.max(4, Math.floor(GW / 2) - 16);
  const my = Math.max(2, Math.floor(GH / 2) - 14);
  rect(mx, my + 1, 4, 4, COL.moon, 0.95);
  rect(mx + 2, my, 2, 1, COL.moon, 0.95);
  rect(mx + 2, my + 5, 2, 1, COL.moon, 0.95);
  ctx.clearRect((mx + 3) * PX, (my + 1) * PX, 2 * PX, 4 * PX);

  const stars = [
    [mx + 8, my + 1], [mx + 12, my + 5], [mx + 3, my + 10],
    [Math.floor(GW / 2) + 12, my + 3], [Math.floor(GW / 2) + 16, my + 9]
  ];
  for (let i = 0; i < stars.length; i++) {
    const [sx, sy] = stars[i];
    const a = 0.45 + 0.45 * Math.max(0, Math.sin(f * 0.09 + i));
    px(sx, sy, COL.star, a);
    if (a > 0.7) {
      px(sx - 1, sy, COL.star, 0.55);
      px(sx + 1, sy, COL.star, 0.55);
      px(sx, sy - 1, COL.star, 0.55);
      px(sx, sy + 1, COL.star, 0.55);
    }
  }
}

function drawMotionTrail(x, y, t) {
  for (let i = 0; i < 3; i++) {
    drawBed(x + i * 3, y + i, { alpha: 0.16 - i * 0.04 });
  }
  for (let i = 0; i < 5; i++) {
    px(x - 2 - i, y + 8 + (i % 2), COL.white, 0.45);
  }
}

function drawPixelText(text, x, y, size, fill, shadow, alpha = 1) {
  const fontSize = Math.round(size * PX * 1.55);
  ctx.save();
  ctx.globalAlpha = alpha;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  ctx.font = `900 ${fontSize}px "Menlo", "Monaco", "Courier New", monospace`;
  ctx.fillStyle = shadow;
  ctx.fillText(text, Math.round(x * PX) + Math.round(PX * 0.12), Math.round(y * PX) + Math.round(PX * 0.12));
  ctx.fillStyle = fill;
  ctx.fillText(text, Math.round(x * PX), Math.round(y * PX));
  ctx.restore();
}

function drawBottomMessage(f) {
  const center = GW / 2;
  const y = Math.min(GH - 5.8, Math.floor(GH / 2) + 12.4);
  const pulse = 0.92 + 0.08 * Math.sin(f * 0.12);
  drawPixelText('TIME TO SLEEP!!!', center, y, 1.18 * pulse, COL.text, COL.textShadow, 1);
  drawPixelText('YOUR BODY COMES FIRST', center, y + 2.15, 0.72, COL.white, COL.textShadow, 0.95);
}

function phase(localT, start, end) {
  return clamp01((localT - start) / (end - start));
}

function render(f) {
  clear();

  const t = (f % TOTAL) / TOTAL;
  const centerX = Math.floor(GW / 2);
  const centerY = Math.max(12, Math.floor(GH / 2) - 5);
  const finalBedX = centerX - 10;
  const finalBedY = centerY - 6;
  const readyBedX = Math.min(centerX + 5, GW - 22);
  const readyBedY = centerY + 3;
  const startClawdX = readyBedX - 13;
  const throwClawdX = Math.max(2, finalBedX - 15);
  const floorY = readyBedY + 3;

  drawMoonAndStars(f);

  if (t < 0.24) {
    const p = phase(t, 0, 0.24);
    const bob = Math.floor(f / 8) % 2 === 0 ? -1 : 0;
    const shake = Math.sin(f * 0.7) > 0.72 ? 1 : 0;
    drawBed(readyBedX, readyBedY, { shake });
    drawClawd(startClawdX, floorY + bob, {
      eyes: p < 0.45 ? 'right' : 'down',
      cap: p > 0.28,
      capTilt: Math.sin(f * 0.2)
    });
    if (p < 0.3) {
      drawSleepCap(startClawdX + 9, floorY - 8 + Math.round((1 - p / 0.3) * 3), 0);
    }
  } else if (t < 0.40) {
    const p = easeInOut(phase(t, 0.24, 0.40));
    const bedX = Math.round(lerp(readyBedX, readyBedX - 2, Math.sin(p * Math.PI)));
    const bedY = Math.round(lerp(readyBedY, readyBedY - 2, Math.sin(p * Math.PI)));
    drawBed(bedX, bedY, { shake: Math.sin(f * 1.2) > 0 ? 1 : -1 });
    drawClawd(startClawdX, floorY - Math.round(Math.sin(p * Math.PI) * 2), {
      eyes: 'right',
      cap: true,
      pose: 'throw',
      capTilt: 1
    });
    drawPixelText('READY?', startClawdX + 9, floorY - 7, 0.74, COL.white, COL.textShadow, 0.88);
  } else if (t < 0.58) {
    const p = easeOut(phase(t, 0.40, 0.58));
    const arc = Math.sin(p * Math.PI) * -8;
    const bedX = Math.round(lerp(readyBedX - 2, finalBedX, p));
    const bedY = Math.round(lerp(readyBedY - 2, finalBedY, p) + arc);
    const clawdX = Math.round(lerp(startClawdX, throwClawdX, Math.min(1, p * 1.15)));
    drawMotionTrail(bedX + 2, bedY + 2, p);
    drawBed(bedX, bedY);
    drawClawd(clawdX, floorY - 1, {
      eyes: 'right',
      cap: true,
      pose: 'throw',
      capTilt: 1
    });
  } else if (t < 0.74) {
    const p = easeInOut(phase(t, 0.58, 0.74));
    const runX = Math.round(lerp(throwClawdX, finalBedX + 2, p));
    const runY = Math.round(lerp(floorY, finalBedY + 5, p)) + (Math.floor(f / 5) % 2 === 0 ? -1 : 0);
    drawBed(finalBedX, finalBedY);
    drawClawd(runX, runY, {
      eyes: 'right',
      cap: true,
      pose: 'run',
      capTilt: Math.sin(f * 0.4)
    });
    for (let i = 0; i < 4; i++) px(runX - 2 - i, runY + 7 + (i % 2), COL.sheetDark, 0.5);
  } else if (t < 0.88) {
    const p = easeOut(phase(t, 0.74, 0.88));
    const climbX = Math.round(lerp(finalBedX + 2, finalBedX + 4, p));
    const climbY = Math.round(lerp(finalBedY + 5, finalBedY + 4, p));
    drawBed(finalBedX, finalBedY);
    if (p < 0.58) {
      drawClawd(climbX, climbY, {
        eyes: 'down',
        cap: true,
        pose: 'tuck',
        blush: p > 0.45
      });
    } else {
      drawClawdHead(finalBedX + 4, finalBedY + 4, {
        eyes: p > 0.78 ? 'closed' : 'down',
        cap: true,
        blush: true
      });
    }
    rect(finalBedX + 6, finalBedY + 7, Math.round(12 * p), 5, COL.blanket, 1);
    rect(finalBedX + 6, finalBedY + 7, Math.round(12 * p), 1, COL.blanketLight, 1);
    rect(finalBedX + 1, finalBedY + 11, 18, 1, COL.woodDark, 1);
  } else {
    drawSleepingInBed(finalBedX, finalBedY, f);
  }

  drawBottomMessage(f);
}

const FPS = 30;
const DUR = 8;
const TOTAL = FPS * DUR;
let startTime = null;

function loop(ts) {
  if (startTime === null) startTime = ts;
  const elapsed = (ts - startTime) / 1000;
  const frame = Math.floor((elapsed % DUR) * FPS);
  render(frame);
  if (info) info.textContent = `clawd bedtime ${elapsed.toFixed(1)}s`;
  requestAnimationFrame(loop);
}

const debugFrame = new URLSearchParams(window.location.search).get('frame');
if (debugFrame !== null) {
  render(Number(debugFrame) || 0);
} else {
  requestAnimationFrame(loop);
}
