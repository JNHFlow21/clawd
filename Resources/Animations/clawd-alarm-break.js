const cv = document.getElementById("c");
const ctx = cv.getContext("2d");
const MODE = document.body.dataset.mode || "rest";

const PALETTE = {
  clawd: { body: "#CD6E58", eye: "#000000" },
  clock: {
    red: "#D9423A",
    redDark: "#9E2D2A",
    face: "#FFF1B8",
    bell: "#F0C65A",
    metal: "#585858",
    shine: "#FFFFFF"
  },
  trail: "#FFF1B8",
  shadow: "rgba(0, 0, 0, 0.22)"
};

const CLAWD_BODY = {
  width: 14,
  height: 8,
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
    eyeLeft: { x: 4, y: 1 },
    eyeRight: { x: 9, y: 1 }
  }
};

const EYES = {
  forward: { left: { dx: 0, dy: 0 }, right: { dx: 0, dy: 0 } },
  look_right: { left: { dx: 1, dy: 0 }, right: { dx: 1, dy: 0 } },
  look_left: { left: { dx: -1, dy: 0 }, right: { dx: -1, dy: 0 } },
  look_down: { left: { dx: 0, dy: 1 }, right: { dx: 0, dy: 1 } },
  blink: { type: "hidden" }
};

let frame = 0;
let pxSize = 20;
let startedAt = performance.now();

function resizeCanvas() {
  cv.width = window.innerWidth;
  cv.height = window.innerHeight;
  const base = MODE === "rest" ? 42 : 36;
  pxSize = Math.max(4, Math.min(22, Math.floor(Math.min(cv.width, cv.height) / base)));
}

resizeCanvas();
window.addEventListener("resize", resizeCanvas);

function px(gx, gy, col) {
  ctx.fillStyle = col;
  ctx.fillRect(Math.round(gx * pxSize), Math.round(gy * pxSize), pxSize, pxSize);
}

function rect(gx, gy, gw, gh, col) {
  ctx.fillStyle = col;
  ctx.fillRect(
    Math.round(gx * pxSize),
    Math.round(gy * pxSize),
    Math.round(gw * pxSize),
    Math.round(gh * pxSize)
  );
}

function drawClawd(ox, oy, opts = {}) {
  const eyeVariant = opts.eyes || "forward";
  const legShift = opts.run ? Math.sin(frame * 0.48) : 0;

  for (let r = 0; r < CLAWD_BODY.height; r += 1) {
    for (let c = 0; c < CLAWD_BODY.width; c += 1) {
      if (CLAWD_BODY.data[r][c] !== 1) continue;
      let dx = 0;
      if (opts.run && r >= 6) dx = ((c % 2 === 0 ? 1 : -1) * legShift) * 0.35;
      px(ox + c + dx, oy + r, PALETTE.clawd.body);
    }
  }

  const ev = EYES[eyeVariant];
  if (ev && ev.type !== "hidden") {
    const el = CLAWD_BODY.anchors.eyeLeft;
    const er = CLAWD_BODY.anchors.eyeRight;
    px(ox + el.x + ev.left.dx, oy + el.y + ev.left.dy, PALETTE.clawd.eye);
    px(ox + er.x + ev.right.dx, oy + er.y + ev.right.dy, PALETTE.clawd.eye);
  }
}

function drawClock(cx, cy, scale = 1, shake = 0) {
  const wobbleX = Math.sin(frame * 0.8) * shake;
  const wobbleY = Math.cos(frame * 0.55) * shake;
  const x = cx - 5 * scale + wobbleX;
  const y = cy - 5 * scale + wobbleY;

  rect(x + 1 * scale, y - 1 * scale, 2 * scale, 2 * scale, PALETTE.clock.bell);
  rect(x + 7 * scale, y - 1 * scale, 2 * scale, 2 * scale, PALETTE.clock.bell);
  rect(x + 2 * scale, y + 9 * scale, 1 * scale, 1 * scale, PALETTE.clock.metal);
  rect(x + 7 * scale, y + 9 * scale, 1 * scale, 1 * scale, PALETTE.clock.metal);
  rect(x + 1 * scale, y + 1 * scale, 8 * scale, 8 * scale, PALETTE.clock.redDark);
  rect(x, y + 2 * scale, 10 * scale, 6 * scale, PALETTE.clock.red);
  rect(x + 2 * scale, y + 2 * scale, 6 * scale, 6 * scale, PALETTE.clock.face);
  rect(x + 3 * scale, y + 3 * scale, 1 * scale, 1 * scale, PALETTE.clock.shine);
  rect(x + 4.5 * scale, y + 3 * scale, 1 * scale, 3 * scale, PALETTE.clock.metal);
  rect(x + 4.5 * scale, y + 5 * scale, 2.5 * scale, 1 * scale, PALETTE.clock.metal);
  rect(x + 3.5 * scale, y + 10.2 * scale, 3 * scale, 0.35 * scale, PALETTE.shadow);
}

