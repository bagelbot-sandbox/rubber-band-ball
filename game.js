const canvas = document.querySelector("#gameCanvas");
const context = canvas.getContext("2d");
const levelLabel = document.querySelector("#levelLabel");
const collectedLabel = document.querySelector("#collectedLabel");
const remainingLabel = document.querySelector("#remainingLabel");
const movesLabel = document.querySelector("#movesLabel");
const playScreen = document.querySelector("#playScreen");
const victoryScreen = document.querySelector("#victoryScreen");
const playAgainButton = document.querySelector("#playAgainButton");
const restartLevelButton = document.querySelector("#restartLevelButton");
const muteButton = document.querySelector("#muteButton");
const dpad = document.querySelector("#dpad");
const dpadButtons = [...document.querySelectorAll(".dpad-button[data-direction]")];
const boppingBall = document.querySelector(".bopping-ball");

const width = 11;
const height = 13;
const tileSize = canvas.width / width;
const rubberBandColors = ["#fac737", "#f2473f", "#40b9f2", "#5bc76d", "#d96ef2"];
const moveRepeatMs = 120;
const ballTravelMs = 120;
const swipeTurnThreshold = 18;
const wallWidth = tileSize * 0.24;
const levelBackgroundSources = [
  "bos-nicholas-short-hair-rbb-660x780.png",
  "bos-nicholas-short-hair-rbb-660x780.png",
  "bos-nicholas-short-hair-rbb-660x780.png",
  "bos-nicholas-short-hair-rbb-660x780.png"
];
const levelBackgrounds = levelBackgroundSources.map((source) => {
  const image = new Image();
  image.src = source;
  return image;
});
const snowflakes = Array.from({ length: 70 }, (_, index) => ({
  x: (index * 97) % canvas.width,
  y: (index * 173) % canvas.height,
  radius: 1.2 + (index % 4) * 0.45,
  speed: 0.02 + (index % 5) * 0.008,
  drift: 9 + (index % 6) * 4,
  phase: index * 0.63
}));
const levelMusicSources = [
  "strings.mp3",
  "drums.mp3",
  "clarinets.mp3",
  "horns.mp3"
];
const victoryMusicSource = "all.mp3";
const backgroundMusic = new Audio();
const victoryMusic = new Audio(victoryMusicSource);
const musicPreloads = levelMusicSources.concat(victoryMusicSource).map((source) => {
  const audio = new Audio(source);
  audio.preload = "auto";
  audio.load();
  return audio;
});

backgroundMusic.loop = true;
backgroundMusic.preload = "auto";
backgroundMusic.volume = 0.35;
victoryMusic.loop = true;
victoryMusic.preload = "auto";
victoryMusic.volume = 0.35;
victoryMusic.muted = true;
victoryMusic.load();

const pointKey = (point) => `${point.x},${point.y}`;
const makePoint = (x, y) => ({ x, y });
let activeInputDirection = null;
let activeKeyDirection = null;
let swipePointerId = null;
let swipeAnchor = null;
let moveRepeatTimer = null;
let musicWasStarted = false;
let currentMusicSource = "";
let isMuted = false;
let victoryMusicIsPrimed = false;
const victoryBall = {
  x: 14,
  y: 14,
  vx: 0,
  vy: 0,
  rotation: 0,
  lastUpdatedAt: 0
};

const makeLevel = (number, start, exit, bands, innerWalls, instrumentalist) => {
  const wallKeys = new Set(innerWalls.map(pointKey));

  for (let x = 0; x < width; x += 1) {
    wallKeys.add(pointKey(makePoint(x, 0)));
    wallKeys.add(pointKey(makePoint(x, height - 1)));
  }

  for (let y = 0; y < height; y += 1) {
    wallKeys.add(pointKey(makePoint(0, y)));
    wallKeys.add(pointKey(makePoint(width - 1, y)));
  }

  wallKeys.delete(pointKey(start));
  wallKeys.delete(pointKey(exit));
  bands.forEach((band) => wallKeys.delete(pointKey(band)));

  return {
    number,
    start,
    exit,
    bands,
    bandKeys: new Set(bands.map(pointKey)),
    wallKeys,
    instrumentalist
  };
};

