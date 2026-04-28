const cv  = document.getElementById('c');
const ctx = cv.getContext('2d');
const PX  = 20;
const GW  = 36, GH = 36;

// ═══════════════════════════════════════════════
// COLORS
// ═══════════════════════════════════════════════
const COL = {
  bg:        '#F9F7F4',
  dot:       '#E0DDD8',
  starDark:  '#333333',
  starMid:   '#888888',
  starLight: '#BBBBBB',
  body:      '#CD6E58',
  bodyDark:  '#B85E4A',
  eye:       '#000000',
  // Cake
  cakeBody:  '#DCA540',
  cakeLight: '#F0D878',
  cakeDark:  '#B88020',
  // Candle & flame
  candle:    '#9C5090',
  flameO:    '#E86030',
  flameY:    '#F8C840',
};

function px(x, y, col) {
  ctx.fillStyle = col;
  ctx.fillRect(Math.round(x) * PX, Math.round(y) * PX, PX, PX);
}

// ═══════════════════════════════════════════════
// BACKGROUND
// ═══════════════════════════════════════════════
function drawBg() {
  ctx.clearRect(0, 0, cv.width, cv.height);
}

const STARS = [
  {x:4,y:3,t:'dark'},{x:14,y:2,t:'dark'},{x:27,y:1,t:'dark'},
  {x:31,y:3,t:'mid'},{x:6,y:7,t:'dark'},{x:19,y:5,t:'light'},
  {x:24,y:6,t:'mid'},{x:9,y:10,t:'dark'},{x:2,y:13,t:'dark'},
  {x:33,y:8,t:'dark'},{x:29,y:12,t:'dark'},{x:7,y:16,t:'mid'},
  {x:3,y:20,t:'dark'},{x:30,y:18,t:'mid'},{x:1,y:25,t:'dark'},
  {x:33,y:24,t:'dark'},{x:5,y:30,t:'light'},{x:28,y:28,t:'mid'},
  {x:15,y:9,t:'light'},{x:21,y:14,t:'mid'},
];

function drawStars(f) {
  ctx.textAlign = 'center';
  ctx.textBaseline = 'middle';
  for (const s of STARS) {
    const tw = Math.sin(f * 0.08 + s.x * 0.5 + s.y * 0.3);
    let col;
    if (s.t === 'dark')       col = tw > 0    ? COL.starDark  : COL.starMid;
    else if (s.t === 'mid')   col = tw > 0.3  ? COL.starMid   : COL.starLight;
    else                      col = tw > 0    ? COL.starLight  : COL.dot;
    ctx.fillStyle = col;
    ctx.font = `bold ${s.t === 'dark' ? 14 : 10}px serif`;
    ctx.fillText('✳', s.x * PX + PX/2, s.y * PX + PX/2);
  }
}

// ═══════════════════════════════════════════════
// CLAWD
// ═══════════════════════════════════════════════
const BODY = [
  [0,0,0,1,1,1,1,1,1,1,1,0,0,0],  // 0 head
  [0,0,0,1,1,1,1,1,1,1,1,0,0,0],  // 1 eyes row
  [0,1,1,1,1,1,1,1,1,1,1,1,1,0],  // 2 arms
  [0,1,1,1,1,1,1,1,1,1,1,1,1,0],  // 3 arms
  [0,0,0,1,1,1,1,1,1,1,1,0,0,0],  // 4 belly
  [0,0,0,1,1,1,1,1,1,1,1,0,0,0],  // 5 belly
  [0,0,0,1,0,1,0,0,1,0,1,0,0,0],  // 6 legs
  [0,0,0,1,0,1,0,0,1,0,1,0,0,0],  // 7 legs
];

// Walk leg variants (rows 6-7 only)
const LEGS_WALK = [
  // Frame 0: legs spread wider
  [[0,0,1,0,0,1,0,0,1,0,0,1,0,0],
   [0,0,1,0,0,1,0,0,1,0,0,1,0,0]],
  // Frame 1: legs normal
  [[0,0,0,1,0,1,0,0,1,0,1,0,0,0],
   [0,0,0,1,0,1,0,0,1,0,1,0,0,0]],
];

const EYES = {
  forward:  [[4,1],[9,1]],
  look_up:  [[4,0],[9,0]],
  blink:    [],
};

