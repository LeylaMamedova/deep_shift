import * as THREE from "three";

const MAP = {
  size: 86,
  treeCount: 220,
  beaconCount: 4,
};

/**
 * Build the haunted forest location: fog floor, pines, path, cabin, beacons.
 */
export function buildHauntedForest(scene) {
  const colliders = [];
  const beacons = [];
  const interactives = [];

  // ground
  const ground = new THREE.Mesh(
    new THREE.PlaneGeometry(MAP.size * 1.4, MAP.size * 1.4, 32, 32),
    new THREE.MeshStandardMaterial({ color: 0x1a2418, roughness: 0.95 })
  );
  ground.rotation.x = -Math.PI / 2;
  ground.receiveShadow = true;
  scene.add(ground);

  // mist patches
  const mistMat = new THREE.MeshStandardMaterial({
    color: 0x6a8070,
    transparent: true,
    opacity: 0.12,
    roughness: 1,
  });
  for (let i = 0; i < 18; i++) {
    const mist = new THREE.Mesh(new THREE.CircleGeometry(4 + Math.random() * 6, 16), mistMat);
    mist.rotation.x = -Math.PI / 2;
    mist.position.set((Math.random() - 0.5) * MAP.size, 0.05, (Math.random() - 0.5) * MAP.size);
    scene.add(mist);
  }

  // winding dirt path
  const pathMat = new THREE.MeshStandardMaterial({ color: 0x3a3224, roughness: 1 });
  for (let i = 0; i < 28; i++) {
    const t = i / 27;
    const x = Math.sin(t * Math.PI * 1.6) * 10;
    const z = -MAP.size * 0.4 + t * MAP.size * 0.85;
    const slab = new THREE.Mesh(new THREE.PlaneGeometry(3.2, 3.6), pathMat);
    slab.rotation.x = -Math.PI / 2;
    slab.position.set(x, 0.03, z);
    scene.add(slab);
  }

  // trees
  const trunkMat = new THREE.MeshStandardMaterial({ color: 0x2a1c12, roughness: 0.9 });
  const leafMat = new THREE.MeshStandardMaterial({ color: 0x163222, roughness: 0.85 });
  const deadMat = new THREE.MeshStandardMaterial({ color: 0x3a4034, roughness: 1 });

  for (let i = 0; i < MAP.treeCount; i++) {
    const x = (Math.random() - 0.5) * MAP.size;
    const z = (Math.random() - 0.5) * MAP.size;
    // keep spawn clearing + path somewhat open
    if (Math.hypot(x, z) < 8) continue;
    if (Math.abs(x - Math.sin(((z + MAP.size * 0.4) / (MAP.size * 0.85)) * Math.PI * 1.6) * 10) < 2.4) continue;

    const tree = new THREE.Group();
    const h = 4 + Math.random() * 5;
    const trunk = new THREE.Mesh(new THREE.CylinderGeometry(0.18, 0.28, h * 0.45, 6), trunkMat);
    trunk.position.y = h * 0.22;
    tree.add(trunk);

    if (Math.random() > 0.18) {
      const canopy = new THREE.Mesh(new THREE.ConeGeometry(1.1 + Math.random() * 0.7, h * 0.7, 7), leafMat);
      canopy.position.y = h * 0.55;
      tree.add(canopy);
    } else {
      // dead snag
      const snag = new THREE.Mesh(new THREE.CylinderGeometry(0.08, 0.12, h * 0.5, 5), deadMat);
      snag.position.set(0.3, h * 0.45, 0);
      snag.rotation.z = 0.6;
      tree.add(snag);
    }

    tree.position.set(x, 0, z);
    tree.rotation.y = Math.random() * Math.PI;
    scene.add(tree);
    colliders.push({ x, z, r: 0.55 });
  }

  // broken fence ring near center
  const postMat = new THREE.MeshStandardMaterial({ color: 0x4a3a28 });
  for (let i = 0; i < 16; i++) {
    if (i % 5 === 0) continue; // gaps
    const a = (i / 16) * Math.PI * 2;
    const post = new THREE.Mesh(new THREE.BoxGeometry(0.12, 1.1, 0.12), postMat);
    post.position.set(Math.cos(a) * 7.5, 0.55, Math.sin(a) * 7.5);
    scene.add(post);
  }

  // abandoned cabin
  const cabin = buildCabin();
  cabin.position.set(14, 0, -18);
  scene.add(cabin);
  colliders.push({ x: 14, z: -18, r: 3.2 });

  // stone circle clearing
  const stoneMat = new THREE.MeshStandardMaterial({ color: 0x5a5e58, roughness: 0.85 });
  for (let i = 0; i < 9; i++) {
    const a = (i / 9) * Math.PI * 2;
    const stone = new THREE.Mesh(new THREE.DodecahedronGeometry(0.35 + Math.random() * 0.25, 0), stoneMat);
    stone.position.set(Math.cos(a) * 4.5 - 12, 0.25, Math.sin(a) * 4.5 + 10);
    stone.rotation.set(Math.random(), Math.random(), Math.random());
    scene.add(stone);
  }

  // beacons (survivor objectives)
  const spots = [
    [0, 0],
    [18, 16],
    [-20, 12],
    [-8, -22],
  ];
  for (let i = 0; i < MAP.beaconCount; i++) {
    const [bx, bz] = spots[i];
    const beacon = buildBeacon(i);
    beacon.position.set(bx, 0, bz);
    scene.add(beacon);
    beacons.push(beacon);
    interactives.push({
      type: "beacon",
      mesh: beacon,
      id: i,
      lit: false,
      progress: 0,
      range: 2.4,
    });
  }

  // soft moon light helper mesh (visual only)
  const moon = new THREE.Mesh(
    new THREE.SphereGeometry(1.2, 12, 12),
    new THREE.MeshBasicMaterial({ color: 0xddeeff })
  );
  moon.position.set(-30, 28, -20);
  scene.add(moon);

  // boundary markers (fallen logs)
  const logMat = new THREE.MeshStandardMaterial({ color: 0x2c2016 });
  for (let i = 0; i < 12; i++) {
    const a = (i / 12) * Math.PI * 2;
    const log = new THREE.Mesh(new THREE.CylinderGeometry(0.35, 0.4, 3.5, 7), logMat);
    log.rotation.z = Math.PI / 2;
    log.rotation.y = a;
    log.position.set(Math.cos(a) * (MAP.size * 0.48), 0.3, Math.sin(a) * (MAP.size * 0.48));
    scene.add(log);
  }

  return { colliders, beacons, interactives, mapSize: MAP.size };
}