const levels = [
  makeLevel(
    1,
    makePoint(1, 1),
    makePoint(9, 11),
    [makePoint(9, 10), makePoint(9, 9), makePoint(9, 8), makePoint(9, 7), makePoint(5, 11), makePoint(7, 8), makePoint(4, 11), makePoint(7, 7), makePoint(3, 11), makePoint(8, 5), makePoint(9, 3), makePoint(5, 7), makePoint(1, 11), makePoint(7, 4), makePoint(4, 7), makePoint(2, 9), makePoint(9, 1), makePoint(5, 5), makePoint(1, 9), makePoint(6, 3)],
    [makePoint(1, 2), makePoint(2, 2), makePoint(3, 2), makePoint(4, 2), makePoint(5, 2), makePoint(6, 2), makePoint(7, 2), makePoint(8, 2), makePoint(2, 3), makePoint(8, 3), makePoint(2, 4), makePoint(4, 4), makePoint(5, 4), makePoint(6, 4), makePoint(8, 4), makePoint(2, 5), makePoint(6, 5), makePoint(2, 6), makePoint(3, 6), makePoint(4, 6), makePoint(6, 6), makePoint(7, 6), makePoint(8, 6), makePoint(9, 6), makePoint(2, 7), makePoint(6, 7), makePoint(2, 8), makePoint(4, 8), makePoint(5, 8), makePoint(6, 8), makePoint(8, 8), makePoint(4, 9), makePoint(8, 9), makePoint(2, 10), makePoint(3, 10), makePoint(4, 10), makePoint(5, 10), makePoint(6, 10), makePoint(7, 10), makePoint(8, 10)],
    { point: makePoint(9, 1), instrument: "violin" }
  ),
  makeLevel(
    2,
    makePoint(1, 11),
    makePoint(9, 1),
    [makePoint(8, 1), makePoint(7, 1), makePoint(6, 1), makePoint(9, 4), makePoint(7, 3), makePoint(6, 3), makePoint(3, 1), makePoint(7, 5), makePoint(2, 1), makePoint(5, 4), makePoint(9, 8), makePoint(3, 3), makePoint(7, 7), makePoint(1, 2), makePoint(4, 5), makePoint(7, 8), makePoint(9, 10), makePoint(3, 5), makePoint(7, 9), makePoint(1, 4)],
    [makePoint(4, 1), makePoint(2, 2), makePoint(4, 2), makePoint(5, 2), makePoint(6, 2), makePoint(8, 2), makePoint(2, 3), makePoint(4, 3), makePoint(8, 3), makePoint(2, 4), makePoint(4, 4), makePoint(6, 4), makePoint(7, 4), makePoint(8, 4), makePoint(2, 5), makePoint(6, 5), makePoint(2, 6), makePoint(3, 6), makePoint(4, 6), makePoint(5, 6), makePoint(6, 6), makePoint(8, 6), makePoint(9, 6), makePoint(2, 7), makePoint(8, 7), makePoint(2, 8), makePoint(3, 8), makePoint(4, 8), makePoint(5, 8), makePoint(6, 8), makePoint(8, 8), makePoint(6, 9), makePoint(1, 10), makePoint(2, 10), makePoint(3, 10), makePoint(4, 10), makePoint(6, 10), makePoint(7, 10), makePoint(8, 10), makePoint(6, 11)],
    { point: makePoint(8, 1), instrument: "drums" }
  ),
  makeLevel(
    3,
    makePoint(5, 11),
    makePoint(5, 1),
    [makePoint(1, 1), makePoint(2, 1), makePoint(1, 2), makePoint(3, 1), makePoint(1, 3), makePoint(4, 1), makePoint(3, 2), makePoint(3, 3), makePoint(1, 5), makePoint(6, 3), makePoint(7, 4), makePoint(8, 5), makePoint(5, 3), makePoint(7, 5), makePoint(9, 7), makePoint(3, 6), makePoint(1, 8), makePoint(5, 5), makePoint(7, 7), makePoint(9, 9)],
    [makePoint(2, 2), makePoint(4, 2), makePoint(5, 2), makePoint(6, 2), makePoint(7, 2), makePoint(8, 2), makePoint(2, 3), makePoint(4, 3), makePoint(8, 3), makePoint(1, 4), makePoint(2, 4), makePoint(4, 4), makePoint(6, 4), makePoint(8, 4), makePoint(4, 5), makePoint(6, 5), makePoint(2, 6), makePoint(4, 6), makePoint(5, 6), makePoint(6, 6), makePoint(7, 6), makePoint(8, 6), makePoint(9, 6), makePoint(2, 7), makePoint(4, 7), makePoint(2, 8), makePoint(3, 8), makePoint(4, 8), makePoint(6, 8), makePoint(7, 8), makePoint(8, 8), makePoint(8, 9), makePoint(2, 10), makePoint(3, 10), makePoint(4, 10), makePoint(5, 10), makePoint(6, 10), makePoint(7, 10), makePoint(8, 10), makePoint(4, 11)],
    { point: makePoint(5, 3), instrument: "clarinet" }
  ),
  makeLevel(
    4,
    makePoint(1, 5),
    makePoint(9, 5),
    [makePoint(9, 11), makePoint(8, 11), makePoint(9, 9), makePoint(8, 1), makePoint(8, 9), makePoint(7, 1), makePoint(9, 7), makePoint(5, 11), makePoint(7, 2), makePoint(9, 6), makePoint(6, 9), makePoint(5, 1), makePoint(7, 7), makePoint(3, 11), makePoint(6, 3), makePoint(6, 7), makePoint(3, 1), makePoint(7, 5), makePoint(3, 9), makePoint(3, 2)],
    [makePoint(2, 1), makePoint(2, 2), makePoint(4, 2), makePoint(5, 2), makePoint(6, 2), makePoint(8, 2), makePoint(4, 3), makePoint(8, 3), makePoint(1, 4), makePoint(2, 4), makePoint(3, 4), makePoint(4, 4), makePoint(6, 4), makePoint(7, 4), makePoint(8, 4), makePoint(6, 5), makePoint(8, 5), makePoint(1, 6), makePoint(2, 6), makePoint(3, 6), makePoint(4, 6), makePoint(5, 6), makePoint(6, 6), makePoint(8, 6), makePoint(2, 7), makePoint(2, 8), makePoint(4, 8), makePoint(5, 8), makePoint(6, 8), makePoint(7, 8), makePoint(8, 8), makePoint(9, 8), makePoint(4, 9), makePoint(2, 10), makePoint(3, 10), makePoint(4, 10), makePoint(5, 10), makePoint(6, 10), makePoint(7, 10), makePoint(8, 10)],
    { point: makePoint(7, 5), instrument: "trumpet" }
  )
];

