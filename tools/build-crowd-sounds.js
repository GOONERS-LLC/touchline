// Builds Touchline/Sounds/*.m4a from public-domain (CC0) Freesound recordings.
//
//   node tools/build-crowd-sounds.js <folder-with-<id>.mp3-previews>
//
// Reaction clips are cut around the moment the crowd erupts (found by
// loudness), crowd beds are trimmed to a steady stretch with soft edges so
// they loop, and everything is loudness-normalised and encoded as AAC.
// Requires ffmpeg on the PATH. Credits are in Touchline/Sounds/CREDITS.md.
const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const src = process.argv[2];
if (!src) { console.error('usage: node tools/build-crowd-sounds.js <folder>'); process.exit(1); }
const OUT = path.join(__dirname, '..', 'Touchline', 'Sounds');
fs.mkdirSync(OUT, { recursive: true });

// name, source id, kind, length (s), loudness target (LUFS), optional fixed start
const CLIPS = [
  ['crowd_bed_small', 868982, 'bed', 60, -24, 8],
  ['crowd_bed_medium', 829456, 'bed', 75, -23, 30],
  ['crowd_bed_large', 424354, 'bed', 55, -22, 3],
  ['crowd_goal_1', 829455, 'onset', 10, -14],
  ['crowd_goal_2', 241630, 'onset', 9, -14],
  ['crowd_goal_3', 348978, 'onset', 9, -14],
  ['crowd_ooh_1', 494362, 'onset', 4, -16],
  ['crowd_ooh_2', 612131, 'onset', 4.5, -16],
  ['crowd_groan', 764106, 'onset', 4.5, -17],
  ['crowd_boo', 557189, 'onset', 6, -17],
  ['crowd_cheer', 397435, 'onset', 5, -16],
  ['crowd_applause', 629884, 'onset', 6, -18],
  ['crowd_chant', 733614, 'loudest', 12, -18],
  ['referee_whistle', 538422, 'whole', 0, -14],
];

const RATE = 8000;
function envelope(file) {
  const raw = execFileSync('ffmpeg', ['-v', 'error', '-i', file, '-ac', '1', '-ar', String(RATE), '-f', 's16le', '-'], { maxBuffer: 1 << 28 });
  const win = RATE / 4; // quarter-second windows
  const env = [];
  for (let i = 0; i + win * 2 <= raw.length; i += win * 2) {
    let sum = 0;
    for (let j = 0; j < win; j++) { const v = raw.readInt16LE(i + j * 2) / 32768; sum += v * v; }
    env.push(Math.sqrt(sum / win));
  }
  return env; // one value per 0.25 s
}

function startFor(kind, env, length) {
  const n = Math.max(1, Math.round(length * 4));
  if (kind === 'onset') {
    // The first time the crowd reaches 75% of its peak, minus half a second.
    const peak = Math.max(...env);
    const idx = env.findIndex(v => v >= peak * 0.75);
    return Math.max(0, idx / 4 - 0.5);
  }
  if (kind === 'loudest') {
    let best = 0, bestSum = -1;
    for (let i = 0; i + n <= env.length; i++) {
      const s = env.slice(i, i + n).reduce((a, b) => a + b, 0);
      if (s > bestSum) { bestSum = s; best = i; }
    }
    return best / 4;
  }
  return 0;
}

for (const [name, id, kind, length, lufs, fixedStart] of CLIPS) {
  const file = path.join(src, `${id}.mp3`);
  if (!fs.existsSync(file)) { console.warn(`missing ${file}`); continue; }
  const env = kind === 'whole' || kind === 'bed' ? [] : envelope(file);
  const start = fixedStart ?? startFor(kind, env, length);
  const fadeIn = kind === 'bed' ? 1.2 : 0.05;
  const fadeOut = kind === 'bed' ? 1.2 : Math.min(1.2, (length || 1) * 0.25);
  const args = ['-v', 'error', '-y', '-ss', String(start)];
  if (length) args.push('-t', String(length));
  args.push('-i', file);
  const filters = [`loudnorm=I=${lufs}:TP=-1.5:LRA=11`];
  if (length) filters.push(`afade=t=in:d=${fadeIn}`, `afade=t=out:st=${Math.max(0, length - fadeOut)}:d=${fadeOut}`);
  args.push('-af', filters.join(','), '-ar', '44100', '-ac', '2', '-c:a', 'aac', '-b:a', kind === 'bed' ? '96k' : '128k',
            path.join(OUT, `${name}.m4a`));
  execFileSync('ffmpeg', args);
  const size = fs.statSync(path.join(OUT, `${name}.m4a`)).size;
  console.log(`${name.padEnd(18)} from ${id} at ${start.toFixed(2)}s, ${length || 'full'}s, ${(size / 1024).toFixed(0)} KB`);
}
