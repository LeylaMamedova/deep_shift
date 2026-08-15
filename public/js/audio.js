/** Dissonant broken-piano stingers. Original, synthesized — no licensed audio. */
let ctx;

function ac() {
  if (!ctx) ctx = new (window.AudioContext || window.webkitAudioContext)();
  if (ctx.state === "suspended") ctx.resume();
  return ctx;
}

function tone(freq, t, dur, type = "triangle", gain = 0.12) {
  const c = ac();
  const o = c.createOscillator();
  const g = c.createGain();
  o.type = type;
  o.frequency.value = freq;
  g.gain.setValueAtTime(gain, t);
  g.gain.exponentialRampToValueAtTime(0.0001, t + dur);
  o.connect(g);
  g.connect(c.destination);
  o.start(t);
  o.stop(t + dur + 0.02);
}

export function resumeAudio() {
  ac();
}

export function pianoChatter(intensity = 0.4) {
  const c = ac();
  const t = c.currentTime;
  const notes = [523.25, 554.37, 659.25, 698.46, 830.61];
  const n = notes[(Math.random() * notes.length) | 0];
  tone(n, t, 0.07 + Math.random() * 0.05, "square", 0.03 * intensity);
  if (Math.random() < 0.35) tone(n * 0.5, t, 0.12, "sawtooth", 0.02 * intensity);
}

export function pianoStalk(dist) {
  if (Math.random() > 0.08) return;
  const c = ac();
  const t = c.currentTime;
  const vol = Math.max(0.01, (1 - Math.min(dist, 22) / 22) * 0.08);
  tone(110 + Math.random() * 40, t, 0.4, "sine", vol);
  tone(116.5, t + 0.05, 0.3, "triangle", vol * 0.7);
}

export function jumpscareSlam() {
  const c = ac();
  const t = c.currentTime;
  const cluster = [48, 51, 55, 58, 61, 64, 70, 73];
  for (const midi of cluster) {
    const f = 440 * Math.pow(2, (midi - 69) / 12);
    tone(f, t, 0.55, "sawtooth", 0.09);
    tone(f * 0.5, t, 0.7, "square", 0.05);
  }
  const noise = c.createBufferSource();
  const buf = c.createBuffer(1, c.sampleRate * 0.35, c.sampleRate);
  const data = buf.getChannelData(0);
  for (let i = 0; i < data.length; i++) data[i] = (Math.random() * 2 - 1) * (1 - i / data.length);
  noise.buffer = buf;
  const ng = c.createGain();
  ng.gain.setValueAtTime(0.22, t);
  ng.gain.exponentialRampToValueAtTime(0.0001, t + 0.35);
  noise.connect(ng);
  ng.connect(c.destination);
  noise.start(t);
  tone(38, t, 1.1, "sine", 0.2);
  tone(41, t + 0.02, 0.9, "sawtooth", 0.12);
}
