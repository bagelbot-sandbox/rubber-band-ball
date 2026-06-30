const canvas = document.querySelector("#gameCanvas");
const context = canvas.getContext("2d");
const levelLabel = document.querySelector("#levelLabel");
const collectedLabel = document.querySelector("#collectedLabel");
const remainingLabel = document.querySelector("#remainingLabel");
const movesLabel = document.querySelector("#movesLabel");
const exitLabel = document.querySelector("#exitLabel");
const playScreen = document.querySelector("#playScreen");
const victoryScreen = document.querySelector("#victoryScreen");
const playAgainButton = document.querySelector("#playAgainButton");
const restartLevelButton = document.querySelector("#restartLevelButton");
const joystick = document.querySelector("#joystick");
const joystickKnob = document.querySelector("#joystickKnob");
const danceFloor = document.querySelector("#danceFloor");

const width = 11;
const height = 13;
const tileSize = canvas.width / width;
const rubberBandColors = ["#fac737", "#f2473f", "#40b9f2", "#5bc76d", "#d96ef2"];
const joystickMaxOffset = 46;
const joystickDeadZone = 14;
const moveRepeatMs = 150;
const ballTravelMs = 145;

const pointKey = (point) => `${point.x},${point.y}`;
const makePoint = (x, y) => ({ x, y });
let activeInputDirection = null;
let activeKeyDirection = null;
let moveRepeatTimer = null;
let lastFrameTime = 0;

const makeLevel = (number, start, exit, bands, innerWalls) => {
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
    wallKeys
  };
};

