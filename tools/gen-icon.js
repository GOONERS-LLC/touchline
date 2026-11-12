// Generates a 1024x1024 app icon PNG for Touchline with no external dependencies.
// Uses a raw RGBA buffer encoded as a PNG (zlib via Node's built-in zlib).
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const SIZE = 1024;
const buf = Buffer.alloc(SIZE * SIZE * 4, 0);

function set(x, y, r, g, b, a = 255) {
  if (x < 0 || y < 0 || x >= SIZE || y >= SIZE) return;
  const i = (y * SIZE + x) * 4;
  buf[i] = r; buf[i + 1] = g; buf[i + 2] = b; buf[i + 3] = a;
}

// Touchline icon: night-sky navy, a floodlit amber touchline, and a bold
// white "T" whose crossbar doubles as the halfway line.
const lerp = (p, q, k) => Math.round(p + (q - p) * k);
for (let y = 0; y < SIZE; y++) {
  const k = y / SIZE;
  for (let x = 0; x < SIZE; x++) {
    // Diagonal glow from the top right, like a floodlight.
    const glow = Math.max(0, 1 - Math.hypot(x - SIZE * 0.85, y - SIZE * 0.1) / (SIZE * 0.9));
    set(x, y,
      Math.min(255, lerp(18, 8, k) + Math.round(glow * 30)),
      Math.min(255, lerp(30, 12, k) + Math.round(glow * 60)),
      Math.min(255, lerp(72, 28, k) + Math.round(glow * 150)));
  }
}
function rect(x0, y0, x1, y1, color) {
  for (let y = y0; y < y1; y++) for (let x = x0; x < x1; x++) set(x, y, ...color);
}
function disc(cx, cy, r, color) {
  for (let y = cy - r; y <= cy + r; y++) for (let x = cx - r; x <= cx + r; x++)
    if (Math.hypot(x - cx, y - cy) <= r) set(x, y, ...color);
}
const white = [245, 247, 255], amber = [255, 176, 32];
// Crossbar and stem of the T.
rect(212, 250, 812, 360, white);
rect(457, 250, 567, 780, white);
// Amber touchline across the base.
rect(120, 820, 904, 860, amber);
// Ball resting on the touchline, right of the stem.
disc(700, 740, 70, amber);
disc(700, 740, 30, [18, 30, 72]);

// Encode PNG.
function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const typeBuf = Buffer.from(type, 'ascii');
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(Buffer.concat([typeBuf, data])) >>> 0, 0);
  return Buffer.concat([len, typeBuf, data, crc]);
}

let crcTable = null;
function crc32(buf) {
  if (!crcTable) {
    crcTable = [];
    for (let n = 0; n < 256; n++) {
      let c = n;
      for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
      crcTable[n] = c >>> 0;
    }
  }
  let c = 0xffffffff;
  for (let i = 0; i < buf.length; i++) c = crcTable[(c ^ buf[i]) & 0xff] ^ (c >>> 8);
  return (c ^ 0xffffffff) >>> 0;
}

const sig = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(SIZE, 0);
ihdr.writeUInt32BE(SIZE, 4);
ihdr[8] = 8;    // bit depth
ihdr[9] = 6;    // color type RGBA
ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;

// Add filter byte (0) at the start of each row.
const raw = Buffer.alloc(SIZE * (SIZE * 4 + 1));
for (let y = 0; y < SIZE; y++) {
  raw[y * (SIZE * 4 + 1)] = 0;
  buf.copy(raw, y * (SIZE * 4 + 1) + 1, y * SIZE * 4, (y + 1) * SIZE * 4);
}
const idat = zlib.deflateSync(raw, { level: 9 });

const png = Buffer.concat([sig, chunk('IHDR', ihdr), chunk('IDAT', idat), chunk('IEND', Buffer.alloc(0))]);

const out = path.join(__dirname, '..', 'Touchline', 'Assets.xcassets', 'AppIcon.appiconset', 'icon-1024.png');
fs.mkdirSync(path.dirname(out), { recursive: true });
fs.writeFileSync(out, png);
console.log('Wrote', out, png.length, 'bytes');
