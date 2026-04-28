const cv = document.getElementById('c');
const ctx = cv.getContext('2d');
const PX = 20;
const GW = 36;
const GH = 36;
const FPS = 30;
const DUR = 5;
const TOTAL = FPS * DUR;
const SCENE = document.body.dataset.scene || 'coffee';

cv.width = 720;
cv.height = 720;

const COL = {
  body: '#CD6E58',
  bodyDark: '#B85E4A',
  eye: '#000000',
  white: '#FFFFFF',
  cream: '#FFF2C2',
  paper: '#FFF7DD',
  paperDark: '#E3D3A4',
  wood: '#8B6642',
  woodDark: '#5E432B',
  coffee: '#6A3A22',
  cup: '#F2F5F7',
  cupBlue: '#78B7D6',
  screen: '#3D4C55',
  screenLight: '#9FE6C1',
  key: '#D9DEE5',
  keyDark: '#87919C',
  red: '#E95B4F',
  pink: '#F48FB1',
  heart: '#EC407A',
  yellow: '#FFE07A',
  green: '#75C782',
  mint: '#9ED8B8',
  blue: '#62BDE8',
  blueDark: '#248CC8',
  purple: '#B78BE8',
  gray: '#888888',
  dark: '#333333',
  line: '#000000'
};

function px(x, y, col, alpha = 1) {
  if (x < -2 || y < -2 || x > GW + 2 || y > GH + 2) return;
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

function clear() {
  ctx.clearRect(0, 0, cv.width, cv.height);
}

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
  look_right: [[5,1],[10,1]],
  look_left: [[3,1],[8,1]],
  blink: []
};

function drawClawd(ox, oy, opts = {}) {
  const eyes = opts.eyes || 'forward';
  for (let r = 0; r < BODY.length; r++) {
    for (let c = 0; c < BODY[r].length; c++) {
      if (BODY[r][c]) px(ox + c, oy + r, COL.body);
    }
  }
  if (eyes === 'closed') {
    rect(ox + 4, oy + 1, 2, 1, COL.eye);
    rect(ox + 9, oy + 1, 2, 1, COL.eye);
    return;
  }
  for (const [ec, er] of (EYES[eyes] || EYES.forward)) px(ox + ec, oy + er, COL.eye);
}

function drawHeart(x, y, col = COL.heart) {
  px(x, y, col); px(x + 2, y, col);
  px(x - 1, y + 1, col); px(x, y + 1, col); px(x + 1, y + 1, col); px(x + 2, y + 1, col); px(x + 3, y + 1, col);
  px(x, y + 2, col); px(x + 1, y + 2, col); px(x + 2, y + 2, col);
  px(x + 1, y + 3, col);
}

function drawBubble(x, y, w, h, col = COL.white, alpha = 0.92) {
  rect(x + 1, y, w - 2, h, col, alpha);
  rect(x, y + 1, w, h - 2, col, alpha);
  rect(x + 2, y + h, 3, 2, col, alpha);
}

function drawLabel(text, x, y, size, col = COL.dark, alpha = 1) {
  ctx.globalAlpha = alpha;
  ctx.fillStyle = col;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'top';
  ctx.font = `900 ${Math.round(size * PX)}px "PingFang SC", "Hiragino Sans GB", Courier New, monospace`;
  ctx.fillText(text, x * PX, y * PX);
  ctx.globalAlpha = 1;
}

function drawBubbleText(lines, x, y, w, h, opts = {}) {
  drawBubble(x, y, w, h, opts.bubbleColor || COL.white, opts.alpha ?? 0.92);
  ctx.globalAlpha = opts.textAlpha ?? 1;
  ctx.fillStyle = opts.color || COL.dark;
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  const fontSize = Math.round((opts.size || 1.05) * PX);
  ctx.font = `900 ${fontSize}px "PingFang SC", "Hiragino Sans GB", Arial, sans-serif`;
  const list = Array.isArray(lines) ? lines : [lines];
  const lineHeight = fontSize * 1.2;
  const centerY = (y + h / 2) * PX;
  const startY = centerY - ((list.length - 1) * lineHeight) / 2;
  for (let i = 0; i < list.length; i++) {
    ctx.fillText(list[i], (x + w / 2) * PX, startY + i * lineHeight);
  }
  ctx.globalAlpha = 1;
}