const state = {
  levelIndex: 0,
  ball: { ...levels[0].start },
  visualBall: { ...levels[0].start },
  previousBall: { ...levels[0].start },
  moveStartedAt: 0,
  collected: 0,
  moves: 0,
  remainingBandKeys: new Set(levels[0].bandKeys),
  hasWon: false
};

function resetGame() {
  resetControls();
  state.levelIndex = 0;
  state.ball = { ...levels[0].start };
  state.visualBall = { ...levels[0].start };
  state.previousBall = { ...levels[0].start };
  state.moveStartedAt = performance.now();
  state.collected = 0;
  state.moves = 0;
  state.remainingBandKeys = new Set(levels[0].bandKeys);
  state.hasWon = false;
  victoryScreen.classList.add("hidden");
  playScreen.classList.remove("hidden");
  levelLabel.classList.remove("hidden");
  updateLevelMusic();
  draw();
}

function resetLevel() {
  resetControls();
  const level = levels[state.levelIndex];

  state.ball = { ...level.start };
  state.visualBall = { ...level.start };
  state.previousBall = { ...level.start };
  state.moveStartedAt = performance.now();
  state.collected = 0;
  state.moves = 0;
  state.remainingBandKeys = new Set(level.bandKeys);
  updateLevelMusic();
}

