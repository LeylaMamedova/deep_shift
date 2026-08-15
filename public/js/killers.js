import * as THREE from "three";

/** Your roster — fan-styled animatronics for this project. */
export const KILLERS = {
  phantomPuppet: {
    id: "phantomPuppet",
    name: "Phantom Puppet",
    color: 0x5c2a6e,
    accent: 0xf2e6ff,
    speed: 6.2,
    abilityName: "Music Box",
    abilityCooldown: 9,
    abilityDuration: 4,
    description: "Slow nearby survivors, then blink toward the closest one.",
  },
  ennard: {
    id: "ennard",
    name: "Ennard",
    color: 0xb8bdc4,
    accent: 0x8b1e2d,
    speed: 6.6,
    abilityName: "Wire Lunge",
    abilityCooldown: 7,
    abilityDuration: 0.55,
    description: "Dash forward through fog and brush.",
  },
  witheredBonnie: {
    id: "witheredBonnie",
    name: "Withered Bonnie",
    color: 0x2a3d6e,
    accent: 0xc9a227,
    speed: 5.6,
    abilityName: "Jaw Slam",
    abilityCooldown: 8,
    abilityDuration: 2.2,
    description: "Heavy hit plus a roar that marks moving survivors.",
  },
};

export function createKillerMesh(killerId) {
  const def = KILLERS[killerId] || KILLERS.phantomPuppet;
  const root = new THREE.Group();
  root.name = def.name;

  if (killerId === "phantomPuppet") buildPhantomPuppet(root, def);
  else if (killerId === "ennard") buildEnnard(root, def);
  else buildWitheredBonnie(root, def);

  root.userData.killerId = def.id;
  return root;
}

function mat(color, emissive = 0x000000, intensity = 0.2) {
  return new THREE.MeshStandardMaterial({
    color,
    emissive,
    emissiveIntensity: intensity,
    roughness: 0.72,
    metalness: 0.18,
  });
}

function buildPhantomPuppet(root, def) {
  const body = new THREE.Mesh(new THREE.CylinderGeometry(0.28, 0.38, 1.35, 10), mat(def.color, def.accent, 0.35));
  body.position.y = 1.05;
  root.add(body);

  const head = new THREE.Mesh(new THREE.SphereGeometry(0.34, 14, 12), mat(0xefe6f5, def.accent, 0.45));
  head.position.y = 1.95;
  root.add(head);

  const mask = new THREE.Mesh(new THREE.BoxGeometry(0.42, 0.28, 0.12), mat(0x1a0a22, def.accent, 0.6));
  mask.position.set(0, 1.98, 0.28);
  root.add(mask);

  for (const x of [-0.42, 0.42]) {
    const arm = new THREE.Mesh(new THREE.CylinderGeometry(0.07, 0.07, 1.05, 6), mat(def.color));
    arm.position.set(x, 1.25, 0);
    arm.rotation.z = x > 0 ? -0.35 : 0.35;
    root.add(arm);
  }

  // hanging strings
  for (const x of [-0.2, 0.2]) {
    const string = new THREE.Mesh(new THREE.CylinderGeometry(0.015, 0.015, 1.4, 4), mat(0xd8c8e8, def.accent, 0.25));
    string.position.set(x, 2.7, 0);
    root.add(string);
  }
  const bar = new THREE.Mesh(new THREE.BoxGeometry(0.7, 0.05, 0.05), mat(0x3a2040));
  bar.position.y = 3.4;
  root.add(bar);

  addEyes(root, 1.98, 0.32, 0xff66dd);
}

function buildEnnard(root, def) {
  const torso = new THREE.Mesh(new THREE.SphereGeometry(0.55, 12, 10), mat(def.color, def.accent, 0.25));
  torso.position.y = 1.15;
  torso.scale.set(1, 1.2, 0.9);
  root.add(torso);

  // wire spaghetti
  for (let i = 0; i < 14; i++) {
    const wire = new THREE.Mesh(
      new THREE.CylinderGeometry(0.025, 0.02, 0.7 + Math.random() * 0.6, 4),
      mat(i % 2 ? 0x8b1e2d : 0xd0d4d8, def.accent, 0.15)
    );
    const a = (i / 14) * Math.PI * 2;
    wire.position.set(Math.cos(a) * 0.45, 1.1 + (i % 3) * 0.15, Math.sin(a) * 0.35);
    wire.rotation.set(Math.random(), a, Math.random() * 0.8);
    root.add(wire);
  }

  const mask = new THREE.Mesh(new THREE.SphereGeometry(0.32, 12, 10), mat(0xe8e8e8, def.accent, 0.4));
  mask.position.set(0, 1.85, 0.25);
  root.add(mask);

  const jaw = new THREE.Mesh(new THREE.BoxGeometry(0.28, 0.1, 0.18), mat(0x222226));
  jaw.position.set(0, 1.68, 0.38);
  root.add(jaw);

  addEyes(root, 1.9, 0.48, 0xff2222);
}

