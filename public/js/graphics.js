import * as THREE from "three";

/**
 * High-graphics pipeline: ACES tonemap, soft shadows, bloom, vignette, grain.
 * quality: "high" | "ultra"
 */
export function createGraphics(canvas, quality = "ultra") {
  const ultra = quality === "ultra";
  const renderer = new THREE.WebGLRenderer({
    canvas,
    antialias: ultra,
    powerPreference: "high-performance",
    stencil: false,
  });
  renderer.setPixelRatio(Math.min(devicePixelRatio || 1, ultra ? 2 : 1.35));
  renderer.outputColorSpace = THREE.SRGBColorSpace;
  renderer.toneMapping = THREE.ACESFilmicToneMapping;
  renderer.toneMappingExposure = 0.88;
  renderer.shadowMap.enabled = true;
  renderer.shadowMap.type = THREE.PCFSoftShadowMap;
  renderer.autoClear = false;

  const size = new THREE.Vector2();
  renderer.getSize(size);

  const rtOpts = {
    minFilter: THREE.LinearFilter,
    magFilter: THREE.LinearFilter,
    format: THREE.RGBAFormat,
  };
  const sceneRT = new THREE.WebGLRenderTarget(size.x, size.y, rtOpts);
  try {
    sceneRT.samples = ultra ? 4 : 0;
  } catch {
    sceneRT.samples = 0;
  }
  const bloomRT = new THREE.WebGLRenderTarget(Math.floor(size.x / 2), Math.floor(size.y / 2), rtOpts);
  const blurRT = new THREE.WebGLRenderTarget(Math.floor(size.x / 2), Math.floor(size.y / 2), rtOpts);

  const quadCam = new THREE.OrthographicCamera(-1, 1, 1, -1, 0, 1);
  const quadGeo = new THREE.PlaneGeometry(2, 2);

  const brightMat = new THREE.ShaderMaterial({
    uniforms: {
      tDiffuse: { value: null },
      threshold: { value: 0.72 },
    },
    vertexShader: VERT,
    fragmentShader: `
      uniform sampler2D tDiffuse;
      uniform float threshold;
      varying vec2 vUv;
      void main() {
        vec4 c = texture2D(tDiffuse, vUv);
        float lum = dot(c.rgb, vec3(0.2126, 0.7152, 0.0722));
        gl_FragColor = vec4(c.rgb * smoothstep(threshold, threshold + 0.25, lum), 1.0);
      }
    `,
  });

  const blurMat = new THREE.ShaderMaterial({
    uniforms: {
      tDiffuse: { value: null },
      direction: { value: new THREE.Vector2(1, 0) },
      resolution: { value: new THREE.Vector2(bloomRT.width, bloomRT.height) },
    },
    vertexShader: VERT,
    fragmentShader: `
      uniform sampler2D tDiffuse;
      uniform vec2 direction;
      uniform vec2 resolution;
      varying vec2 vUv;
      void main() {
        vec2 px = direction / resolution;
        vec3 acc = texture2D(tDiffuse, vUv).rgb * 0.227027;
        acc += texture2D(tDiffuse, vUv + px * 1.384615).rgb * 0.316216;
        acc += texture2D(tDiffuse, vUv - px * 1.384615).rgb * 0.316216;
        acc += texture2D(tDiffuse, vUv + px * 3.230769).rgb * 0.070270;
        acc += texture2D(tDiffuse, vUv - px * 3.230769).rgb * 0.070270;
        gl_FragColor = vec4(acc, 1.0);
      }
    `,
  });

  const compositeMat = new THREE.ShaderMaterial({
    uniforms: {
      tScene: { value: null },
      tBloom: { value: null },
      bloomStrength: { value: ultra ? 0.55 : 0.38 },
      vignette: { value: 0.55 },
      time: { value: 0 },
    },
    vertexShader: VERT,
    fragmentShader: `
      uniform sampler2D tScene;
      uniform sampler2D tBloom;
      uniform float bloomStrength;
      uniform float vignette;
      uniform float time;
      varying vec2 vUv;
      float hash(vec2 p) {
        return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
      }
      void main() {
        vec2 uv = vUv;
        vec3 scene = texture2D(tScene, uv).rgb;
        vec3 bloom = texture2D(tBloom, uv).rgb;
        vec3 col = scene + bloom * bloomStrength;
        float d = distance(uv, vec2(0.5));
        col *= smoothstep(1.05, 0.35, d * (0.65 + vignette));
        float g = hash(uv * vec2(1920.0, 1080.0) + time) * 0.035;
        col += g;
        gl_FragColor = vec4(col, 1.0);
      }
    `,
  });

  const brightMesh = new THREE.Mesh(quadGeo, brightMat);
  const blurMesh = new THREE.Mesh(quadGeo, blurMat);
  const compMesh = new THREE.Mesh(quadGeo, compositeMat);
  const passScene = new THREE.Scene();
  passScene.add(brightMesh);

  function resize() {
    const w = canvas.clientWidth || innerWidth;
    const h = canvas.clientHeight || innerHeight;
    renderer.setSize(w, h, false);
    sceneRT.setSize(w, h);
    bloomRT.setSize(Math.max(1, w >> 1), Math.max(1, h >> 1));
    blurRT.setSize(Math.max(1, w >> 1), Math.max(1, h >> 1));
    blurMat.uniforms.resolution.value.set(bloomRT.width, bloomRT.height);
  }

  function render(scene, camera, time = 0) {
    renderer.setRenderTarget(sceneRT);
    renderer.clear();
    renderer.render(scene, camera);

    brightMat.uniforms.tDiffuse.value = sceneRT.texture;
    renderer.setRenderTarget(bloomRT);
    renderer.clear();
    brightMesh.material = brightMat;
    renderer.render(passScene, quadCam);

    blurMat.uniforms.tDiffuse.value = bloomRT.texture;
    blurMat.uniforms.direction.value.set(1, 0);
    renderer.setRenderTarget(blurRT);
    brightMesh.material = blurMat;
    renderer.render(passScene, quadCam);

    blurMat.uniforms.tDiffuse.value = blurRT.texture;
    blurMat.uniforms.direction.value.set(0, 1);
    renderer.setRenderTarget(bloomRT);
    renderer.render(passScene, quadCam);

    compositeMat.uniforms.tScene.value = sceneRT.texture;
    compositeMat.uniforms.tBloom.value = bloomRT.texture;
    compositeMat.uniforms.time.value = time;
    renderer.setRenderTarget(null);
    brightMesh.material = compositeMat;
    renderer.render(passScene, quadCam);
    brightMesh.material = brightMat;
  }

  function makeEnvironment(scene) {
    const pmrem = new THREE.PMREMGenerator(renderer);
    const envScene = new THREE.Scene();
    envScene.add(new THREE.HemisphereLight(0xff6a4a, 0x080204, 1.2));
    envScene.add(new THREE.AmbientLight(0x2a1014, 0.4));
    const env = pmrem.fromScene(envScene, 0.06).texture;
    scene.environment = env;
    pmrem.dispose();
    return env;
  }

  function dispose() {
    sceneRT.dispose();
    bloomRT.dispose();
    blurRT.dispose();
    quadGeo.dispose();
    brightMat.dispose();
    blurMat.dispose();
    compositeMat.dispose();
    renderer.dispose();
  }

  resize();
  return { renderer, render, resize, makeEnvironment, dispose, quality };
}

const VERT = `
  varying vec2 vUv;
  void main() {
    vUv = uv;
    gl_Position = vec4(position.xy, 0.0, 1.0);
  }
`;
