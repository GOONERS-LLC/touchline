// Merges Transfermarkt squad data into the bundled league files.
//
//   node tools/enrich-from-transfermarkt.js <dir-with-transfermarkt-tier-files> [--write]
//
// For every club that also exists in the Transfermarkt files (matched by
// normalised name):
//   * players found in both get Transfermarkt age and preferred foot (nationality spellings stay, as national teams depend on them);
//   * a squad where fewer than 40% of players are found on Transfermarkt is
//     treated as placeholder data and replaced by the real squad, rescaled so
//     the club's median rating is unchanged (game balance stays the same).
// Without --write it only prints what would change.
const fs = require('fs');
const path = require('path');

const tmDir = process.argv[2];
const write = process.argv.includes('--write');
const OUT = path.join(__dirname, '..', 'Touchline', 'Data', 'Resources');
if (!tmDir) { console.error('usage: node tools/enrich-from-transfermarkt.js <tm-dir> [--write]'); process.exit(1); }

const norm = s => (s || '').normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase()
  .replace(/\b(fc|afc|cf|sc|ac|fk|sk|cd|ud|sv|vfl|vfb|tsg|ss|as|club|de|the|cp|sad)\b/g, ' ')
  .replace(/[^a-z0-9]+/g, ' ').trim();
const median = xs => { const s = [...xs].sort((a, b) => a - b); return s.length ? s[Math.floor(s.length / 2)] : 0; };

const tmClubs = new Map();
const tmByTier = new Map();
for (const f of fs.readdirSync(tmDir).filter(f => /^tier\d+\.json$/.test(f))) {
  const clubs = JSON.parse(fs.readFileSync(path.join(tmDir, f), 'utf8')).clubs;
  tmByTier.set(f, clubs);
  for (const c of clubs) tmClubs.set(norm(c.name), c);
}

/// Exact normalised name first; otherwise, within the same league file, a
/// club whose name contains every word of ours ("Lecce" in "US Lecce").
function findTm(name, file) {
  const exact = tmClubs.get(norm(name));
  if (exact) return exact;
  const words = norm(name).split(' ').filter(w => w.length > 2);
  if (!words.length) return undefined;
  const pool = tmByTier.get(file) || [];
  const hits = pool.filter(c => {
    const theirs = norm(c.name).split(' ');
    return words.every(w => theirs.some(t => t === w || (w.length >= 5 && t.startsWith(w.slice(0, 5)))));
  });
  return hits.length === 1 ? hits[0] : undefined;
}

let clubsMatched = 0, playersUpdated = 0, squadsReplaced = 0, clubsTotal = 0;
const replaced = [];
for (const f of fs.readdirSync(OUT).filter(f => /^tier\d+\.json$/.test(f))) {
  const file = path.join(OUT, f);
  const league = JSON.parse(fs.readFileSync(file, 'utf8'));
  let changed = false;
  for (const club of league.clubs) {
    clubsTotal++;
    const tm = findTm(club.name, f);
    if (!tm) continue;
    clubsMatched++;
    const byName = new Map(tm.players.map(p => [norm(`${p.firstName} ${p.lastName}`), p]));
    const byLast = new Map(tm.players.map(p => [norm(p.lastName), p]));
    let found = 0;
    for (const p of club.players) {
      const hit = byName.get(norm(`${p.firstName} ${p.lastName}`)) || (p.lastName.length > 4 ? byLast.get(norm(p.lastName)) : undefined);
      if (!hit) continue;
      found++;
      if (p.age !== hit.age || (hit.preferredFoot && p.preferredFoot !== hit.preferredFoot)) {
        p.age = hit.age;
        if (hit.preferredFoot) p.preferredFoot = hit.preferredFoot;
        playersUpdated++;
        changed = true;
      }
    }
    const ratio = club.players.length ? found / club.players.length : 0;
    if (ratio < 0.4 && tm.players.length >= 16) {
      const oldMedian = median(club.players.map(p => p.overall));
      const newMedian = median(tm.players.map(p => p.overall));
      const shift = oldMedian - newMedian;
      club.players = tm.players.map(p => ({
        ...p,
        overall: Math.max(35, Math.min(95, p.overall + shift)),
        potential: Math.max(Math.max(35, Math.min(95, p.overall + shift)), Math.min(96, p.potential + shift)),
      }));
      squadsReplaced++;
      replaced.push(`${club.name} (${league.name}, ${Math.round(ratio * 100)}% matched before)`);
      changed = true;
    }
  }
  if (changed && write) fs.writeFileSync(file, JSON.stringify(league));
}
console.log(`${clubsMatched} of ${clubsTotal} clubs matched; ${playersUpdated} players corrected; ${squadsReplaced} placeholder squads replaced${write ? '' : ' (dry run)'}`);
for (const r of replaced) console.log('  replaced: ' + r);
