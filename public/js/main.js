import * as THREE from "three";
import { createGraphics } from "./graphics.js";
import { buildFactory, resolveCollisions } from "./factory.js";
import { createClampRig } from "./clamprig.js";
import { createHushhorn, updateHushhorn } from "./creature.js";
import { createIvorymaw, updateIvorymaw } from "./ivorymaw.js";
import { createFlashlight } from "./flashlight.js";
import { resumeAudio, pianoChatter, pianoStalk, jumpscareSlam } from "./audio.js";
import { createMenuScene } from "./menu-scene.js";

const SAVE_KEY = "wirebound-save";

const els = {
  menu: document.getElementById("menu"),
  hud: document.getElementById("hud"),
  canvas: document.getElementById("game"),
  menuCanvas: document.getElementById("menu-canvas"),
  hint: document.getElementById("hint"),
  obj: document.getElementById("objective"),
  toast: document.getElementById("toast"),
  end: document.getElementById("end"),
  endTitle: document.getElementById("end-title"),
  endBody: document.getElementById("end-body"),
  settings: document.getElementById("settings"),
  credits: document.getElementById("credits"),
  continueBtn: document.getElementById("btn-continue"),
  scare: document.getElementById("jumpscare"),
  flashHud: document.getElementById("flash-state"),
};

let quality = localStorage.getItem("wb-quality") || "ultra";
let menuGfx = null;
let menuWorld = null;
let menuRaf = 0;
let game = null;

initMenu();
wireUi();

function enterFullscreen() {
  const root = document.documentElement;
  if (!document.fullscreenElement) {
    root.requestFullscreen?.() || root.webkitRequestFullscreen?.();
  }
}

function wireUi() {
  const save = localStorage.getItem(SAVE_KEY);
  els.continueBtn.disabled = !save;
  els.continueBtn.classList.toggle("dim", !save);

  document.getElementById("btn-continue").onclick = () => startGame(true);
  document.getElementById("btn-new").onclick = () => {
    localStorage.removeItem(SAVE_KEY);
    startGame(false);
  };
  document.getElementById("btn-settings").onclick = () => togglePanel("settings");
  document.getElementById("btn-credits").onclick = () => togglePanel("credits");
  document.getElementById("btn-fullscreen").onclick = () => {
    enterFullscreen();
    showToast("Fullscreen");
  };
  document.getElementById("btn-quit").onclick = () => {
    showToast("Close the tab to quit.");
  };
  document.getElementById("settings-close").onclick = () => els.settings.classList.add("hidden");
  document.getElementById("credits-close").onclick = () => els.credits.classList.add("hidden");
  document.getElementById("again-btn").onclick = () => {
    els.end.classList.add("hidden");
    els.scare.classList.add("hidden");
    showMenu();
  };
  document.getElementById("leave-btn").onclick = () => {
    if (game) {
      saveGame();
      game.dispose();
      game = null;
    }
    showMenu();
  };
  document.querySelectorAll("[data-quality]").forEach((btn) => {
    btn.classList.toggle("selected", btn.dataset.quality === quality);
    btn.onclick = () => {
      quality = btn.dataset.quality;
      localStorage.setItem("wb-quality", quality);
      document.querySelectorAll("[data-quality]").forEach((b) => b.classList.toggle("selected", b.dataset.quality === quality));
      restartMenuGfx();
    };
  });
}

function togglePanel(id) {
  const panel = document.getElementById(id);
  const other = id === "settings" ? els.credits : els.settings;
  other.classList.add("hidden");
  panel.classList.toggle("hidden");
}

function initMenu() {
  restartMenuGfx();
}

function restartMenuGfx() {
  cancelAnimationFrame(menuRaf);
  menuGfx?.dispose();
  menuGfx = createGraphics(els.menuCanvas, quality);
  menuWorld = createMenuScene(menuGfx.renderer);
  menuGfx.makeEnvironment(menuWorld.scene);
  let last = performance.now();
  const loop = (now) => {
    if (!els.hud.classList.contains("hidden")) return;
    const dt = Math.min(0.05, (now - last) / 1000);
    last = now;
    menuWorld.tick(dt);
    menuGfx.render(menuWorld.scene, menuWorld.camera, now / 1000);
    menuRaf = requestAnimationFrame(loop);
  };
  const onResize = () => {
    menuGfx.resize();
    menuWorld.resize();
  };
  window.addEventListener("resize", onResize);
  menuRaf = requestAnimationFrame(loop);
}

