import * as THREE from "three";

/** Original stalker mascot — Hushhorn. Not a licensed character. */
export function createHushhorn() {
  const root = new THREE.Group();
  root.name = "Hushhorn";

  const velvet = mat(0x1a1018, 0x2a0814, 0.12, 0.92, 0.04);
  const horn = mat(0x2a2218, 0x000000, 0, 0.55, 0.15);
  const eye = new THREE.MeshStandardMaterial({
    color: 0xfff4d6,
    emissive: 0xffe8a8,
    emissiveIntensity: 2.4,
    roughness: 0.2,
    metalness: 0,
  });

  const torso = new THREE.Mesh(new THREE.SphereGeometry(0.85, 20, 16), velvet);
  torso.scale.set(1.15, 0.95, 1.45);
  torso.position.y = 1.55;
  torso.castShadow = true;
  root.add(torso);

  const head = new THREE.Mesh(new THREE.SphereGeometry(0.72, 22, 18), velvet);
  head.position.set(0, 2.55, 0.35);
  head.castShadow = true;
  root.add(head);

  for (const s of [-1, 1]) {
    const h = new THREE.Mesh(new THREE.TorusGeometry(0.38, 0.08, 8, 18, Math.PI * 1.3), horn);
    h.position.set(s * 0.42, 3.05, 0.15);
    h.rotation.set(0.4, s * 0.9, s * 1.1);
    h.castShadow = true;
    root.add(h);

    const ant = new THREE.Mesh(new THREE.CylinderGeometry(0.03, 0.02, 0.7, 6), velvet);
    ant.position.set(s * 0.22, 3.2, 0.4);
    ant.rotation.z = s * 0.35;
    ant.rotation.x = -0.4;
    root.add(ant);
    const bulb = new THREE.Mesh(new THREE.SphereGeometry(0.07, 8, 8), mat(0x3a1020, 0x661122, 0.4));
    bulb.position.set(s * 0.38, 3.52, 0.62);
    root.add(bulb);
  }

  for (const s of [-1, 1]) {
    const e = new THREE.Mesh(new THREE.SphereGeometry(0.055, 10, 8), eye);
    e.position.set(s * 0.22, 2.62, 0.98);
    root.add(e);
  }

  const cape = new THREE.Mesh(
    new THREE.ConeGeometry(1.35, 1.8, 8, 1, true),
    new THREE.MeshStandardMaterial({
      color: 0x140c12,
      roughness: 0.95,
      metalness: 0,
      side: THREE.DoubleSide,
      transparent: true,
      opacity: 0.88,
    })
  );
  cape.position.set(0, 1.7, -0.35);
  cape.rotation.x = 2.7;
  root.add(cape);

  const legGeo = new THREE.CylinderGeometry(0.12, 0.16, 1.35, 8);
  const pawGeo = new THREE.SphereGeometry(0.16, 10, 8);
  const placements = [
    [-0.45, 0.55, 0.55],
    [0.45, 0.55, 0.55],
    [-0.5, 0.55, -0.55],
    [0.5, 0.55, -0.55],
  ];
  for (const [x, y, z] of placements) {
    const leg = new THREE.Mesh(legGeo, velvet);
    leg.position.set(x, y, z);
    leg.castShadow = true;
    root.add(leg);
    const paw = new THREE.Mesh(pawGeo, velvet);
    paw.position.set(x, 0.12, z);
    paw.castShadow = true;
    root.add(paw);
  }

  const glow = new THREE.PointLight(0xff4466, 0.35, 6);
  glow.position.set(0, 2.4, 0.6);
  root.add(glow);

  root.userData.bob = 0;
  return root;
}

export function updateHushhorn(mesh, dt, target, speed = 3.35) {
  if (!mesh || !target) return;
  mesh.userData.bob = (mesh.userData.bob || 0) + dt;
  const dir = new THREE.Vector3().subVectors(target, mesh.position);
  dir.y = 0;
  const dist = dir.length();
  if (dist > 0.2) {
    dir.normalize();
    mesh.position.addScaledVector(dir, speed * dt);
    mesh.lookAt(target.x, 0, target.z);
  }
  mesh.position.y = Math.sin(mesh.userData.bob * 2.4) * 0.06;
}

function mat(color, emissive = 0x000000, intensity = 0, roughness = 0.8, metalness = 0.05) {
  const m = new THREE.MeshStandardMaterial({
    color,
    emissive,
    emissiveIntensity: intensity,
    roughness,
    metalness,
  });
  return m;
}