const levels = [
  makeLevel(
    1,
    makePoint(1, 1),
    makePoint(9, 11),
    [makePoint(3, 1), makePoint(7, 2), makePoint(2, 6), makePoint(8, 7), makePoint(5, 10)],
    [makePoint(4, 2), makePoint(4, 3), makePoint(4, 4), makePoint(6, 5), makePoint(7, 5), makePoint(8, 5), makePoint(2, 8), makePoint(3, 8), makePoint(4, 8)]
  ),
  makeLevel(
    2,
    makePoint(1, 11),
    makePoint(9, 1),
    [makePoint(2, 9), makePoint(5, 9), makePoint(8, 8), makePoint(3, 4), makePoint(7, 2)],
    [makePoint(2, 2), makePoint(3, 2), makePoint(4, 2), makePoint(6, 3), makePoint(6, 4), makePoint(6, 5), makePoint(4, 7), makePoint(5, 7), makePoint(6, 7), makePoint(8, 10)]
  ),
  makeLevel(
    3,
    makePoint(5, 11),
    makePoint(5, 1),
    [makePoint(1, 9), makePoint(9, 9), makePoint(2, 5), makePoint(8, 5), makePoint(5, 3)],
    [makePoint(3, 2), makePoint(3, 3), makePoint(3, 4), makePoint(7, 2), makePoint(7, 3), makePoint(7, 4), makePoint(3, 8), makePoint(4, 8), makePoint(6, 8), makePoint(7, 8)]
  ),
  makeLevel(
    4,
    makePoint(9, 11),
    makePoint(1, 1),
    [makePoint(8, 10), makePoint(5, 10), makePoint(2, 8), makePoint(4, 4), makePoint(8, 2)],
    [makePoint(2, 3), makePoint(2, 4), makePoint(2, 5), makePoint(5, 2), makePoint(5, 3), makePoint(5, 4), makePoint(7, 6), makePoint(8, 6), makePoint(9, 6), makePoint(4, 9), makePoint(5, 9), makePoint(6, 9)]
  ),
  makeLevel(
    5,
    makePoint(1, 6),
    makePoint(9, 6),
    [makePoint(2, 2), makePoint(8, 2), makePoint(5, 5), makePoint(2, 10), makePoint(8, 10)],
    [makePoint(4, 1), makePoint(4, 2), makePoint(4, 3), makePoint(6, 9), makePoint(6, 10), makePoint(6, 11), makePoint(2, 6), makePoint(3, 6), makePoint(7, 6), makePoint(8, 6)]
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
  resetJoystick();
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
  draw();
}

function resetLevel() {
  resetJoystick();
  const level = levels[state.levelIndex];

  state.ball = { ...level.start };
  state.visualBall = { ...level.start };
  state.previousBall = { ...level.start };
  state.moveStartedAt = performance.now();
  state.collected = 0;
  state.moves = 0;
  state.remainingBandKeys = new Set(level.bandKeys);
}

function startMoving(direction) {
  if (!direction) {
    stopMoving();
    return;
  }

  if (activeInputDirection === direction && moveRepeatTimer) return;

  stopMoveTimer();
  activeInputDirection = direction;
  move(direction);
  moveRepeatTimer = window.setInterval(() => move(direction), moveRepeatMs);
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

function updateJoystickFromPointer(event) {
  const rect = joystick.getBoundingClientRect();
  const centerX = rect.left + rect.width / 2;
  const centerY = rect.top + rect.height / 2;
  const rawOffset = {
    x: event.clientX - centerX,
    y: event.clientY - centerY
  };
  const offset = clampJoystickOffset(rawOffset);

  joystickKnob.style.transform = `translate(${offset.x}px, ${offset.y}px)`;
  startMoving(directionFromOffset(offset));
}

function resetJoystick() {
  joystickKnob.style.transform = "translate(0, 0)";
  stopMoving();
}

function clampJoystickOffset(offset) {
  const distance = Math.hypot(offset.x, offset.y);

  if (distance <= joystickMaxOffset) {
    return offset;
  }

  const scale = joystickMaxOffset / distance;
  return {
    x: offset.x * scale,
    y: offset.y * scale
  };
}

function directionFromOffset(offset) {
  if (Math.max(Math.abs(offset.x), Math.abs(offset.y)) < joystickDeadZone) {
    return null;
  }

  if (Math.abs(offset.x) > Math.abs(offset.y)) {
    return offset.x < 0 ? "left" : "right";
  }

  return offset.y < 0 ? "up" : "down";
}

function move(direction) {
  if (state.hasWon) return;

  const next = { ...state.ball };

  if (direction === "up") next.y -= 1;
  if (direction === "down") next.y += 1;
  if (direction === "left") next.x -= 1;
  if (direction === "right") next.x += 1;

  const level = levels[state.levelIndex];
  const nextKey = pointKey(next);

  if (level.wallKeys.has(nextKey)) {
    return;
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
}

function showVictory() {
  stopMoving();
  playScreen.classList.add("hidden");
  levelLabel.classList.add("hidden");
  victoryScreen.classList.remove("hidden");
}

function draw(now = performance.now()) {
  const level = levels[state.levelIndex];

  updateVisualBall(now);
  context.clearRect(0, 0, canvas.width, canvas.height);
  context.fillStyle = "#03090c";
  context.fillRect(0, 0, canvas.width, canvas.height);

  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) {
      drawTile(x, y, level);
    }
  }

  drawExit(level.exit, state.remainingBandKeys.size === 0);
  level.bands.forEach((band) => {
    if (state.remainingBandKeys.has(pointKey(band))) {
      drawRubberBand(band.x, band.y, tileSize * 0.58, "#fac737", now);
    }
  });
  drawBall(state.visualBall.x, state.visualBall.y);
  updateLabels();
}

function updateVisualBall(now) {
  const progress = Math.min(1, (now - state.moveStartedAt) / ballTravelMs);
  const eased = progress * progress * (3 - 2 * progress);

  state.visualBall = {
    x: state.previousBall.x + (state.ball.x - state.previousBall.x) * eased,
    y: state.previousBall.y + (state.ball.y - state.previousBall.y) * eased
  };
}

function drawTile(x, y, level) {
  const key = pointKey(makePoint(x, y));
  const px = x * tileSize;
  const py = y * tileSize;

  if (level.wallKeys.has(key)) {
    context.fillStyle = "#14616f";
    context.fillRect(px + 2, py + 2, tileSize - 4, tileSize - 4);
    context.strokeStyle = "rgba(119, 230, 239, 0.6)";
    context.lineWidth = 2;
    context.strokeRect(px + 3, py + 3, tileSize - 6, tileSize - 6);
  } else {
    context.fillStyle = "rgba(255,255,255,0.035)";
    context.fillRect(px, py, tileSize, tileSize);
    context.strokeStyle = "rgba(255,255,255,0.05)";
    context.lineWidth = 1;
    context.strokeRect(px, py, tileSize, tileSize);
  }
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

function drawBall(x, y) {
  const center = centerOf(x, y);
  const radius = tileSize * (0.32 + state.collected * 0.025);
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
  levelLabel.textContent = `Level ${level.number}/5`;
  collectedLabel.textContent = `${state.collected} collected`;
  remainingLabel.textContent = `${state.remainingBandKeys.size} left`;
  movesLabel.textContent = `${state.moves} moves`;
  exitLabel.textContent = state.remainingBandKeys.size === 0 ? "Find exit" : "Collect bands";
}

joystick.addEventListener("pointerdown", (event) => {
  event.preventDefault();
  joystick.setPointerCapture(event.pointerId);
  updateJoystickFromPointer(event);
});

joystick.addEventListener("pointermove", (event) => {
  if (!joystick.hasPointerCapture(event.pointerId)) return;

  event.preventDefault();
  updateJoystickFromPointer(event);
});

joystick.addEventListener("pointerup", (event) => {
  if (joystick.hasPointerCapture(event.pointerId)) {
    joystick.releasePointerCapture(event.pointerId);
  }

  resetJoystick();
});

joystick.addEventListener("pointercancel", resetJoystick);

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
  stopMoving();
});

window.addEventListener("blur", () => {
  activeKeyDirection = null;
  resetJoystick();
});

playAgainButton.addEventListener("click", resetGame);
restartLevelButton.addEventListener("click", resetLevel);

rubberBandColors.concat(rubberBandColors, rubberBandColors).slice(0, 12).forEach((color, index) => {
  const band = document.createElement("span");
  band.className = "dancing-band";
  band.style.color = color;
  band.style.setProperty("--angle", `${index * 30}deg`);
  band.style.setProperty("--radius", `${82 + (index % 3) * 14}px`);
  band.style.animationDelay = `${index * -0.08}s`;
  danceFloor.appendChild(band);
});

draw();