function easeOut(t) { return 1 - (1 - t) ** 3; }
function easeInOut(t) { return t < 0.5 ? 4 * t ** 3 : 1 - (-2 * t + 2) ** 3 / 2; }
function lerp(a, b, t) { return a + (b - a) * t; }
function pulse(f, speed = 0.35) { return Math.sin(f * speed); }
function wrapFrame(f) { return f % TOTAL; }

function drawSteam(x, y, f) {
  for (let i = 0; i < 3; i++) {
    const yy = y - ((f / 8 + i * 3) % 9);
    const xx = x + i * 2 + Math.round(Math.sin(f * 0.18 + i) * 1);
    px(xx, yy, COL.white, 0.75);
    px(xx, yy + 1, COL.white, 0.45);
  }
}

function drawMug(x, y, f) {
  rect(x, y + 2, 7, 5, COL.cup);
  rect(x + 1, y + 1, 5, 2, COL.coffee);
  rect(x + 7, y + 3, 2, 3, COL.cup);
  rect(x + 2, y + 4, 2, 2, COL.cupBlue);
  drawSteam(x + 2, y, f);
}

function drawKeyboard(x, y, f) {
  rect(x, y, 15, 5, COL.keyDark);
  rect(x + 1, y + 1, 13, 3, COL.key);
  for (let r = 0; r < 2; r++) {
    for (let c = 0; c < 6; c++) {
      const hot = (f + c * 3 + r * 7) % 18 < 4;
      rect(x + 2 + c * 2, y + 1 + r, 1, 1, hot ? COL.yellow : COL.keyDark);
    }
  }
}

function drawMonitor(x, y, f) {
  rect(x, y, 13, 8, COL.dark);
  rect(x + 1, y + 1, 11, 6, COL.screen);
  const cursor = Math.floor(f / 12) % 2 === 0;
  rect(x + 3, y + 3, 4, 1, COL.screenLight);
  rect(x + 3, y + 5, 6, 1, COL.blue);
  if (cursor) rect(x + 10, y + 5, 1, 1, COL.white);
  rect(x + 5, y + 8, 3, 2, COL.gray);
}

function drawBook(x, y, f, open = true) {
  if (!open) {
    rect(x, y, 10, 8, COL.paperDark);
    rect(x + 1, y + 1, 8, 6, COL.paper);
    return;
  }
  rect(x, y + 1, 8, 8, COL.paper);
  rect(x + 8, y + 1, 8, 8, COL.paper);
  rect(x + 7, y, 2, 10, COL.paperDark);
  for (let i = 0; i < 3; i++) {
    rect(x + 2, y + 3 + i * 2, 4, 1, COL.paperDark);
    rect(x + 10, y + 3 + i * 2, 4, 1, COL.paperDark);
  }
  if (f % 80 > 58) rect(x + 8, y + 1, 2, 8, COL.white, 0.8);
}

function drawMat(x, y, w, col) {
  rect(x, y, w, 3, col);
  rect(x + 1, y + 1, w - 2, 1, COL.white, 0.32);
}

function drawDesk(x, y) {
  rect(x, y, 24, 3, COL.wood);
  rect(x + 2, y + 3, 3, 8, COL.woodDark);
  rect(x + 19, y + 3, 3, 8, COL.woodDark);
}

function drawDumbbell(x, y, up) {
  const yy = y - up;
  rect(x, yy + 1, 2, 4, COL.dark);
  rect(x + 2, yy + 2, 6, 2, COL.gray);
  rect(x + 8, yy + 1, 2, 4, COL.dark);
}