function drawClawd(ox, oy, { eyes = 'forward', walkFrame = -1 } = {}) {
  // Body rows 0-5
  for (let r = 0; r < 6; r++)
    for (let c = 0; c < BODY[r].length; c++)
      if (BODY[r][c]) px(ox + c, oy + r, COL.body);

  // Legs rows 6-7
  if (walkFrame >= 0) {
    const legs = LEGS_WALK[walkFrame % 2];
    for (let r = 0; r < 2; r++)
      for (let c = 0; c < legs[r].length; c++)
        if (legs[r][c]) px(ox + c, oy + 6 + r, COL.body);
  } else {
    for (let r = 6; r < 8; r++)
      for (let c = 0; c < BODY[r].length; c++)
        if (BODY[r][c]) px(ox + c, oy + r, COL.body);
  }

  // Eyes
  for (const [ec, er] of (EYES[eyes] || []))
    px(ox + ec, oy + er, COL.eye);
}

// ═══════════════════════════════════════════════
// BIRTHDAY CAKE — two-tier with frosting scallops
// ═══════════════════════════════════════════════
// 14 wide (aligned with body grid), 8 rows tall
// 0=empty, 1=cakeBody, 2=cakeLight(frost), 3=cakeDark(brim)
const CAKE = [
  [0,0,0,0,2,2,1,1,2,2,0,0,0,0],  // 0: top frost scallop
  [0,0,0,2,1,1,1,1,1,1,2,0,0,0],  // 1: upper tier top
  [0,0,0,1,1,1,1,1,1,1,1,0,0,0],  // 2: upper tier body
  [0,0,2,2,1,2,2,1,2,2,1,2,0,0],  // 3: mid frost scallop
  [0,0,1,1,1,1,1,1,1,1,1,1,0,0],  // 4: lower tier top
  [0,1,1,1,1,1,1,1,1,1,1,1,1,0],  // 5: lower tier
  [0,1,1,1,1,1,1,1,1,1,1,1,1,0],  // 6: lower tier
  [3,3,3,3,3,3,3,3,3,3,3,3,3,3],  // 7: brim
];
const CAKE_PAL = { 1: COL.cakeBody, 2: COL.cakeLight, 3: COL.cakeDark };

// Flame frames (3×3): 0=empty, 1=outer orange, 2=inner yellow
const FLAMES = [
  [[0,1,0],[1,2,1],[0,1,0]],  // diamond
  [[0,1,0],[1,2,0],[0,1,1]],  // lean right
  [[0,1,0],[0,2,1],[1,1,0]],  // lean left
];
const FLAME_PAL = { 1: COL.flameO, 2: COL.flameY };

function drawCake(ox, cakeY, f) {
  // Cake body (8 rows: cakeY to cakeY+7)
  for (let r = 0; r < CAKE.length; r++)
    for (let c = 0; c < CAKE[r].length; c++) {
      const v = CAKE[r][c];
      if (v) px(ox + c, cakeY + r, CAKE_PAL[v]);
    }

  // Candle: 1px wide at col 7, 3 rows above cake top
  const candleX = ox + 7;
  for (let i = 0; i < 3; i++)
    px(candleX, cakeY - 3 + i, COL.candle);

  // Flame: 3×3 centered on candle top, flickering
  const fi = Math.floor(f / 5) % FLAMES.length;
  const flame = FLAMES[fi];
  for (let r = 0; r < 3; r++)
    for (let c = 0; c < 3; c++) {
      const v = flame[r][c];
      if (v) px(candleX - 1 + c, cakeY - 6 + r, FLAME_PAL[v]);
    }
}

// ═══════════════════════════════════════════════
// SPARKLE PARTICLES
// ═══════════════════════════════════════════════
let particles = [];

function addSparkle(x, y, col) {
  particles.push({
    x, y,
    vx: (Math.random() - 0.5) * 0.6,
    vy: -Math.random() * 0.5 - 0.2,
    life: 1.0, col,
  });
}

function tickParticles() {
  for (let i = particles.length - 1; i >= 0; i--) {
    const p = particles[i];
    p.x += p.vx; p.y += p.vy;
    p.vy += 0.02; p.life -= 0.025;
    if (p.life <= 0) { particles.splice(i, 1); continue; }
    if (p.life > 0.1) {
      ctx.globalAlpha = p.life;
      ctx.fillStyle = p.col;
      ctx.font = `bold ${Math.round(8 + p.life * 6)}px serif`;
      ctx.textAlign = 'center';
      ctx.textBaseline = 'middle';
      ctx.fillText('✳', Math.round(p.x) * PX + PX/2, Math.round(p.y) * PX + PX/2);
      ctx.globalAlpha = 1;
    }
  }
}

