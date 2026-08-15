import * as THREE from "three";

export function createFlashlight(camera) {
  const light = new THREE.SpotLight(0xfff1d0, 0, 24, 0.38, 0.28, 1.15);
  light.castShadow = true;
  light.shadow.mapSize.set(1024, 1024);
  light.shadow.bias = -0.0009;
  light.shadow.camera.near = 0.2;
  light.shadow.camera.far = 26;
  light.position.set(0.12, -0.08, 0.1);
  camera.add(light);

  const target = new THREE.Object3D();
  target.position.set(0, 0, -8);
  camera.add(target);
  light.target = target;

  const fill = new THREE.PointLight(0xffe8c4, 0, 3.2);
  fill.position.set(0.1, -0.12, 0.2);
  camera.add(fill);

  const body = new THREE.Mesh(
    new THREE.CylinderGeometry(0.025, 0.032, 0.16, 8),
    new THREE.MeshStandardMaterial({ color: 0x222226, metalness: 0.7, roughness: 0.35 })
  );
  body.rotation.x = Math.PI / 2;
  body.position.set(0.18, -0.16, -0.28);
  camera.add(body);

  const lens = new THREE.Mesh(
    new THREE.CircleGeometry(0.03, 12),
    new THREE.MeshStandardMaterial({
      color: 0xfff4cc,
      emissive: 0xffe8a0,
      emissiveIntensity: 0,
    })
  );
  lens.position.set(0.18, -0.16, -0.37);
  camera.add(lens);

  let on = true;
  let flick = 0;

  function setOn(v) {
    on = v;
    apply(1);
  }

  function toggle() {
    setOn(!on);
    return on;
  }

  function apply(mul) {
    const live = on ? 1 : 0;
    light.intensity = 42 * live * mul;
    fill.intensity = 1.1 * live * mul;
    if (lens.material) lens.material.emissiveIntensity = 2.2 * live * mul;
  }

  function update(dt, panic = false) {
    if (!on) {
      apply(0);
      return on;
    }
    flick += dt;
    let mul = 1;
    if (panic) {
      mul = 0.35 + Math.random() * 0.7;
      if (Math.random() < 0.08) mul = 0.05;
    } else if (Math.random() < 0.004) {
      mul = 0.45;
    }
    apply(mul);
    return on;
  }

  return { light, toggle, setOn, update, isOn: () => on };
}