function buildCabin() {
  const g = new THREE.Group();
  const wood = new THREE.MeshStandardMaterial({ color: 0x3a2818, roughness: 0.92 });
  const dark = new THREE.MeshStandardMaterial({ color: 0x1a120c, roughness: 0.95 });
  const roof = new THREE.MeshStandardMaterial({ color: 0x2a2018, roughness: 0.9 });

  const base = new THREE.Mesh(new THREE.BoxGeometry(6, 3, 5), wood);
  base.position.y = 1.5;
  g.add(base);

  const roofMesh = new THREE.Mesh(new THREE.ConeGeometry(4.6, 2.2, 4), roof);
  roofMesh.position.y = 4.1;
  roofMesh.rotation.y = Math.PI / 4;
  g.add(roofMesh);

  const door = new THREE.Mesh(new THREE.BoxGeometry(1.1, 1.8, 0.15), dark);
  door.position.set(0, 0.9, 2.55);
  g.add(door);

  const window = new THREE.Mesh(
    new THREE.PlaneGeometry(0.9, 0.7),
    new THREE.MeshStandardMaterial({ color: 0xffaa44, emissive: 0xff6622, emissiveIntensity: 0.55 })
  );
  window.position.set(-1.6, 1.7, 2.52);
  g.add(window);

  return g;
}

function buildBeacon(index) {
  const g = new THREE.Group();
  g.name = `beacon-${index}`;

  const pole = new THREE.Mesh(
    new THREE.CylinderGeometry(0.12, 0.16, 2.2, 8),
    new THREE.MeshStandardMaterial({ color: 0x4a4030, metalness: 0.4, roughness: 0.5 })
  );
  pole.position.y = 1.1;
  g.add(pole);

  const lamp = new THREE.Mesh(
    new THREE.SphereGeometry(0.28, 12, 10),
    new THREE.MeshStandardMaterial({
      color: 0x223322,
      emissive: 0x114422,
      emissiveIntensity: 0.2,
    })
  );
  lamp.position.y = 2.35;
  lamp.name = "lamp";
  g.add(lamp);

  const light = new THREE.PointLight(0x66ff88, 0.15, 8);
  light.position.y = 2.35;
  light.name = "light";
  g.add(light);

  g.userData.lit = false;
  return g;
}

export function lightBeacon(beaconMesh) {
  if (!beaconMesh || beaconMesh.userData.lit) return;
  beaconMesh.userData.lit = true;
  const lamp = beaconMesh.getObjectByName("lamp");
  const light = beaconMesh.getObjectByName("light");
  if (lamp?.material) {
    lamp.material.emissive = new THREE.Color(0x66ff88);
    lamp.material.emissiveIntensity = 1.4;
    lamp.material.color = new THREE.Color(0xccffdd);
  }
  if (light) light.intensity = 1.6;
}

export function resolveCollisions(pos, colliders, radius = 0.45) {
  for (const c of colliders) {
    const dx = pos.x - c.x;
    const dz = pos.z - c.z;
    const dist = Math.hypot(dx, dz);
    const min = radius + c.r;
    if (dist < min && dist > 0.0001) {
      const push = (min - dist) / dist;
      pos.x += dx * push;
      pos.z += dz * push;
    }
  }
  const limit = MAP.size * 0.46;
  pos.x = THREE.MathUtils.clamp(pos.x, -limit, limit);
  pos.z = THREE.MathUtils.clamp(pos.z, -limit, limit);
}