function buildWitheredBonnie(root, def) {
  const body = new THREE.Mesh(new THREE.CylinderGeometry(0.32, 0.42, 1.2, 10), mat(def.color, 0x111822, 0.2));
  body.position.y = 1.0;
  root.add(body);

  const head = new THREE.Mesh(new THREE.SphereGeometry(0.36, 12, 10), mat(0x334a7a, def.accent, 0.2));
  head.position.y = 1.85;
  root.add(head);

  // broken jaw hanging
  const jaw = new THREE.Mesh(new THREE.BoxGeometry(0.3, 0.12, 0.22), mat(0x1a2233));
  jaw.position.set(0, 1.55, 0.28);
  jaw.rotation.x = 0.55;
  root.add(jaw);

  // one ear intact, one snapped
  const earL = new THREE.Mesh(new THREE.CylinderGeometry(0.07, 0.09, 0.55, 6), mat(def.color));
  earL.position.set(-0.18, 2.35, 0);
  root.add(earL);
  const earR = new THREE.Mesh(new THREE.BoxGeometry(0.12, 0.18, 0.08), mat(0x222833));
  earR.position.set(0.22, 2.15, 0);
  earR.rotation.z = 0.7;
  root.add(earR);

  // exposed endo arm
  const arm = new THREE.Mesh(new THREE.CylinderGeometry(0.05, 0.05, 0.95, 5), mat(0xb8bdc4, 0x444444, 0.1));
  arm.position.set(0.55, 1.15, 0);
  arm.rotation.z = -0.5;
  root.add(arm);

  addEyes(root, 1.88, 0.3, 0xffcc33);
}

function addEyes(root, y, z, color) {
  for (const x of [-0.1, 0.1]) {
    const eye = new THREE.Mesh(
      new THREE.SphereGeometry(0.06, 8, 8),
      new THREE.MeshStandardMaterial({ color, emissive: color, emissiveIntensity: 1.2 })
    );
    eye.position.set(x, y, z);
    root.add(eye);
  }
}

/**
 * Activate killer ability. Mutates game state helpers passed in.
 */
export function useKillerAbility(ctx) {
  const { killerId, player, survivors, now, cooldowns, effects } = ctx;
  const def = KILLERS[killerId];
  if (!def) return false;
  if ((cooldowns[killerId] || 0) > now) return false;

  cooldowns[killerId] = now + def.abilityCooldown;

  if (killerId === "phantomPuppet") {
    effects.musicBoxUntil = now + def.abilityDuration;
    // blink toward nearest survivor-like target (beacon cluster / player if killer is AI later)
    const target = survivors[0];
    if (target) {
      const dir = new THREE.Vector3().subVectors(target.position, player.position);
      dir.y = 0;
      if (dir.lengthSq() > 0.01) {
        dir.normalize();
        player.position.addScaledVector(dir, Math.min(8, dir.length() || 8));
      }
    } else {
      const forward = new THREE.Vector3(0, 0, -1).applyQuaternion(player.quaternion);
      player.position.addScaledVector(forward, 6);
    }
    return { toast: "Music Box — blink" };
  }

  if (killerId === "ennard") {
    effects.lungeUntil = now + def.abilityDuration;
    effects.lungeDir = new THREE.Vector3(0, 0, -1).applyQuaternion(player.quaternion);
    return { toast: "Wire Lunge" };
  }

  if (killerId === "witheredBonnie") {
    effects.jawSlamUntil = now + 0.35;
    effects.roarUntil = now + def.abilityDuration;
    return { toast: "Jaw Slam" };
  }

  return false;
}