function sceneCoffee(f, t) {
  const p = t < 0.25 ? easeOut(t / 0.25) : 1;
  const cx = Math.round(lerp(-10, 9, p));
  const bob = pulse(f, 0.45) > 0 ? -1 : 0;
  drawMug(23, 21, f);
  if (t > 0.55) drawHeart(20, 11 - Math.round((t - 0.55) * 10), COL.heart);
  drawClawd(cx, 22 + bob, { eyes: t > 0.35 ? 'look_right' : 'forward' });
  if (t > 0.42 && Math.floor(f / 8) % 2 === 0) drawLabel('SIP', 19, 15.5, 1.25, COL.coffee, 0.95);
}

function sceneKeyboard(f) {
  drawMonitor(18, 10, f);
  drawKeyboard(17, 23, f);
  const bob = Math.floor(f / 6) % 2 === 0 ? -1 : 0;
  drawClawd(5, 21 + bob, { eyes: 'look_right' });
  if (f % 20 < 8) {
    px(14, 18, COL.yellow);
    px(15, 17, COL.yellow);
  }
}

function sceneReading(f, t) {
  drawBook(18, 19, f, true);
  const eye = f % 90 > 72 ? 'blink' : 'look_right';
  drawClawd(6, 22 + (pulse(f, 0.18) > 0.85 ? -1 : 0), { eyes: eye });
  drawBubbleText(['人就是要', '多学习'], 12, 5, 22, 12, { size: 1.5, color: COL.dark, alpha: 0.94 });
}

function sceneStretch(f, t) {
  drawMat(7, 30, 23, COL.mint);
  const stretch = Math.sin(t * Math.PI * 2) > 0.25;
  const y = stretch ? 18 : 21;
  drawClawd(11, y, { eyes: stretch ? 'blink' : 'forward' });
  rect(8, 15, 2, 1, COL.yellow);
  rect(7, 16, 1, 2, COL.yellow);
  rect(27, 15, 2, 1, COL.yellow);
  rect(29, 16, 1, 2, COL.yellow);
  if (stretch) drawLabel('UP!', 18, 10.6, 1.35, COL.green, 0.95);
}

function sceneMeditation(f) {
  drawMat(10, 29, 18, COL.purple);
  const breathe = (Math.sin(f * 0.08) + 1) / 2;
  rect(12, 25, 14, 3, COL.purple);
  drawClawd(11, 21 + Math.round(breathe), { eyes: 'closed' });
  drawBubble(8, 8, 20, 8, COL.white, 0.12 + breathe * 0.16);
  px(17, 10, COL.mint, 0.8);
  px(20, 12, COL.blue, 0.7);
  px(15, 14, COL.yellow, 0.7);
}

function sceneTidyDesk(f, t) {
  drawDesk(6, 25);
  drawBubbleText(['正在', '整理桌面'], 14, 5, 20, 11, { size: 1.35, color: COL.woodDark, alpha: 0.94 });
  const stage = Math.floor(t * 4);
  if (stage < 1) { rect(12, 20, 4, 3, COL.paper); rect(25, 22, 3, 2, COL.paper); }
  if (stage < 2) { rect(18, 21, 4, 2, COL.paper); }
  rect(26, 19, 5, 5, COL.paperDark);
  rect(27, 18, 5, 5, COL.paper);
  const cx = stage % 2 === 0 ? 4 : 10;
  drawClawd(cx, 17 + (f % 10 < 5 ? -1 : 0), { eyes: 'look_right' });
  if (stage >= 3) drawHeart(22, 13, COL.heart);
}

function sceneCheer(f) {
  rect(12, 9, 17, 9, COL.yellow);
  rect(13, 10, 15, 7, COL.paper);
  drawLabel('GO!', 20.5, 11.2, 1.95, COL.red);
  rect(20, 18, 1, 8, COL.woodDark);
  const bob = f % 16 < 8 ? -2 : 0;
  drawClawd(11, 24 + bob, { eyes: 'forward' });
  if (bob < 0) {
    px(9, 15, COL.yellow);
    px(29, 16, COL.yellow);
  }
}

function sceneFitness(f) {
  const lift = Math.floor(f / 15) % 2 === 0 ? 5 : 0;
  drawDumbbell(19, 23, lift);
  drawDumbbell(7, 23, lift > 0 ? 0 : 4);
  drawClawd(11, 22 + (lift > 0 ? -1 : 0), { eyes: lift > 0 ? 'blink' : 'forward' });
  drawLabel(String((Math.floor(f / 15) % 4) + 1), 30, 12.4, 1.55, COL.red, 0.95);
  px(24, 16, COL.blue, 0.8);
}

