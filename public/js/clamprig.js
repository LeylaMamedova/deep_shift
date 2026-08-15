import * as THREE from "three";

const RANGE = 28;
const FLY = 92;
const PULL = 22;
const RETRACT = 48;

/**
 * ClampRig 2.0 — independent left (blue) / right (red) launcher hands.
 * LMB fire / hold left, RMB fire / hold right. Release retracts.
 */
export function createClampRig(camera, scene) {
  const root = new THREE.Group();
  root.name = "ClampRig";
  camera.add(root);

  const left = makeHand("left", 0x3aa0ff, new THREE.Vector3(-0.28, -0.22, -0.42));
  const right = makeHand("right", 0xff3a3a, new THREE.Vector3(0.28, -0.22, -0.42));
  root.add(left.group, right.group);
  scene.add(left.worldHand, right.worldHand, left.cable, right.cable);

  const ray = new THREE.Raycaster();
  ray.far = RANGE;
  const ndc = new THREE.Vector2();
  const tmp = new THREE.Vector3();
  const tmp2 = new THREE.Vector3();

  const hands = { left, right };

  function fire(side, hits) {
    const h = hands[side];
    if (h.state === "flying") return;
    h.state = "flying";
    h.held = null;
    h.stuck = null;
    camera.getWorldPosition(h.origin);
    camera.getWorldDirection(h.dir);
    // slight offset so each hand is not identical
    h.dir.x += side === "left" ? -0.012 : 0.012;
    h.dir.normalize();
    h.worldHand.position.copy(h.origin);
    h.worldHand.visible = true;
    h.group.visible = false;

    ray.set(h.origin, h.dir);
    const hit = firstHit(ray, hits);
    if (hit) {
      h.pending = hit;
      h.pendingDist = hit.point.distanceTo(h.origin);
    } else {
      h.pending = {
        point: h.origin.clone().addScaledVector(h.dir, RANGE),
        object: null,
        grabable: null,
        socket: null,
      };
      h.pendingDist = RANGE;
    }
    h.travel = 0;
  }

  function release(side) {
    const h = hands[side];
    if (h.held?.userData) h.held.userData.heldBy = null;
    if (h.stuck?.socket) h.stuck.socket.charged = false;
    h.held = null;
    h.stuck = null;
    h.pending = null;
    h.state = "retract";
  }

  function update(dt, hits, playerPos, velocity) {
    camera.getWorldPosition(tmp);
    for (const side of ["left", "right"]) {
      const h = hands[side];
      h.origin.copy(tmp);
      localToWorldHandRest(camera, h);

      if (h.state === "holstered") {
        h.worldHand.visible = false;
        h.group.visible = true;
        h.group.rotation.x = Math.sin(performance.now() / 420) * 0.04;
        updateCable(h, h.restWorld, true);
        continue;
      }

      if (h.state === "flying") {
        h.travel += FLY * dt;
        const t = Math.min(1, h.travel / Math.max(0.2, h.pendingDist));
        h.worldHand.position.lerpVectors(h.origin, h.pending.point, t);
        h.worldHand.lookAt(h.pending.point);
        updateCable(h, h.worldHand.position, false);
        if (t >= 1) {
          if (h.pending.grabable) {
            h.state = "holding";
            h.held = h.pending.grabable;
            h.held.userData.heldBy = side;
          } else if (h.pending.socket) {
            h.state = "stuck";
            h.stuck = { point: h.pending.point.clone(), socket: h.pending.socket };
            h.pending.socket.charged = true;
          } else if (h.pending.object) {
            h.state = "stuck";
            h.stuck = { point: h.pending.point.clone(), socket: null };
          } else {
            h.state = "retract";
          }
        }
        continue;
      }

      if (h.state === "stuck") {
        h.worldHand.position.copy(h.stuck.point);
        h.worldHand.lookAt(h.origin);
        updateCable(h, h.worldHand.position, false);
        const to = tmp2.subVectors(h.stuck.point, playerPos);
        to.y = 0;
        const dist = to.length();
        if (dist > 1.4) {
          to.normalize();
          velocity.x += to.x * PULL * dt;
          velocity.z += to.z * PULL * dt;
        }
        continue;
      }

      if (h.state === "holding" && h.held) {
        const hold = tmp2.copy(h.origin).addScaledVector(h.dirHold(camera), 2.1);
        hold.y = Math.max(0.45, hold.y);
        h.held.position.lerp(hold, 1 - Math.pow(0.001, dt));
        h.worldHand.position.copy(h.held.position);
        h.worldHand.lookAt(h.origin);
        updateCable(h, h.worldHand.position, false);
        continue;
      }

      if (h.state === "retract") {
        h.worldHand.position.lerp(h.restWorld, 1 - Math.exp(-RETRACT * dt));
        updateCable(h, h.worldHand.position, false);
        if (h.worldHand.position.distanceTo(h.restWorld) < 0.18) {
          h.state = "holstered";
          h.worldHand.visible = false;
          h.group.visible = true;
        }
      }
    }

    velocity.x *= 0.86;
    velocity.z *= 0.86;
    return velocity;
  }

  function bothSocketsCharged(gate) {
    return gate?.sockets?.every((s) => s.charged);
  }

  function dispose() {
    scene.remove(left.worldHand, right.worldHand, left.cable, right.cable);
  }

  return { fire, release, update, bothSocketsCharged, dispose, hands };
}