function startMoving(direction) {
  if (!direction) {
    activeInputDirection = null;
    return;
  }

  startLevelMusic();
  activeInputDirection = direction;

  if (moveRepeatTimer) {
    return;
  }

  move(direction);
  moveRepeatTimer = window.setInterval(() => {
    if (activeInputDirection) {
      move(activeInputDirection);
    }
  }, moveRepeatMs);
}

function stopMoving() {
  activeInputDirection = null;
  stopMoveTimer();
}

function stopMoveTimer() {
  if (!moveRepeatTimer) return;

  window.clearInterval(moveRepeatTimer);
  moveRepeatTimer = null;
}

function resetControls() {
  setActiveDpadDirection(null);
  stopMoving();
}

function setActiveDpadDirection(direction) {
  dpad.dataset.direction = direction || "";
  dpadButtons.forEach((button) => {
    button.classList.toggle("active", button.dataset.direction === direction);
  });
}

function directionFromSwipe(start, current) {
  const dx = current.x - start.x;
  const dy = current.y - start.y;
  const absX = Math.abs(dx);
  const absY = Math.abs(dy);

  if (Math.max(absX, absY) < swipeTurnThreshold) {
    return null;
  }

  if (absX > absY) {
    return dx < 0 ? "left" : "right";
  }

  return dy < 0 ? "up" : "down";
}

function move(direction) {
  if (state.hasWon) return false;

  const next = { ...state.ball };

  if (direction === "up") next.y -= 1;
  if (direction === "down") next.y += 1;
  if (direction === "left") next.x -= 1;
  if (direction === "right") next.x += 1;

  const level = levels[state.levelIndex];
  const nextKey = pointKey(next);

  if (level.wallKeys.has(nextKey)) {
    return false;
  }

  state.previousBall = { ...state.visualBall };
  state.ball = next;
  state.moveStartedAt = performance.now();
  state.moves += 1;

  if (state.remainingBandKeys.delete(nextKey)) {
    state.collected += 1;
  }

  if (state.remainingBandKeys.size === 0 && nextKey === pointKey(level.exit)) {
    completeLevel();
  }

  return true;
}

function completeLevel() {
  if (state.levelIndex === levels.length - 1) {
    state.hasWon = true;
    showVictory();
    return;
  }

  state.levelIndex += 1;
  const level = levels[state.levelIndex];
  state.ball = { ...level.start };
  state.visualBall = { ...level.start };
  state.previousBall = { ...level.start };
  state.moveStartedAt = performance.now();
  state.collected = 0;
  state.moves = 0;
  state.remainingBandKeys = new Set(level.bandKeys);
  updateLevelMusic();
}

function showVictory() {
  stopMoving();
  playVictoryMusic();
  startVictoryBall();
  playScreen.classList.add("hidden");
  levelLabel.classList.add("hidden");
  victoryScreen.classList.remove("hidden");
}

function startVictoryBall() {
  const speed = 0.13;
  const angle = Math.random() * Math.PI * 2;

  victoryBall.x = 14 + Math.random() * 42;
  victoryBall.y = 14 + Math.random() * 42;
  victoryBall.vx = Math.cos(angle) * speed;
  victoryBall.vy = Math.sin(angle) * speed;
  victoryBall.rotation = 0;
  victoryBall.lastUpdatedAt = performance.now();
  updateVictoryBallPosition();
}

function updateVictoryBall(now) {
  if (!state.hasWon) return;

  const rect = victoryScreen.getBoundingClientRect();
  if (!rect.width || !rect.height) return;

  const ballSize = boppingBall.offsetWidth || 48;
  const margin = 8;
  const maxX = Math.max(margin, rect.width - ballSize - margin);
  const maxY = Math.max(margin, rect.height - ballSize - margin);
  const elapsed = Math.min(34, now - victoryBall.lastUpdatedAt);
  victoryBall.lastUpdatedAt = now;

  victoryBall.x += victoryBall.vx * elapsed;
  victoryBall.y += victoryBall.vy * elapsed;
  victoryBall.rotation += elapsed * 0.32;

  if (victoryBall.x <= margin || victoryBall.x >= maxX) {
    victoryBall.x = Math.min(maxX, Math.max(margin, victoryBall.x));
    victoryBall.vx *= -1;
  }

  if (victoryBall.y <= margin || victoryBall.y >= maxY) {
    victoryBall.y = Math.min(maxY, Math.max(margin, victoryBall.y));
    victoryBall.vy *= -1;
  }

  updateVictoryBallPosition();
}

