#!/usr/bin/env node
// Curates bundled league data: real display names, 3-letter codes, cities and
// club colours; reputation derived from squad strength and stadium size;
// 2025-26 membership corrections; and second divisions for Spain, Italy,
// Germany, France and Scotland. Idempotent: run again after editing the
// metadata tables in tools/data/.
const fs = require('fs');
const path = require('path');
const dir = path.join(__dirname, '..', 'Touchline', 'Data', 'Resources');
const meta = Object.assign({},
  require('./data/club-meta-1.js'), require('./data/club-meta-2.js'), require('./data/club-meta-3.js'));
const extra = require('./data/new-clubs.js');

// Historic prestige the squad rating alone does not capture.
const giants = {
  6: ['Real Madrid', 'Barcelona', 'Bayern Munich', 'Manchester United', 'Liverpool', 'Juventus',
      'AC Milan', 'Inter', 'Paris Saint-Germain', 'Arsenal', 'Chelsea', 'Manchester City'],
  4: ['Atlético Madrid', 'Borussia Dortmund', 'Tottenham Hotspur', 'Ajax', 'Benfica', 'Porto',
      'Celtic', 'Rangers', 'Boca Juniors', 'River Plate', 'Flamengo', 'Galatasaray', 'Fenerbahçe',
      'Napoli', 'Roma', 'Olympique de Marseille', 'Newcastle United', 'Feyenoord', 'PSV', 'Sporting CP'],
};
const giantBonus = name => (giants[6].includes(name) ? 6 : giants[4].includes(name) ? 4 : 0);
// Typical standing for divisions whose squads are generated in-game.
const generatedBase = { 13: 46, 14: 38, 22: 52, 32: 52, 42: 55, 52: 48, 92: 34 };

const parse = s => {
  const [name, shortName, city, primaryColor, secondaryColor, stadium, cap] = s.split('|');
  return { name, shortName, city, primaryColor, secondaryColor, stadium, stadiumCapacity: cap ? parseInt(cap, 10) : undefined };
};
const topAverage = (club, n) => {
  const o = club.players.map(p => p.overall).sort((a, b) => b - a).slice(0, n);
  return o.length ? o.reduce((a, b) => a + b, 0) / o.length : 0;
};
const clamp = (v, lo, hi) => Math.max(lo, Math.min(hi, v));
const newClub = (spec, tier) => ({
  name: spec.name, shortName: spec.shortName, stadium: spec.stadium, stadiumCapacity: spec.stadiumCapacity,
  city: spec.city, primaryColor: spec.primaryColor, secondaryColor: spec.secondaryColor,
  reputation: 0, manager: 'Head Coach', budget: 0, wageBudget: 0, players: [],
});

// 1. Create the new divisions.
for (const [tier, def] of Object.entries(extra.leagues)) {
  const file = path.join(dir, `tier${tier}.json`);
  const league = { name: def.name, season: '2026-27', tier: parseInt(tier, 10), clubs: def.clubs.map(s => newClub(parse(s), tier)) };
  fs.writeFileSync(file, JSON.stringify(league));
}

