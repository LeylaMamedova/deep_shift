import * as THREE from "three";

/**
 * Original piano-jaw predator — Ivorymaw.
 * Not Pianosaurus / Poppy Playtime. Broken upright-piano skull, stop-motion stalk, jumpscare lunge.
 */
export function createIvorymaw() {
  const root = new THREE.Group();
  root.name = "Ivorymaw";

  const hide = mat(0x121014, 0x1a0808, 0.08, 0.78, 0.12);
  const bone = mat(0xcfc6b0, 0x3a3018, 0.06, 0.42, 0.08);
  const rot = mat(0x2a1a14, 0x4a1008, 0.2, 0.7, 0.05);
  const iron = mat(0x1a1a1c, 0x000000, 0, 0.35, 0.72);
  const gum = mat(0x3a0508, 0x7a1020, 0.55, 0.55, 0.05);

  const hips = new THREE.Mesh(new THREE.SphereGeometry(0.42, 12, 10), hide);
  hips.scale.set(1.15, 0.85, 1.35);
  hips.position.y = 1.15;
  hips.castShadow = true;
  root.add(hips);

  const torso = new THREE.Mesh(new THREE.CylinderGeometry(0.38, 0.5, 1.15, 10), hide);
  torso.position.set(0, 1.85, 0.05);
  torso.rotation.x = 0.35;
  torso.castShadow = true;
  root.add(torso);

  for (let i = 0; i < 5; i++) {
    const rib = new THREE.Mesh(new THREE.TorusGeometry(0.32, 0.018, 5, 10, Math.PI), iron);
    rib.position.set(0, 1.55 + i * 0.16, 0.22);
    rib.rotation.x = 1.2;
    root.add(rib);
  }

  const jaw = new THREE.Group();
  jaw.name = "jaw";
  jaw.position.set(0, 2.15, 0.55);
  root.add(jaw);

  const caseBox = new THREE.Mesh(new THREE.BoxGeometry(1.15, 0.72, 0.55), rot);
  caseBox.position.set(0, 0.22, 0);
  caseBox.castShadow = true;
  jaw.add(caseBox);

  const lid = new THREE.Mesh(new THREE.BoxGeometry(1.18, 0.08, 0.7), rot);
  lid.position.set(0, 0.62, -0.08);
  lid.name = "lid";
  jaw.add(lid);

  const mouth = new THREE.Mesh(new THREE.BoxGeometry(0.95, 0.22, 0.35), gum);
  mouth.position.set(0, 0.02, 0.12);
  jaw.add(mouth);

  const keys = [];
  const whiteW = 0.07;
  for (let i = 0; i < 14; i++) {
    const broken = Math.random() < 0.28;
    const k = new THREE.Mesh(
      new THREE.BoxGeometry(whiteW, broken ? 0.08 : 0.16, 0.32),
      bone
    );
    k.position.set(-0.46 + i * 0.072, broken ? -0.08 : -0.12, 0.28);
    k.rotation.x = broken ? 0.55 + Math.random() * 0.7 : 0.15;
    k.rotation.z = (Math.random() - 0.5) * 0.2;
    jaw.add(k);
    keys.push(k);
  }
  for (let i = 0; i < 10; i++) {
    if (i === 2 || i === 6) continue;
    const k = new THREE.Mesh(new THREE.BoxGeometry(0.045, 0.1, 0.2), iron);
    k.position.set(-0.42 + i * 0.09, -0.02, 0.22);
    jaw.add(k);
    keys.push(k);
  }

  for (const s of [-1, 1]) {
    const fang = new THREE.Mesh(new THREE.BoxGeometry(0.06, 0.28, 0.06), bone);
    fang.position.set(s * 0.52, -0.18, 0.3);
    fang.rotation.z = s * 0.4;
    fang.rotation.x = 0.5;
    jaw.add(fang);
  }

  const socketMat = new THREE.MeshStandardMaterial({
    color: 0x090000,
    emissive: 0xff2208,
    emissiveIntensity: 0.15,
    roughness: 0.4,
  });
  for (const s of [-1, 1]) {
    const hole = new THREE.Mesh(new THREE.CylinderGeometry(0.07, 0.09, 0.08, 10), socketMat);
    hole.rotation.x = Math.PI / 2;
    hole.position.set(s * 0.22, 0.38, 0.28);
    hole.name = s < 0 ? "eyeL" : "eyeR";
    jaw.add(hole);
  }

  const eyeLight = new THREE.PointLight(0xff1a00, 0.25, 4.5);
  eyeLight.name = "eyeLight";
  eyeLight.position.set(0, 2.35, 0.9);
  root.add(eyeLight);

  const thighGeo = new THREE.CylinderGeometry(0.14, 0.2, 0.85, 8);
  const shinGeo = new THREE.CylinderGeometry(0.08, 0.12, 0.75, 8);
  for (const s of [-1, 1]) {
    const thigh = new THREE.Mesh(thighGeo, hide);
    thigh.position.set(s * 0.28, 0.85, -0.05);
    thigh.rotation.z = s * 0.12;
    thigh.castShadow = true;
    root.add(thigh);
    const shin = new THREE.Mesh(shinGeo, hide);
    shin.position.set(s * 0.34, 0.28, 0.12);
    shin.castShadow = true;
    root.add(shin);
    const claw = new THREE.Mesh(new THREE.BoxGeometry(0.22, 0.08, 0.38), iron);
    claw.position.set(s * 0.34, 0.05, 0.28);
    root.add(claw);
    const arm = new THREE.Mesh(new THREE.CylinderGeometry(0.05, 0.07, 0.55, 6), hide);
    arm.position.set(s * 0.42, 1.85, 0.35);
    arm.rotation.z = s * 0.9;
    arm.rotation.x = 0.4;
    root.add(arm);
    const hammer = new THREE.Mesh(new THREE.BoxGeometry(0.1, 0.08, 0.22), iron);
    hammer.position.set(s * 0.62, 1.62, 0.55);
    root.add(hammer);
  }

  const tail = new THREE.Group();
  tail.position.set(0, 1.05, -0.7);
  root.add(tail);
  for (let i = 0; i < 7; i++) {
    const k = new THREE.Mesh(new THREE.BoxGeometry(0.16, 0.05, 0.22), i % 2 ? bone : iron);
    k.position.set((i % 2 ? 0.08 : -0.08), -i * 0.08, -i * 0.16);
    k.rotation.x = 0.4;
    tail.add(k);
  }

  root.userData = {
    keys,
    jaw,
    lid: jaw.getObjectByName("lid"),
    eyeLight,
    eyeL: jaw.getObjectByName("eyeL"),
    eyeR: jaw.getObjectByName("eyeR"),
    bob: 0,
    stepAcc: 0,
    freezeT: 0,
    scare: false,
    scareT: 0,
    chatter: 0,
    lastSnap: new THREE.Vector3(0, 0, 22),
  };
  root.position.set(0, 0, 24);
  return root;
}