function updateVictoryBallPosition() {
  boppingBall.style.left = `${victoryBall.x}px`;
  boppingBall.style.top = `${victoryBall.y}px`;
  boppingBall.style.transform = `rotate(${victoryBall.rotation}deg)`;
}

function startLevelMusic() {
  musicWasStarted = true;
  updateLevelMusic();
  primeVictoryMusic();
}

function updateLevelMusic() {
  if (!musicWasStarted || state.hasWon) return;

  victoryMusic.muted = true;
  playMusicSource(levelMusicSources[state.levelIndex], false);
}

function playVictoryMusic() {
  if (!musicWasStarted) return;

  backgroundMusic.pause();
  currentMusicSource = "";
  victoryMusic.currentTime = 0;
  victoryMusic.muted = isMuted;
  victoryMusic.play().catch(() => {});
}

function playMusicSource(source, restart) {
  if (!source) return;

  if (currentMusicSource !== source) {
    backgroundMusic.src = source;
    currentMusicSource = source;
    backgroundMusic.currentTime = 0;
  } else if (restart) {
    backgroundMusic.currentTime = 0;
  }

  backgroundMusic.play().catch(() => {});
}

function toggleMute() {
  isMuted = !isMuted;
  backgroundMusic.muted = isMuted;
  victoryMusic.muted = isMuted || !state.hasWon;
  updateMuteButton();
}

function updateMuteButton() {
  muteButton.textContent = isMuted ? "Unmute" : "Mute";
  muteButton.setAttribute("aria-pressed", String(isMuted));
}

function primeVictoryMusic() {
  if (victoryMusicIsPrimed) return;

  victoryMusicIsPrimed = true;
  victoryMusic.muted = true;
  victoryMusic.play().catch(() => {
    victoryMusicIsPrimed = false;
  });
}

function draw(now = performance.now()) {
  const level = levels[state.levelIndex];
  const levelBandColor = rubberBandColors[state.levelIndex % 4];

  updateVisualBall(now);
  context.clearRect(0, 0, canvas.width, canvas.height);
  drawBackground();
  drawBackgroundAnimation(now);

  drawWalls(level);

  drawExit(level.exit, state.remainingBandKeys.size === 0);
  const instrumentalistKey = pointKey(level.instrumentalist.point);
  level.bands.forEach((band) => {
    if (state.remainingBandKeys.has(pointKey(band))) {
      if (pointKey(band) === instrumentalistKey) {
        drawInstrumentalist(band.x, band.y, tileSize * 0.72, levelBandColor, level.instrumentalist.instrument, now);
      } else {
        drawRubberBand(band.x, band.y, tileSize * 0.58, levelBandColor, now);
      }
    }
  });
  drawBall(state.visualBall.x, state.visualBall.y);
  updateLabels();
}

function drawBackground() {
  const background = levelBackgrounds[state.levelIndex];

  if (background?.complete && background.naturalWidth > 0) {
    context.drawImage(background, 0, 0, canvas.width, canvas.height);
    context.fillStyle = "rgba(3, 9, 12, 0.18)";
    context.fillRect(0, 0, canvas.width, canvas.height);
    return;
  }

  context.fillStyle = "#03090c";
  context.fillRect(0, 0, canvas.width, canvas.height);
}

function drawBackgroundAnimation(now) {
  drawSnow(now);
}