function showMenu() {
  els.hud.classList.add("hidden");
  els.end.classList.add("hidden");
  els.scare.classList.add("hidden");
  els.menu.classList.remove("hidden");
  els.continueBtn.disabled = !localStorage.getItem(SAVE_KEY);
  els.continueBtn.classList.toggle("dim", els.continueBtn.disabled);
  restartMenuGfx();
}

function startGame(resume) {
  enterFullscreen();
  resumeAudio();
  cancelAnimationFrame(menuRaf);
  menuGfx?.dispose();
  menuGfx = null;
  els.menu.classList.add("hidden");
  els.settings.classList.add("hidden");
  els.credits.classList.add("hidden");
  els.end.classList.add("hidden");
  els.scare.classList.add("hidden");
  els.hud.classList.remove("hidden");
  if (game) game.dispose();
  game = createGame(resume);
  game.start();
}

function showToast(text, ms = 1600) {
  els.toast.textContent = text;
  els.toast.classList.remove("hidden");
  clearTimeout(showToast._t);
  showToast._t = setTimeout(() => els.toast.classList.add("hidden"), ms);
}

function saveGame() {
  if (!game?.snapshot) return;
  localStorage.setItem(SAVE_KEY, JSON.stringify(game.snapshot()));
}

function createGame(resume) {
  const gfx = createGraphics(els.canvas, quality);
  gfx.renderer.toneMappingExposure = 0.52;
  const scene = new THREE.Scene();
  scene.fog = new THREE.FogExp2(0x060103, 0.078);
  scene.background = new THREE.Color(0x030001);
  gfx.makeEnvironment(scene);

  const camera = new THREE.PerspectiveCamera(68, innerWidth / innerHeight, 0.08, 90);
  scene.add(camera);
  const factory = buildFactory(scene);

  const hemi = new THREE.HemisphereLight(0xff6655, 0x080103, 0.08);
  scene.add(hemi);
  const bounce = new THREE.DirectionalLight(0x44222a, 0.08);
  bounce.position.set(-8, 6, 4);
  scene.add(bounce);

  const player = new THREE.Group();
  player.position.copy(factory.spawn);
  scene.add(player);

  const hush = createHushhorn();
  hush.position.set(-6.5, 0, 18);
  scene.add(hush);

  const ivory = createIvorymaw();
  ivory.position.set(0.4, 0, 28);
  scene.add(ivory);

  const look = { yaw: 0, pitch: 0 };
  const vel = new THREE.Vector3();
  const keys = new Set();
  const rig = createClampRig(camera, scene);
  const flash = createFlashlight(camera);
  flash.setOn(true);
  camera.rotation.order = "YXZ";

  const state = {
    alive: true,
    won: false,
    stamina: 100,
    gateOpen: false,
    scare: false,
    scareUntil: 0,
    baseFov: 68,
  };

  if (resume) {
    try {
      const s = JSON.parse(localStorage.getItem(SAVE_KEY) || "null");
      if (s?.pos) player.position.set(s.pos[0], 0, s.pos[1]);
      if (s?.yaw != null) look.yaw = s.yaw;
    } catch {
      /* ignore */
    }
  }

  const onKey = (e, down) => {
    if (["KeyW", "KeyA", "KeyS", "KeyD", "ShiftLeft", "ShiftRight", "KeyF"].includes(e.code)) {
      e.preventDefault();
      if (down) keys.add(e.code);
      else keys.delete(e.code);
    }
    if (down && e.code === "KeyF") {
      const on = flash.toggle();
      els.flashHud.textContent = on ? "FLASHLIGHT ON" : "FLASHLIGHT OFF";
      showToast(on ? "Flashlight on" : "Flashlight off");
    }
    if (down && e.code === "F11") {
      e.preventDefault();
      if (document.fullscreenElement) document.exitFullscreen?.();
      else enterFullscreen();
    }
  };

  const onMouse = (e) => {
    if (state.scare) return;
    if (document.pointerLockElement !== els.canvas) return;
    look.yaw -= e.movementX * 0.002;
    look.pitch -= e.movementY * 0.002;
    look.pitch = THREE.MathUtils.clamp(look.pitch, -1.15, 1.15);
  };

  const onDown = (e) => {
    if (document.pointerLockElement !== els.canvas) {
      els.canvas.requestPointerLock();
      resumeAudio();
      return;
    }
    if (e.button === 0) rig.fire("left", factory.hits);
    if (e.button === 2) {
      e.preventDefault();
      rig.fire("right", factory.hits);
    }
  };
  const onUp = (e) => {
    if (e.button === 0) rig.release("left");
    if (e.button === 2) rig.release("right");
  };

  const onResize = () => {
    camera.aspect = innerWidth / innerHeight;
    camera.updateProjectionMatrix();
    gfx.resize();
  };

  let raf = 0;
  let last = performance.now();
  let running = false;
  let chatterAcc = 0;

  function tick(nowMs) {
    if (!running) return;
    const dt = Math.min(0.05, (nowMs - last) / 1000);
    last = nowMs;
    const now = nowMs / 1000;

    camera.rotation.y = look.yaw;
    camera.rotation.x = look.pitch;
    camera.position.copy(player.position);
    camera.position.y = 1.62;

    if (!state.scare) {
      const forward = new THREE.Vector3(0, 0, -1).applyAxisAngle(new THREE.Vector3(0, 1, 0), look.yaw);
      const right = new THREE.Vector3(1, 0, 0).applyAxisAngle(new THREE.Vector3(0, 1, 0), look.yaw);
      const wish = new THREE.Vector3();
      if (keys.has("KeyW")) wish.add(forward);
      if (keys.has("KeyS")) wish.sub(forward);
      if (keys.has("KeyD")) wish.add(right);
      if (keys.has("KeyA")) wish.sub(right);

      const sprint = (keys.has("ShiftLeft") || keys.has("ShiftRight")) && state.stamina > 0;
      let speed = sprint ? 7.4 : 5.1;
      if (sprint && wish.lengthSq()) state.stamina = Math.max(0, state.stamina - 18 * dt);
      else state.stamina = Math.min(100, state.stamina + 12 * dt);

      if (wish.lengthSq()) {
        wish.normalize().multiplyScalar(speed * dt);
        player.position.add(wish);
      }
      player.position.addScaledVector(vel, dt);
      resolveCollisions(player.position, factory.colliders, 0.38);
      player.position.y = 0;
    }

    rig.update(dt, factory.hits, player.position, vel);
    factory.gate.update(dt);
    const gateCol = factory.colliders.find((c) => c.gate);
    if (gateCol) gateCol.disabled = factory.gate.open;

    if (factory.dust) {
      factory.dust.rotation.y += dt * 0.02;
      const arr = factory.dust.geometry.attributes.position.array;
      for (let i = 1; i < arr.length; i += 3) {
        arr[i] += dt * 0.12;
        if (arr[i] > 4.4) arr[i] = 0.1;
      }
      factory.dust.geometry.attributes.position.needsUpdate = true;
    }

    const ivoryInfo = updateIvorymaw(ivory, dt, camera, player.position, flash.isOn());
    const panic = ivoryInfo.dist < 9 || ivoryInfo.inBeam || state.scare;
    flash.update(dt, panic);

    chatterAcc += dt;
    if (ivoryInfo.inBeam || ivoryInfo.dist < 11) {
      if (chatterAcc > 0.09) {
        chatterAcc = 0;
        pianoChatter(ivoryInfo.inBeam ? 1 : 0.45);
      }
    }
    pianoStalk(ivoryInfo.dist);

    if (ivoryInfo.jumpscare && !state.scare) {
      state.scare = true;
      state.scareUntil = now + 0.62;
      jumpscareSlam();
      els.scare.classList.remove("hidden");
      document.body.classList.add("shaking");
    }

    if (state.scare) {
      const k = Math.min(1, 1 - (state.scareUntil - now) / 0.62);
      camera.fov = THREE.MathUtils.lerp(state.baseFov, 102, k);
      camera.updateProjectionMatrix();
      look.pitch += (Math.random() - 0.5) * 0.08;
      look.yaw += (Math.random() - 0.5) * 0.06;
      els.scare.style.opacity = String(0.35 + k * 0.55);
      if (now >= state.scareUntil) {
        state.alive = false;
        state.won = false;
      }
    } else {
      camera.fov = state.baseFov;
      camera.updateProjectionMatrix();
    }

    const charged = factory.gate.sockets.filter((s) => s.charged).length;
    els.obj.textContent = factory.gate.open
      ? "Gate open — don't look too long"
      : `ClampRig 2.0 · sockets ${charged}/2`;
    els.hint.textContent = state.scare
      ? ""
      : "F flashlight · LMB blue · RMB red · don't stare at Ivorymaw";

    updateHushhorn(hush, dt, player.position, factory.gate.open ? 3.6 : 2.4);

    if (!state.scare && player.position.distanceTo(hush.position) < 1.35) {
      state.alive = false;
      state.won = false;
    }
    if (factory.gate.open && player.position.z > factory.exitZ) {
      state.alive = false;
      state.won = true;
    }

    gfx.render(scene, camera, now);
    document.getElementById("stamina-fill").style.transform = `scaleX(${state.stamina / 100})`;

    if (!state.alive) {
      stop(state.won ? "win" : ivoryInfo.jumpscare || state.scare ? "ivory" : "lose");
      return;
    }
    raf = requestAnimationFrame(tick);
  }

  function stop(reason) {
    running = false;
    cancelAnimationFrame(raf);
    document.exitPointerLock?.();
    document.body.classList.remove("shaking");
    if (reason === "win") localStorage.removeItem(SAVE_KEY);
    els.hud.classList.add("hidden");
    if (reason === "left") {
      els.scare.classList.add("hidden");
      showMenu();
      return;
    }
    if (reason !== "ivory") els.scare.classList.add("hidden");
    els.end.classList.remove("hidden");
    if (reason === "win") {
      els.endTitle.textContent = "Shift complete";
      els.endBody.textContent = "The ClampRig still hums. The factory does not let go — it only lets you pass.";
    } else if (reason === "ivory") {
      els.endTitle.textContent = "The keys closed";
      els.endBody.textContent = "Ivorymaw does not roar. It plays you. Every broken note is a tooth.";
    } else {
      els.endTitle.textContent = "It found you";
      els.endBody.textContent = "Hushhorn does not run. It waits until the cables go slack.";
    }
  }

  const onKeyDown = (e) => onKey(e, true);
  const onKeyUp = (e) => onKey(e, false);
  const onContext = (e) => e.preventDefault();

  function start() {
    running = true;
    last = performance.now();
    window.addEventListener("keydown", onKeyDown);
    window.addEventListener("keyup", onKeyUp);
    window.addEventListener("mousemove", onMouse);
    window.addEventListener("resize", onResize);
    els.canvas.addEventListener("mousedown", onDown);
    window.addEventListener("mouseup", onUp);
    els.canvas.addEventListener("contextmenu", onContext);
    els.flashHud.textContent = "FLASHLIGHT ON";
    showToast("F flashlight · click to lock mouse");
    raf = requestAnimationFrame(tick);
  }

  function dispose() {
    running = false;
    cancelAnimationFrame(raf);
    window.removeEventListener("keydown", onKeyDown);
    window.removeEventListener("keyup", onKeyUp);
    window.removeEventListener("mousemove", onMouse);
    window.removeEventListener("resize", onResize);
    els.canvas.removeEventListener("mousedown", onDown);
    window.removeEventListener("mouseup", onUp);
    els.canvas.removeEventListener("contextmenu", onContext);
    document.body.classList.remove("shaking");
    rig.dispose();
    gfx.dispose();
    document.exitPointerLock?.();
  }

  function snapshot() {
    return { pos: [player.position.x, player.position.z], yaw: look.yaw };
  }

  return { start, dispose, snapshot };
}
