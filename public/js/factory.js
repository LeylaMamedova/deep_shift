import * as THREE from "three";

const HALL_W = 4.2;
const HALL_LEN = 52;

export function buildFactory(scene) {
  const colliders = [];
  const grabables = [];
  const hits = [];
  const sockets = [];

  const rust = std(0x3a2a24, 0.82, 0.35);
  const metal = std(0x1c1c20, 0.38, 0.72);
  const paint = std(0x241016, 0.7, 0.18);
  const warn = std(0xc9a227, 0.45, 0.35);
  const black = std(0x0a0a0c, 0.55, 0.4);
  const wet = new THREE.MeshStandardMaterial({
    color: 0x16141a,
    roughness: 0.22,
    metalness: 0.78,
    envMapIntensity: 1.1,
  });

  // floor + ceiling
  const floor = new THREE.Mesh(new THREE.PlaneGeometry(28, HALL_LEN + 16), wet);
  floor.rotation.x = -Math.PI / 2;
  floor.position.set(0, 0, HALL_LEN * 0.4);
  floor.receiveShadow = true;
  floor.userData.world = true;
  scene.add(floor);
  hits.push(floor);

  const ceil = new THREE.Mesh(new THREE.PlaneGeometry(28, HALL_LEN + 16), metal);
  ceil.rotation.x = Math.PI / 2;
  ceil.position.set(0, 4.6, HALL_LEN * 0.4);
  ceil.userData.world = true;
  scene.add(ceil);
  hits.push(ceil);

  addHall(scene, hits, colliders, rust, metal, paint, warn, black);

  // red volumetric shafts
  for (let i = 0; i < 7; i++) {
    const z = 6 + i * 7;
    const shaft = new THREE.Mesh(
      new THREE.ConeGeometry(1.8, 4.4, 16, 1, true),
      new THREE.MeshBasicMaterial({
        color: 0xff2244,
        transparent: true,
        opacity: 0.02,
        depthWrite: false,
        side: THREE.DoubleSide,
      })
    );
    shaft.position.set((i % 2 === 0 ? -0.6 : 0.6), 2.2, z);
    shaft.rotation.x = Math.PI;
    scene.add(shaft);

    const lamp = new THREE.Mesh(
      new THREE.BoxGeometry(0.5, 0.12, 0.9),
      new THREE.MeshStandardMaterial({
        color: 0x220000,
        emissive: 0xff2244,
        emissiveIntensity: 0.55,
        roughness: 0.4,
      })
    );
    lamp.position.set(0, 4.35, z);
    scene.add(lamp);

    const spot = new THREE.SpotLight(0xff3355, 2.1, 14, 0.5, 0.55, 1.6);
    spot.position.set(0, 4.2, z);
    spot.target.position.set(0, 0, z + 0.2);
    spot.castShadow = i === 0;
    spot.shadow.mapSize.set(1024, 1024);
    spot.shadow.bias = -0.0008;
    scene.add(spot, spot.target);
  }

  // pipes
  const pipeMat = std(0x4a4038, 0.45, 0.65);
  for (let i = 0; i < 10; i++) {
    const pipe = new THREE.Mesh(new THREE.CylinderGeometry(0.12, 0.12, 8, 10), pipeMat);
    pipe.rotation.z = Math.PI / 2;
    pipe.position.set(0, 3.9, 4 + i * 5);
    pipe.castShadow = true;
    pipe.userData.world = true;
    scene.add(pipe);
    hits.push(pipe);
  }

  // crates
  const crateSpots = [
    [-1.6, 8],
    [1.7, 14],
    [-1.4, 22],
    [6.5, 18],
    [-6.2, 18],
  ];
  for (const [x, z] of crateSpots) {
    const crate = makeCrate();
    crate.position.set(x, 0.4, z);
    scene.add(crate);
    grabables.push(crate);
    hits.push(crate);
    colliders.push({ type: "circle", x, z, r: 0.45, dynamic: crate });
  }

  const gate = makeDualGate(warn, metal);
  gate.group.position.set(0, 0, 40);
  scene.add(gate.group);
  hits.push(...gate.hits);
  sockets.push(...gate.sockets);
  colliders.push({ type: "aabb", minX: -2.2, maxX: 2.2, minZ: 39.6, maxZ: 40.5, gate: true });

  // side alcoves
  addAlcove(scene, hits, colliders, rust, 8.2, 18);
  addAlcove(scene, hits, colliders, rust, -8.2, 18);

  // steam / dust
  const dust = makeDust();
  scene.add(dust);

  const key = makeKeycard();
  key.position.set(6.4, 0.9, 18.2);
  scene.add(key);
  grabables.push(key);
  hits.push(key);

  return {
    colliders,
    grabables,
    hits,
    sockets,
    gate,
    dust,
    spawn: new THREE.Vector3(0, 0, 2.5),
    exitZ: 46,
    mapSize: HALL_LEN,
  };
}