function drawSnow(now) {
  context.save();

  snowflakes.forEach((flake) => {
    const fall = (flake.y + now * flake.speed) % (canvas.height + 24);
    const sway = Math.sin(now * 0.0011 + flake.phase) * flake.drift;
    const x = (flake.x + sway + canvas.width) % canvas.width;
    const y = fall - 12;

    context.globalAlpha = 0.36 + (flake.radius - 1.2) * 0.12;
    context.fillStyle = "#ffffff";
    context.beginPath();
    context.arc(x, y, flake.radius, 0, Math.PI * 2);
    context.fill();
  });

  context.restore();
}

function updateVisualBall(now) {
  const progress = Math.min(1, (now - state.moveStartedAt) / ballTravelMs);
  const eased = progress * progress * (3 - 2 * progress);

  state.visualBall = {
    x: state.previousBall.x + (state.ball.x - state.previousBall.x) * eased,
    y: state.previousBall.y + (state.ball.y - state.previousBall.y) * eased
  };
}

function drawWalls(level) {
  context.save();
  context.lineCap = "round";
  context.lineJoin = "round";
  drawWallLayer(level, wallWidth + 8, "rgba(119, 230, 239, 0.22)");
  drawWallLayer(level, wallWidth, "#14616f");
  drawWallNodes(level, wallWidth * 0.52, "#14616f");
  drawWallNodes(level, wallWidth * 0.26, "rgba(119, 230, 239, 0.42)");
  context.restore();
}

function drawWallLayer(level, lineWidth, strokeStyle) {
  context.strokeStyle = strokeStyle;
  context.lineWidth = lineWidth;
  context.beginPath();

  level.wallKeys.forEach((key) => {
    const [x, y] = key.split(",").map(Number);
    const center = centerOf(x, y);
    const rightKey = pointKey(makePoint(x + 1, y));
    const downKey = pointKey(makePoint(x, y + 1));

    if (level.wallKeys.has(rightKey)) {
      const rightCenter = centerOf(x + 1, y);
      context.moveTo(center.x, center.y);
      context.lineTo(rightCenter.x, rightCenter.y);
    }

    if (level.wallKeys.has(downKey)) {
      const downCenter = centerOf(x, y + 1);
      context.moveTo(center.x, center.y);
      context.lineTo(downCenter.x, downCenter.y);
    }
  });

  context.stroke();
}

function drawWallNodes(level, radius, fillStyle) {
  context.fillStyle = fillStyle;

  level.wallKeys.forEach((key) => {
    const [x, y] = key.split(",").map(Number);
    const center = centerOf(x, y);

    context.beginPath();
    context.arc(center.x, center.y, radius, 0, Math.PI * 2);
    context.fill();
  });
}

function drawExit(exit, isOpen) {
  const center = centerOf(exit.x, exit.y);

  context.fillStyle = isOpen ? "#51d26b" : "rgba(255,255,255,0.45)";
  context.fillRect(center.x - 8, center.y - 18, 5, 34);
  context.beginPath();
  context.moveTo(center.x - 3, center.y - 18);
  context.lineTo(center.x + 20, center.y - 11);
  context.lineTo(center.x - 3, center.y - 3);
  context.closePath();
  context.fill();
}

function drawRubberBand(x, y, size, color, now) {
  const center = centerOf(x, y);
  const spin = now / 430;

  context.save();
  context.translate(center.x, center.y);
  context.rotate(spin);
  context.strokeStyle = color;
  context.lineWidth = Math.max(4, size * 0.16);
  context.shadowColor = color;
  context.shadowBlur = 8;
  drawEllipse(0, 0, size / 2, size * 0.24);
  context.restore();
}

function drawInstrumentalist(x, y, size, color, instrument, now) {
  const center = centerOf(x, y);
  const bounce = Math.sin(now / 120) * size * 0.08;

  context.save();
  context.translate(center.x, center.y + bounce);
  context.rotate(Math.sin(now / 180) * 0.12);
  context.strokeStyle = color;
  context.lineWidth = Math.max(3, size * 0.11);
  context.shadowColor = color;
  context.shadowBlur = 8;
  drawEllipse(0, 0, size * 0.25, size * 0.43);
  context.shadowBlur = 0;
  drawMiniInstrument(instrument, size);
  context.restore();
}