const renames = {};
const missing = [];
const files = fs.readdirSync(dir).filter(f => /^tier\d+\.json$/.test(f));
for (const f of files) {
  const file = path.join(dir, f);
  const league = JSON.parse(fs.readFileSync(file, 'utf8'));
  const tier = league.tier;

  // 2. Membership corrections.
  const removals = extra.removals[tier] || [];
  league.clubs = league.clubs.filter(c => !removals.includes(c.name));
  for (const s of extra.additions[tier] || []) {
    const spec = parse(s);
    if (!league.clubs.some(c => c.name === spec.name)) league.clubs.push(newClub(spec, tier));
  }

  // 3. Names, codes, cities and colours.
  for (const club of league.clubs) {
    const m = meta[club.name];
    if (m) {
      const spec = parse(m);
      if (spec.name !== club.name) renames[club.name] = spec.name;
      Object.assign(club, { name: spec.name, shortName: spec.shortName, city: spec.city,
        primaryColor: spec.primaryColor, secondaryColor: spec.secondaryColor });
    } else if (!Object.values(meta).some(v => v.startsWith(club.name + '|')) && !extra.leagues[tier]
               && !(extra.additions[tier] || []).some(s => s.startsWith(club.name + '|'))) {
      missing.push(`${f}: ${club.name}`);
    }
  }

  // 4. Reputation from squad strength, stadium size and history.
  const rated = league.clubs.filter(c => c.players.length >= 11);
  const ratedReps = rated.map(c => 20 + (topAverage(c, 16) - 45) * 1.5 + Math.min(6, c.stadiumCapacity / 10000) + giantBonus(c.name));
  const median = ratedReps.length ? ratedReps.slice().sort((a, b) => a - b)[Math.floor(ratedReps.length / 2)] : null;
  for (const club of league.clubs) {
    let rep;
    if (club.players.length >= 11) {
      rep = 20 + (topAverage(club, 16) - 45) * 1.5 + Math.min(6, club.stadiumCapacity / 10000) + giantBonus(club.name);
    } else {
      const base = median != null ? median - 2 : (generatedBase[tier] || 45);
      rep = base + Math.min(8, club.stadiumCapacity / 6000) - 3;
    }
    club.reputation = Math.round(clamp(rep, 18, 99));
  }

  // 5. Codes must be unique within a division.
  const seen = new Set();
  for (const club of league.clubs) {
    let code = club.shortName;
    let n = 2;
    while (seen.has(code)) code = club.shortName.slice(0, 3) + n++;
    club.shortName = code;
    seen.add(code);
  }

  fs.writeFileSync(file, JSON.stringify(league));
}

// 6. Player names: the source repeats the first name inside the last name
//    ("Nacho" + "Nacho Ferri") and lists single-name players twice
//    ("Richarlison" + "Richarlison"). Store a mononym as a last name only.
const fixName = p => {
  if (!p.firstName) return;
  if (p.lastName === p.firstName) { p.firstName = ''; return; }
  if (p.lastName.startsWith(p.firstName + ' ')) p.lastName = p.lastName.slice(p.firstName.length + 1);
};
for (const f of fs.readdirSync(dir).filter(f => /^tier\d+\.json$/.test(f))) {
  const file = path.join(dir, f);
  const league = JSON.parse(fs.readFileSync(file, 'utf8'));
  league.clubs.forEach(c => c.players.forEach(fixName));
  fs.writeFileSync(file, JSON.stringify(league));
}
const ntFile = path.join(dir, 'national_teams.json');
const nt = JSON.parse(fs.readFileSync(ntFile, 'utf8'));
nt.teams.forEach(t => (t.players || []).forEach(fixName));
fs.writeFileSync(ntFile, JSON.stringify(nt));

// 7. Keep European competition entries pointing at the renamed clubs.
const euroFile = path.join(dir, 'european_competitions.json');
const euro = JSON.parse(fs.readFileSync(euroFile, 'utf8'));
for (const comp of euro.competitions) {
  comp.clubNames = comp.clubNames.map(n => renames[n] || n);
}
fs.writeFileSync(euroFile, JSON.stringify(euro));

// 8. Rivalries: validated against the final club names and written to
//    rivalries.json for the game to load.
const allNames = new Set();
for (const f of fs.readdirSync(dir).filter(f => /^tier\d+\.json$/.test(f))) {
  JSON.parse(fs.readFileSync(path.join(dir, f), 'utf8')).clubs.forEach(c => allNames.add(c.name));
}
const rivalries = [];
const unknown = [];
for (const [a, b, name, intensity] of require('./data/rivalries.js')) {
  for (const club of [a, b]) if (!allNames.has(club)) unknown.push(`${club} (${name})`);
  if (allNames.has(a) && allNames.has(b)) rivalries.push({ clubA: a, clubB: b, name, intensity });
}
fs.writeFileSync(path.join(dir, 'rivalries.json'), JSON.stringify({ rivalries }));
console.log(`Wrote ${rivalries.length} rivalries.`);
if (unknown.length) console.log('Rivalry clubs not in the game (skipped): ' + unknown.join(', '));

console.log(`Renamed ${Object.keys(renames).length} clubs.`);
if (missing.length) { console.log('No metadata for:'); missing.forEach(m => console.log('  ' + m)); }