export function resolveCollisions(pos, colliders, radius = 0.38) {
  for (const c of colliders) {
    if (c.disabled) continue;
    if (c.dynamic) {
      c.x = c.dynamic.position.x;
      c.z = c.dynamic.position.z;
    }
    if (c.type === "circle") {
      const dx = pos.x - c.x;
      const dz = pos.z - c.z;
      const dist = Math.hypot(dx, dz);
      const min = radius + c.r;
      if (dist < min && dist > 1e-4) {
        const push = (min - dist) / dist;
        pos.x += dx * push;
        pos.z += dz * push;
      }
    } else if (c.type === "aabb") {
      const nx = Math.max(c.minX, Math.min(pos.x, c.maxX));
      const nz = Math.max(c.minZ, Math.min(pos.z, c.maxZ));
      const dx = pos.x - nx;
      const dz = pos.z - nz;
      const d2 = dx * dx + dz * dz;
      if (d2 < radius * radius) {
        if (d2 < 1e-8) {
          const left = pos.x - c.minX;
          const right = c.maxX - pos.x;
          const back = pos.z - c.minZ;
          const fwd = c.maxZ - pos.z;
          const m = Math.min(left, right, back, fwd);
          if (m === left) pos.x = c.minX - radius;
          else if (m === right) pos.x = c.maxX + radius;
          else if (m === back) pos.z = c.minZ - radius;
          else pos.z = c.maxZ + radius;
        } else {
          const d = Math.sqrt(d2);
          pos.x = nx + (dx / d) * radius;
          pos.z = nz + (dz / d) * radius;
        }
      }
    }
  }
  pos.x = THREE.MathUtils.clamp(pos.x, -11, 11);
  pos.z = THREE.MathUtils.clamp(pos.z, -1, HALL_LEN);
}

function addHall(scene, hits, colliders, rust, metal, paint, warn, black) {
  const wallH = 4.6;
  const segs = 8;
  const segLen = HALL_LEN / segs;
  for (let i = 0; i < segs; i++) {
    const z = i * segLen + segLen * 0.5;
    const alcoveGap = z > 14 && z < 22;
    for (const x of [-HALL_W, HALL_W]) {
      if (alcoveGap) continue;
      const wall = new THREE.Mesh(new THREE.BoxGeometry(0.35, wallH, segLen), i % 2 ? paint : rust);
      wall.position.set(x, wallH * 0.5, z);
      wall.castShadow = true;
      wall.receiveShadow = true;
      wall.userData.world = true;
      scene.add(wall);
      hits.push(wall);
    }
    const stripe = new THREE.Mesh(new THREE.BoxGeometry(HALL_W * 2, 0.04, 0.28), i % 2 ? warn : black);
    stripe.position.set(0, 0.03, z);
    scene.add(stripe);
  }
  colliders.push({ type: "aabb", minX: -20, maxX: -HALL_W + 0.2, minZ: -2, maxZ: 14 });
  colliders.push({ type: "aabb", minX: -20, maxX: -HALL_W + 0.2, minZ: 22, maxZ: HALL_LEN });
  colliders.push({ type: "aabb", minX: HALL_W - 0.2, maxX: 20, minZ: -2, maxZ: 14 });
  colliders.push({ type: "aabb", minX: HALL_W - 0.2, maxX: 20, minZ: 22, maxZ: HALL_LEN });
  colliders.push({ type: "aabb", minX: -20, maxX: 20, minZ: -2.2, maxZ: -1.4 });

  const back = new THREE.Mesh(new THREE.BoxGeometry(HALL_W * 2.2, wallH, 0.4), rust);
  back.position.set(0, wallH * 0.5, -1.2);
  back.userData.world = true;
  scene.add(back);
  hits.push(back);
}

function addAlcove(scene, hits, colliders, rust, x, z) {
  const back = new THREE.Mesh(new THREE.BoxGeometry(0.3, 4.6, 8), rust);
  back.position.set(x + Math.sign(x) * 3.6, 2.3, z);
  back.userData.world = true;
  scene.add(back);
  hits.push(back);
  for (const dz of [-4, 4]) {
    const side = new THREE.Mesh(new THREE.BoxGeometry(7.2, 4.6, 0.3), rust);
    side.position.set(x, 2.3, z + dz);
    side.userData.world = true;
    scene.add(side);
    hits.push(side);
  }
}