function drawMiniInstrument(instrument, size) {
  context.save();
  context.lineCap = "round";
  context.lineJoin = "round";

  if (instrument === "violin") {
    context.fillStyle = "#ad6428";
    context.strokeStyle = "#e2a14a";
    context.lineWidth = Math.max(2, size * 0.05);
    context.beginPath();
    context.ellipse(0, size * 0.02, size * 0.14, size * 0.2, 0, 0, Math.PI * 2);
    context.fill();
    context.stroke();
    context.strokeStyle = "#f7e8ba";
    context.lineWidth = Math.max(2, size * 0.04);
    context.beginPath();
    context.moveTo(size * 0.16, -size * 0.28);
    context.lineTo(size * 0.34, size * 0.3);
    context.stroke();
  }

  if (instrument === "drums") {
    context.fillStyle = "#d64b45";
    context.strokeStyle = "#f7f0d0";
    context.lineWidth = Math.max(2, size * 0.05);
    context.beginPath();
    context.rect(-size * 0.22, size * 0.06, size * 0.44, size * 0.22);
    context.fill();
    context.stroke();
    context.strokeStyle = "#f7e8ba";
    context.beginPath();
    context.moveTo(-size * 0.18, -size * 0.28);
    context.lineTo(-size * 0.04, size * 0.04);
    context.moveTo(size * 0.18, -size * 0.28);
    context.lineTo(size * 0.04, size * 0.04);
    context.stroke();
  }

  if (instrument === "clarinet") {
    context.strokeStyle = "#d7efff";
    context.lineWidth = Math.max(2, size * 0.08);
    context.beginPath();
    context.moveTo(-size * 0.08, -size * 0.3);
    context.lineTo(size * 0.08, size * 0.32);
    context.stroke();
    context.fillStyle = "#222";
    context.beginPath();
    context.ellipse(size * 0.1, size * 0.36, size * 0.13, size * 0.08, 0.25, 0, Math.PI * 2);
    context.fill();
  }

  if (instrument === "trumpet") {
    context.fillStyle = "#f6c94f";
    context.strokeStyle = "#f7d86e";
    context.lineWidth = Math.max(2, size * 0.04);
    context.beginPath();
    context.rect(-size * 0.28, -size * 0.04, size * 0.42, size * 0.12);
    context.fill();
    context.stroke();
    context.beginPath();
    context.moveTo(size * 0.1, -size * 0.14);
    context.lineTo(size * 0.36, -size * 0.25);
    context.lineTo(size * 0.36, size * 0.25);
    context.lineTo(size * 0.1, size * 0.14);
    context.closePath();
    context.fill();
    context.stroke();
  }

  context.restore();
}

function drawBall(x, y) {
  const center = centerOf(x, y);
  const radius = tileSize * (0.3 + state.collected * 0.009);
  const gradient = context.createRadialGradient(center.x - 12, center.y - 12, 4, center.x, center.y, radius);

  gradient.addColorStop(0, "#fff06a");
  gradient.addColorStop(0.55, "#f49a24");
  gradient.addColorStop(1, "#d7332b");

  context.fillStyle = gradient;
  context.shadowColor = "rgba(245, 158, 34, 0.5)";
  context.shadowBlur = 16;
  context.beginPath();
  context.arc(center.x, center.y, radius, 0, Math.PI * 2);
  context.fill();
  context.shadowBlur = 0;

  const bandCount = Math.max(3, state.collected + 3);
  for (let index = 0; index < bandCount; index += 1) {
    context.save();
    context.translate(center.x, center.y);
    context.rotate((index * 31 * Math.PI) / 180);
    context.strokeStyle = rubberBandColors[index % rubberBandColors.length];
    context.lineWidth = Math.max(3, radius * 0.16);
    drawEllipse(0, 0, radius * 0.82, radius * 0.36);
    context.restore();
  }
}

function drawEllipse(x, y, radiusX, radiusY) {
  context.beginPath();
  context.ellipse(x, y, radiusX, radiusY, 0, 0, Math.PI * 2);
  context.stroke();
}