// ═══════════════════════════════════════════════
// ANIMATION
// ═══════════════════════════════════════════════
const FPS = 30, DUR = 5, TOTAL = FPS * DUR;
const CX = 11, CY = 18;  // Clawd base position

function getPhase(t) {
  if (t < 0.12) return { ph: 'enter',     pt: t / 0.12 };
  if (t < 0.22) return { ph: 'idle',      pt: (t - 0.12) / 0.10 };
  if (t < 0.34) return { ph: 'cake_drop', pt: (t - 0.22) / 0.12 };
  if (t < 0.90) return { ph: 'dance',     pt: (t - 0.34) / 0.56 };
  return               { ph: 'celebrate', pt: (t - 0.90) / 0.10 };
}

function easeOut(t)   { return 1 - (1 - t) ** 3; }
function lerp(a, b, t) { return a + (b - a) * t; }

// Bounce easing for cake drop
function easeOutBounce(t) {
  if (t < 1/2.75)   return 7.5625 * t * t;
  if (t < 2/2.75)   { t -= 1.5/2.75;   return 7.5625 * t * t + 0.75; }
  if (t < 2.5/2.75) { t -= 2.25/2.75;  return 7.5625 * t * t + 0.9375; }
  t -= 2.625/2.75;  return 7.5625 * t * t + 0.984375;
}

let startTime = null;

function render(f) {
  const t = f / TOTAL;
  const { ph, pt } = getPhase(t);

  drawBg();
  let cx = CX, bounce = 0;
  let eyes = 'forward';
  let walkFrame = -1;
  let showCake = false;
  let cakeOffsetY = 0;

  switch (ph) {

    case 'enter':
      cx = Math.round(lerp(-14, CX, easeOut(pt)));
      bounce = f % 10 < 5 ? -1 : 0;
      walkFrame = Math.floor(f / 5) % 2;
      break;

    case 'idle':
      cx = CX;
      bounce = 0;
      eyes = pt > 0.3 ? 'look_up' : 'forward';
      break;

    case 'cake_drop':
      cx = CX;
      eyes = pt < 0.7 ? 'look_up' : 'forward';
      showCake = true;
      // Cake drops from sky with bounce landing
      cakeOffsetY = Math.round(lerp(-20, 0, easeOutBounce(pt)));
      // Little surprise bounce when cake lands
      if (pt > 0.85) bounce = -1;
      break;

    case 'dance': {
      cx = CX;
      showCake = true;
      // Walk cycle: 16 frames per cycle (~0.53s)
      const cycle = f % 16;
      bounce = cycle < 8 ? -1 : 0;
      walkFrame = cycle < 8 ? 0 : 1;
      // Occasional blink
      eyes = Math.sin(f * 0.3) > 0.85 ? 'blink' : 'forward';
      // Sparkle particles during dance
      if (f % 12 === 0) {
        addSparkle(cx + 2, CY - 2, COL.starDark);
        addSparkle(cx + 12, CY - 3, COL.starMid);
      }
      break;
    }

    case 'celebrate': {
      cx = CX;
      showCake = true;
      // Faster bounce for celebration
      const cyc = f % 10;
      bounce = cyc < 5 ? -2 : 0;
      walkFrame = Math.floor(f / 4) % 2;
      eyes = Math.sin(f * 0.5) > 0.6 ? 'blink' : 'forward';
      // More sparkles
      if (f % 4 === 0) {
        addSparkle(cx + Math.random() * 14, CY - 4 - Math.random() * 6, COL.cakeLight);
        addSparkle(cx + Math.random() * 14, CY - 2 - Math.random() * 4, COL.starDark);
      }
      break;
    }
  }

  // Draw Clawd first (cake overlays the head top)
  drawClawd(cx, CY + bounce, { eyes, walkFrame });

  // Draw cake on top of Clawd's head
  if (showCake) {
    // Brim (CAKE row 7) sits at CY+bounce-1 (directly above head)
    // So cake top row is at CY+bounce-8
    const cakeY = CY + bounce - 8 + cakeOffsetY;
    drawCake(cx, cakeY, f);
  }

  // Sparkle particles (drawn last, on top)
  tickParticles();

  document.getElementById('info').textContent =
    `小螃蟹过生日 — ${(f / FPS).toFixed(1)}s / ${DUR}.0s`;
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