function makeCrate() {
  const g = new THREE.Group();
  const box = new THREE.Mesh(
    new THREE.BoxGeometry(0.8, 0.8, 0.8),
    new THREE.MeshStandardMaterial({ color: 0x6a4a28, roughness: 0.78, metalness: 0.08 })
  );
  box.castShadow = true;
  box.receiveShadow = true;
  g.add(box);
  const band = new THREE.Mesh(
    new THREE.BoxGeometry(0.82, 0.08, 0.82),
    new THREE.MeshStandardMaterial({ color: 0x222018, metalness: 0.6, roughness: 0.4 })
  );
  band.position.y = 0.1;
  g.add(band);
  g.userData.grabable = true;
  g.userData.kind = "crate";
  return g;
}

function makeKeycard() {
  const g = new THREE.Group();
  const card = new THREE.Mesh(
    new THREE.BoxGeometry(0.22, 0.02, 0.14),
    new THREE.MeshStandardMaterial({
      color: 0x88ffcc,
      emissive: 0x44ffaa,
      emissiveIntensity: 0.8,
      metalness: 0.3,
      roughness: 0.3,
    })
  );
  g.add(card);
  const light = new THREE.PointLight(0x66ffcc, 0.8, 3);
  g.add(light);
  g.userData.grabable = true;
  g.userData.kind = "key";
  return g;
}

function makeDualGate(warn, metal) {
  const group = new THREE.Group();
  const doorL = new THREE.Mesh(new THREE.BoxGeometry(2.05, 3.6, 0.18), metal);
  const doorR = new THREE.Mesh(new THREE.BoxGeometry(2.05, 3.6, 0.18), metal);
  doorL.position.set(-1.05, 1.8, 0);
  doorR.position.set(1.05, 1.8, 0);
  doorL.userData.world = true;
  doorR.userData.world = true;
  group.add(doorL, doorR);

  const frame = new THREE.Mesh(new THREE.BoxGeometry(4.6, 4.2, 0.35), warn);
  frame.position.y = 2.1;
  frame.userData.world = true;
  group.add(frame);
  const hole = new THREE.Mesh(new THREE.BoxGeometry(4.1, 3.7, 0.4), new THREE.MeshBasicMaterial({ color: 0x000000 }));
  hole.position.y = 1.85;
  group.add(hole);
  // hide hole by rendering doors in front — actually subtract isn't possible; skip hole mesh
  group.remove(hole);

  const sockets = [];
  const hits = [doorL, doorR, frame];
  for (const [x, id] of [[-1.55, "L"], [1.55, "R"]]) {
    const sock = new THREE.Mesh(
      new THREE.CylinderGeometry(0.16, 0.16, 0.12, 14),
      new THREE.MeshStandardMaterial({
        color: 0x111111,
        emissive: id === "L" ? 0x2266ff : 0xff2222,
        emissiveIntensity: 0.7,
        metalness: 0.8,
        roughness: 0.25,
      })
    );
    sock.rotation.x = Math.PI / 2;
    sock.position.set(x, 1.6, 0.22);
    sock.userData.socket = true;
    sock.userData.charged = false;
    sock.userData.id = id;
    group.add(sock);
    hits.push(sock);
    sockets.push(sock.userData);
    sock.userData.mesh = sock;
  }

  return {
    group,
    doorL,
    doorR,
    hits,
    sockets,
    open: false,
    collider: null,
    update(dt) {
      const ready = sockets.every((s) => s.charged);
      for (const s of sockets) {
        if (s.mesh?.material) s.mesh.material.emissiveIntensity = s.charged ? 2.4 : 0.5;
      }
      if (ready && !this.open) this.open = true;
      if (this.open) {
        doorL.position.x = THREE.MathUtils.lerp(doorL.position.x, -3.1, 1 - Math.exp(-2.5 * dt));
        doorR.position.x = THREE.MathUtils.lerp(doorR.position.x, 3.1, 1 - Math.exp(-2.5 * dt));
      }
    },
  };
}

function makeDust() {
  const count = 420;
  const geo = new THREE.BufferGeometry();
  const pos = new Float32Array(count * 3);
  for (let i = 0; i < count; i++) {
    pos[i * 3] = (Math.random() - 0.5) * 10;
    pos[i * 3 + 1] = Math.random() * 4.2;
    pos[i * 3 + 2] = Math.random() * HALL_LEN;
  }
  geo.setAttribute("position", new THREE.BufferAttribute(pos, 3));
  const mat = new THREE.PointsMaterial({
    color: 0xff8899,
    size: 0.035,
    transparent: true,
    opacity: 0.35,
    depthWrite: false,
  });
  const pts = new THREE.Points(geo, mat);
  pts.frustumCulled = false;
  return pts;
}

function std(color, roughness, metalness) {
  return new THREE.MeshStandardMaterial({ color, roughness, metalness });
}