function centerOf(x, y) {
  return {
    x: x * tileSize + tileSize / 2,
    y: y * tileSize + tileSize / 2
  };
}

function updateLabels() {
  const level = levels[state.levelIndex];
  levelLabel.textContent = `Level ${level.number}/${levels.length}`;
  collectedLabel.textContent = `${state.collected} collected`;
  remainingLabel.textContent = `${state.remainingBandKeys.size} left`;
  movesLabel.textContent = `${state.moves} moves`;
}

dpadButtons.forEach((button) => {
  button.addEventListener("pointerdown", (event) => {
    event.preventDefault();
    button.setPointerCapture(event.pointerId);
    setActiveDpadDirection(button.dataset.direction);
    startMoving(button.dataset.direction);
  });

  button.addEventListener("pointerup", (event) => {
    if (button.hasPointerCapture(event.pointerId)) {
      button.releasePointerCapture(event.pointerId);
    }

    resetControls();
  });

  button.addEventListener("pointercancel", resetControls);
  button.addEventListener("pointerleave", (event) => {
    if (event.pointerType === "mouse") {
      resetControls();
    }
  });
});

playScreen.addEventListener("pointerdown", (event) => {
  if (event.target.closest("button")) return;

  event.preventDefault();
  swipePointerId = event.pointerId;
  swipeAnchor = { x: event.clientX, y: event.clientY };
  playScreen.setPointerCapture(event.pointerId);
});

playScreen.addEventListener("pointermove", (event) => {
  if (event.pointerId !== swipePointerId || !swipeAnchor) return;

  event.preventDefault();
  const current = { x: event.clientX, y: event.clientY };
  const direction = directionFromSwipe(swipeAnchor, current);

  if (!direction) {
    resetControls();
    return;
  }

  setActiveDpadDirection(direction);
  startMoving(direction);
});

playScreen.addEventListener("pointerup", (event) => {
  if (event.pointerId !== swipePointerId) return;

  if (playScreen.hasPointerCapture(event.pointerId)) {
    playScreen.releasePointerCapture(event.pointerId);
  }

  swipePointerId = null;
  swipeAnchor = null;
  resetControls();
});

playScreen.addEventListener("pointercancel", () => {
  swipePointerId = null;
  swipeAnchor = null;
  resetControls();
});

document.addEventListener("keydown", (event) => {
  const keyMap = {
    ArrowUp: "up",
    w: "up",
    W: "up",
    ArrowDown: "down",
    s: "down",
    S: "down",
    ArrowLeft: "left",
    a: "left",
    A: "left",
    ArrowRight: "right",
    d: "right",
    D: "right"
  };

  const direction = keyMap[event.key];
  if (!direction) return;

  event.preventDefault();
  activeKeyDirection = direction;
  setActiveDpadDirection(direction);
  startMoving(direction);
});

document.addEventListener("keyup", (event) => {
  const keyMap = {
    ArrowUp: "up",
    w: "up",
    W: "up",
    ArrowDown: "down",
    s: "down",
    S: "down",
    ArrowLeft: "left",
    a: "left",
    A: "left",
    ArrowRight: "right",
    d: "right",
    D: "right"
  };

  if (keyMap[event.key] !== activeKeyDirection) return;

  activeKeyDirection = null;
  resetControls();
});

window.addEventListener("blur", () => {
  activeKeyDirection = null;
  resetControls();
});

playAgainButton.addEventListener("click", () => {
  resetGame();
  startLevelMusic();
});
restartLevelButton.addEventListener("click", () => {
  resetLevel();
  startLevelMusic();
});
muteButton.addEventListener("click", toggleMute);
playScreen.addEventListener("contextmenu", (event) => event.preventDefault());
playScreen.addEventListener("selectstart", (event) => event.preventDefault());
updateMuteButton();
startLevelMusic();

function animationLoop(now) {
  draw(now);
  updateVictoryBall(now);
  window.requestAnimationFrame(animationLoop);
}

window.requestAnimationFrame(animationLoop);