function makeHand(side, color, rest) {
  const group = new THREE.Group();
  group.position.copy(rest);

  const palm = new THREE.Mesh(
    new THREE.BoxGeometry(0.09, 0.05, 0.12),
    new THREE.MeshStandardMaterial({
      color: 0x111111,
      metalness: 0.75,
      roughness: 0.28,
      emissive: color,
      emissiveIntensity: 0.35,
    })
  );
  group.add(palm);

  const stripe = new THREE.Mesh(
    new THREE.BoxGeometry(0.1, 0.02, 0.04),
    new THREE.MeshStandardMaterial({ color: 0xf0c000, metalness: 0.4, roughness: 0.4 })
  );
  stripe.position.y = 0.03;
  group.add(stripe);

  for (const x of [-0.03, 0.03]) {
    const claw = new THREE.Mesh(
      new THREE.ConeGeometry(0.015, 0.08, 6),
      new THREE.MeshStandardMaterial({ color, metalness: 0.6, roughness: 0.25, emissive: color, emissiveIntensity: 0.5 })
    );
    claw.position.set(x, 0, -0.09);
    claw.rotation.x = Math.PI;
    group.add(claw);
  }

  const worldHand = group.clone(true);
  worldHand.visible = false;

  const cableGeo = new THREE.BufferGeometry().setFromPoints([new THREE.Vector3(), new THREE.Vector3()]);
  const cable = new THREE.Line(
    cableGeo,
    new THREE.LineBasicMaterial({ color, transparent: true, opacity: 0.85 })
  );

  const glow = new THREE.PointLight(color, 0.55, 3.5);
  group.add(glow);

  return {
    side,
    group,
    worldHand,
    cable,
    rest,
    restWorld: new THREE.Vector3(),
    origin: new THREE.Vector3(),
    dir: new THREE.Vector3(),
    state: "holstered",
    pending: null,
    pendingDist: 0,
    travel: 0,
    stuck: null,
    held: null,
    dirHold(camera) {
      const d = new THREE.Vector3();
      camera.getWorldDirection(d);
      return d;
    },
  };
}

function localToWorldHandRest(camera, h) {
  h.restWorld.copy(h.rest).applyMatrix4(camera.matrixWorld);
}

function updateCable(h, end, dim) {
  const p = h.cable.geometry.attributes.position;
  p.setXYZ(0, h.origin.x, h.origin.y - 0.12, h.origin.z);
  p.setXYZ(1, end.x, end.y, end.z);
  p.needsUpdate = true;
  h.cable.material.opacity = dim ? 0.15 : 0.9;
}

function firstHit(ray, hits) {
  const list = ray.intersectObjects(hits, true);
  for (const hit of list) {
    let obj = hit.object;
    while (obj && !obj.userData.grabable && !obj.userData.socket && !obj.userData.world) {
      obj = obj.parent;
    }
    if (!obj) {
      return { point: hit.point.clone(), object: hit.object, grabable: null, socket: null };
    }
    return {
      point: hit.point.clone(),
      object: obj,
      grabable: obj.userData.grabable ? obj : null,
      socket: obj.userData.socket ? obj.userData : null,
    };
  }
  return null;
}
