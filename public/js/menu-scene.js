import * as THREE from "three";
import { createHushhorn } from "./creature.js";

/** Cinematic menu backdrop: factory vignette + Hushhorn + ClampRig gauntlet on the floor. */
export function createMenuScene(renderer) {
  const scene = new THREE.Scene();
  scene.fog = new THREE.FogExp2(0x140308, 0.055);
  scene.background = new THREE.Color(0x070103);

  const camera = new THREE.PerspectiveCamera(38, innerWidth / innerHeight, 0.1, 80);
  camera.position.set(-2.4, 1.45, 6.2);
  camera.lookAt(1.6, 1.5, 0.2);

  const hemi = new THREE.HemisphereLight(0xff6a55, 0x080103, 0.35);
  scene.add(hemi);

  const key = new THREE.SpotLight(0xff2244, 80, 28, 0.7, 0.55, 1.2);
  key.position.set(6, 5.5, 4);
  key.target.position.set(1.2, 1.2, -1);
  key.castShadow = true;
  key.shadow.mapSize.set(2048, 2048);
  key.shadow.bias = -0.0004;
  scene.add(key, key.target);

  const rim = new THREE.DirectionalLight(0xff8899, 1.1);
  rim.position.set(-4, 3, -6);
  scene.add(rim);

  const fill = new THREE.PointLight(0x331018, 4, 16);
  fill.position.set(-3, 1.4, 4);
  scene.add(fill);

  const floor = new THREE.Mesh(
    new THREE.PlaneGeometry(40, 40),
    new THREE.MeshStandardMaterial({ color: 0x121014, metalness: 0.72, roughness: 0.28 })
  );
  floor.rotation.x = -Math.PI / 2;
  floor.receiveShadow = true;
  scene.add(floor);

  const grate = new THREE.Mesh(
    new THREE.PlaneGeometry(12, 12),
    new THREE.MeshStandardMaterial({ color: 0x2a2428, metalness: 0.8, roughness: 0.35 })
  );
  grate.rotation.x = -Math.PI / 2;
  grate.position.y = 0.01;
  grate.receiveShadow = true;
  scene.add(grate);

  for (let i = 0; i < 6; i++) {
    const col = new THREE.Mesh(
      new THREE.BoxGeometry(0.7, 8, 0.7),
      new THREE.MeshStandardMaterial({ color: 0x2a1818, roughness: 0.7, metalness: 0.25 })
    );
    col.position.set(-2 + i * 1.8, 4, -4.5);
    col.castShadow = true;
    scene.add(col);
  }

  const hush = createHushhorn();
  hush.position.set(2.1, 0, -1.4);
  hush.rotation.y = -0.55;
  hush.scale.setScalar(1.35);
  scene.add(hush);

  scene.add(makeGauntlet());

  const haze = new THREE.Mesh(
    new THREE.PlaneGeometry(18, 10),
    new THREE.MeshBasicMaterial({
      color: 0xff2244,
      transparent: true,
      opacity: 0.08,
      depthWrite: false,
    })
  );
  haze.position.set(3, 2.2, -3);
  scene.add(haze);

  let t = 0;
  function tick(dt) {
    t += dt;
    hush.position.y = Math.sin(t * 0.8) * 0.05;
    hush.rotation.y = -0.55 + Math.sin(t * 0.25) * 0.04;
    camera.position.x = -2.4 + Math.sin(t * 0.12) * 0.12;
    camera.position.y = 1.45 + Math.sin(t * 0.18) * 0.04;
    camera.lookAt(1.6, 1.55 + Math.sin(t * 0.2) * 0.05, 0.2);
  }

  function resize() {
    camera.aspect = innerWidth / innerHeight;
    camera.updateProjectionMatrix();
  }

  return { scene, camera, tick, resize };
}

function makeGauntlet() {
  const g = new THREE.Group();
  const body = new THREE.Mesh(
    new THREE.BoxGeometry(0.38, 0.16, 0.55),
    new THREE.MeshStandardMaterial({ color: 0xf0c400, metalness: 0.45, roughness: 0.35 })
  );
  g.add(body);
  const stripe = new THREE.Mesh(
    new THREE.BoxGeometry(0.4, 0.05, 0.18),
    new THREE.MeshStandardMaterial({ color: 0x111111, metalness: 0.6, roughness: 0.4 })
  );
  stripe.position.y = 0.08;
  g.add(stripe);
  for (const x of [-0.1, 0.1]) {
    const claw = new THREE.Mesh(
      new THREE.ConeGeometry(0.045, 0.22, 8),
      new THREE.MeshStandardMaterial({ color: 0xffcc33, metalness: 0.7, roughness: 0.25 })
    );
    claw.position.set(x, 0.02, -0.38);
    claw.rotation.x = Math.PI / 2.2;
    g.add(claw);
  }
  const glow = new THREE.PointLight(0xffcc33, 1.2, 3);
  glow.position.set(0, 0.2, 0);
  g.add(glow);
  g.position.set(1.35, 0.12, 3.4);
  g.rotation.set(0.15, 0.8, -0.4);
  g.castShadow = true;
  return g;
}