function sceneSleep(f) {
  drawMat(7, 30, 23, COL.blue);
  rect(10, 27, 18, 3, COL.blueDark);
  drawClawd(11, 21 + (pulse(f, 0.08) > 0 ? 0 : 1), { eyes: 'closed' });
  drawBubbleText(['Z', 'z z'], 20, 6, 12, 10, { size: 1.7, color: COL.purple, alpha: 0.9 });
}

function sceneRunning(f) {
  rect(0, 29, 36, 4, COL.gray);
  rect(0, 28, 36, 1, COL.dark);
  for (let i = 0; i < 8; i++) rect(3 + i * 6 - (f % 6), 31, 3, 1, COL.yellow);
  rect(28, 4, 4, 4, COL.yellow);
  rect(5, 6, 7, 3, COL.white);
  rect(8, 4, 8, 4, COL.white);
  rect(21, 7, 6, 3, COL.white);
  rect(24, 5, 7, 4, COL.white);
  const stride = f % 10 < 5 ? -2 : 0;
  drawClawd(10 + Math.round(Math.sin(f * 0.18) * 2), 22 + stride, { eyes: 'look_right' });
  px(8, 27, COL.paperDark);
  px(6, 28, COL.paperDark);
}

function sceneSwimming(f) {
  const wave = f * 0.18;
  rect(4, 25, 29, 8, COL.blue, 0.72);
  for (let x = 5; x < 33; x++) {
    const topWave = Math.sin(x * 0.8 + wave);
    const lowWave = Math.sin(x * 0.7 + wave + 1.4);
    if (topWave > 0.15) px(x, 24 + Math.round(topWave), COL.white, 0.9);
    if (lowWave > 0.15) px(x, 29 + Math.round(lowWave), COL.blueDark, 0.9);
  }
  const dive = f % 40 < 20 ? 0 : 2;
  drawClawd(11, 20 + dive, { eyes: dive ? 'blink' : 'forward' });
  rect(14, 22 + dive, 3, 1, COL.blueDark);
  rect(21, 22 + dive, 3, 1, COL.blueDark);
  rect(7 + (f % 8), 26, 4, 1, COL.white, 0.9);
  rect(24 - (f % 7), 31, 5, 1, COL.white, 0.85);
}

function sceneDaydream(f) {
  drawClawd(11, 23 + (pulse(f, 0.1) > 0 ? 0 : 1), { eyes: f % 80 > 40 ? 'look_left' : 'look_right' });
  drawBubbleText(['我活着', '究竟是', '为什么？'], 12, 4, 23, 14, { size: 1.08, color: COL.dark, alpha: 0.94 });
  px(19, 18, COL.white, 0.8);
  px(17, 20, COL.white, 0.6);
}

const SCENES = {
  coffee: sceneCoffee,
  keyboard: sceneKeyboard,
  reading: sceneReading,
  stretch: sceneStretch,
  meditation: sceneMeditation,
  tidy: sceneTidyDesk,
  cheer: sceneCheer,
  fitness: sceneFitness,
  sleep: sceneSleep,
  running: sceneRunning,
  swimming: sceneSwimming,
  daydream: sceneDaydream
};

function render(f = 0) {
  f = wrapFrame(f);
  clear();
  const t = f / TOTAL;
  const fn = SCENES[SCENE] || SCENES.coffee;
  fn(f, t);
  const info = document.getElementById('info');
  if (info) info.textContent = `clawd original ${SCENE} - ${(f / FPS).toFixed(1)}s / ${DUR}.0s`;
}

let startTime = null;
function loop(ts) {
  if (!startTime) startTime = ts;
  const elapsed = (ts - startTime) / 1000;
  render(Math.floor((elapsed % DUR) * FPS));
  requestAnimationFrame(loop);
}

render(0);
requestAnimationFrame(loop);