export function inFlashCone(camera, point, range = 18, cosAng = 0.82) {
  const origin = new THREE.Vector3();
  const dir = new THREE.Vector3();
  camera.getWorldPosition(origin);
  camera.getWorldDirection(dir);
  const to = point.clone().sub(origin);
  const dist = to.length();
  if (dist > range || dist < 0.01) return { hit: false, dist };
  to.multiplyScalar(1 / dist);
  return { hit: dir.dot(to) > cosAng, dist };
}

/**
 * Stop-motion stalker. Returns { dist, jumpscare } when it should lunge.
 */
export function updateIvorymaw(mesh, dt, camera, playerPos, flashlightOn) {
  const u = mesh.userData;
  u.bob += dt;
  u.chatter += dt;

  const target = new THREE.Vector3(playerPos.x, 0, playerPos.z);
  const toPlayer = target.clone().sub(mesh.position);
  toPlayer.y = 0;
  const dist = toPlayer.length();
  const cone = flashlightOn ? inFlashCone(camera, mesh.position.clone().setY(1.8)) : { hit: false, dist };

  for (let i = 0; i < u.keys.length; i++) {
    const k = u.keys[i];
    const n = Math.sin(u.chatter * (8 + i * 0.35) + i) * (cone.hit ? 0.18 : 0.05);
    k.rotation.x = 0.12 + n + (cone.hit && dist < 10 ? 0.25 : 0);
  }
  if (u.jaw) u.jaw.rotation.x = cone.hit ? Math.sin(u.bob * 14) * 0.08 : Math.sin(u.bob * 3) * 0.03;
  if (u.lid) u.lid.rotation.x = cone.hit ? -0.25 - Math.abs(Math.sin(u.bob * 9)) * 0.15 : -0.08;

  const glow = cone.hit ? 1.8 : 0.12;
  if (u.eyeLight) u.eyeLight.intensity = glow + Math.random() * (cone.hit ? 0.8 : 0.05);
  if (u.eyeL?.material) u.eyeL.material.emissiveIntensity = cone.hit ? 2.6 : 0.2;
  if (u.eyeR?.material) u.eyeR.material.emissiveIntensity = cone.hit ? 2.6 : 0.2;

  if (u.scare) {
    u.scareT += dt;
    const p = Math.min(1, u.scareT / 0.28);
    const camPos = new THREE.Vector3();
    camera.getWorldPosition(camPos);
    const dir = new THREE.Vector3();
    camera.getWorldDirection(dir);
    const end = camPos.clone().addScaledVector(dir, 0.72);
    end.y = 0;
    mesh.position.lerp(end, 0.45 + p * 0.5);
    mesh.lookAt(camPos.x, 0, camPos.z);
    mesh.position.y = 0.05;
    if (u.jaw) u.jaw.rotation.x = 0.85 * p;
    if (u.lid) u.lid.rotation.x = -1.1 * p;
    mesh.scale.setScalar(1 + p * 0.55);
    return { dist: 0.2, jumpscare: true, scareT: u.scareT };
  }

  const tooClose = dist < 3.4;
  const staredDown = cone.hit && dist < 7.5 && (u.freezeT += dt) > 1.35;
  const ambush = !flashlightOn && dist < 4.2;
  if (tooClose || staredDown || ambush) {
    u.scare = true;
    u.scareT = 0;
    return { dist, jumpscare: true, scareT: 0 };
  }
  if (!cone.hit) u.freezeT = Math.max(0, u.freezeT - dt * 0.6);

  if (cone.hit && dist < 12) {
    mesh.lookAt(target.x, 0, target.z);
    mesh.position.y = Math.sin(u.bob * 18) * 0.03;
    return { dist, jumpscare: false, inBeam: true };
  }

  u.stepAcc += dt;
  const interval = 0.11 + Math.min(0.18, dist * 0.008);
  if (u.stepAcc >= interval) {
    u.stepAcc = 0;
    if (dist > 0.4) {
      toPlayer.normalize();
      const snap = 0.55 + Math.random() * 0.35;
      mesh.position.addScaledVector(toPlayer, snap);
      mesh.lookAt(target.x, 0, target.z);
      mesh.position.x += (Math.random() - 0.5) * 0.12;
    }
  }
  mesh.position.y = 0;
  return { dist, jumpscare: false, inBeam: false };
}

function mat(color, emissive = 0x000000, intensity = 0, roughness = 0.8, metalness = 0.05) {
  return new THREE.MeshStandardMaterial({
    color,
    emissive,
    emissiveIntensity: intensity,
    roughness,
    metalness,
  });
}