function drawTrail(x, y, progress) {
  for (let i = 0; i < 5; i += 1) {
    ctx.globalAlpha = Math.max(0, 0.34 - i * 0.06);
    rect(x - i * 1.45 * progress, y + i * 0.6 * progress, 1.3, 0.45, PALETTE.trail);
  }
  ctx.globalAlpha = 1;
}

function easeOut(t) {
  return 1 - Math.pow(1 - t, 3);
}

function easeInOut(t) {
  return t < 0.5 ? 4 * t * t * t : 1 - Math.pow(-2 * t + 2, 3) / 2;
}

function lerp(a, b, t) {
  return a + (b - a) * t;
}

function drawReady(gw, gh) {
  const bob = Math.sin(frame * 0.18) * 0.45;
  const tense = Math.sin(frame * 0.55) * 0.2;
  const crabX = Math.max(2, gw - 17);
  const crabY = Math.max(4, gh - 11);
  drawClawd(crabX + tense, crabY + bob, { eyes: frame % 42 < 4 ? "blink" : "look_left" });
  drawClock(crabX - 2.1 + tense, crabY - 2.5 + bob, 0.52, 0.1);
}

function drawThrow(gw, gh) {
  const elapsed = performance.now() - startedAt;
  const t = Math.min(1, elapsed / 2500);
  const crabStartX = Math.max(2, gw - 17);
  const crabStartY = Math.max(5, gh - 11);
  const centerX = gw * 0.5;
  const centerY = gh * 0.42;

  if (t < 0.18) {
    drawReady(gw, gh);
    return;
  }

  const throwT = Math.min(1, (t - 0.18) / 0.36);
  const runT = Math.min(1, Math.max(0, (t - 0.36) / 0.5));
  const easedThrow = easeOut(throwT);
  const arc = Math.sin(easedThrow * Math.PI) * 8;
  const clockX = lerp(crabStartX - 2.1, centerX, easedThrow);
  const clockY = lerp(crabStartY - 2.5, centerY, easedThrow) - arc;
  const crabX = lerp(crabStartX, centerX - 16, easeInOut(runT));
  const crabY = lerp(crabStartY, centerY + 9, easeInOut(runT));

  drawTrail(clockX, clockY, easedThrow);
  drawClock(clockX, clockY, lerp(0.52, 1.25, easedThrow), 0.08);
  drawClawd(crabX, crabY, { eyes: "look_left", run: true });
}

function drawRest(gw, gh) {
  const centerX = gw * 0.5;
  const centerY = gh * 0.42;
  const pulse = 1.22 + Math.sin(frame * 0.22) * 0.08;
  const angle = frame * 0.028;
  const orbitX = Math.cos(angle) * 11;
  const orbitY = Math.sin(angle) * 5;
  const crabX = centerX + orbitX - 7;
  const crabY = centerY + 10 + orbitY;
  const blink = frame % 90 > 84;

  drawClock(centerX, centerY, pulse, 0.24);
  drawClawd(crabX, crabY, {
    eyes: blink ? "blink" : orbitX > 0 ? "look_left" : "look_right",
    run: true
  });
}

function render() {
  frame += 1;
  ctx.clearRect(0, 0, cv.width, cv.height);

  const gw = cv.width / pxSize;
  const gh = cv.height / pxSize;

  if (MODE === "ready") drawReady(gw, gh);
  else if (MODE === "throw") drawThrow(gw, gh);
  else drawRest(gw, gh);

  requestAnimationFrame(render);
}

requestAnimationFrame(render);
