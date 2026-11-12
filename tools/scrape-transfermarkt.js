// Rebuilds Touchline/Data/Resources/tier<rawValue>.json from live Transfermarkt
// squad pages for the current season, so every league (including the English
// Championship, League One and League Two) carries real players with real
// dates of birth, nationalities, preferred feet and market values.
//
//   node tools/scrape-transfermarkt.js            # all leagues
//   node tools/scrape-transfermarkt.js GB2 GB3    # selected competitions
//
// Pages are cached in tools/.tm-cache so re-runs are fast and polite.
// Ratings come from market value, then each league is shifted (at most 8
// points) so its median matches the previously shipped file. That keeps game
// balance stable while the squads themselves become real.
const fs = require('fs');
const path = require('path');

const SEASON_ID = process.env.TM_SEASON || '2026';
const SEASON_LABEL = '2026-27';
const AGE_YEAR = 2026;
const HOST = 'https://www.transfermarkt.co.uk';
const UA = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36';
const OUT = path.join(__dirname, '..', 'Touchline', 'Data', 'Resources');
const CACHE = path.join(__dirname, '.tm-cache');
const DELAY_MS = 1100;

// rawValue = index * 10 + level. England keeps its four-tier pyramid.
const LEAGUES = [
  { code: 'GB1', slug: 'premier-league', name: 'Premier League', raw: 11, country: 'England' },
  { code: 'GB2', slug: 'championship', name: 'Championship', raw: 12, country: 'England' },
  { code: 'GB3', slug: 'league-one', name: 'League One', raw: 13, country: 'England' },
  { code: 'GB4', slug: 'league-two', name: 'League Two', raw: 14, country: 'England' },
  { code: 'ES1', slug: 'laliga', name: 'La Liga', raw: 21, country: 'Spain' },
  { code: 'IT1', slug: 'serie-a', name: 'Serie A', raw: 31, country: 'Italy' },
  { code: 'L1', slug: 'bundesliga', name: 'Bundesliga', raw: 41, country: 'Germany' },
  { code: 'FR1', slug: 'ligue-1', name: 'Ligue 1', raw: 51, country: 'France' },
  { code: 'PO1', slug: 'liga-portugal', name: 'Primeira Liga', raw: 61, country: 'Portugal' },
  { code: 'NL1', slug: 'eredivisie', name: 'Eredivisie', raw: 71, country: 'Netherlands' },
  { code: 'TR1', slug: 'super-lig', name: 'Süper Lig', raw: 81, country: 'Türkiye' },
  { code: 'SC1', slug: 'scottish-premiership', name: 'Scottish Premiership', raw: 91, country: 'Scotland' },
  { code: 'BE1', slug: 'jupiler-pro-league', name: 'Belgian Pro League', raw: 101, country: 'Belgium' },
  { code: 'ARG1', slug: 'liga-profesional-de-futbol', name: 'Liga Profesional', raw: 111, country: 'Argentina' },
  { code: 'AUS1', slug: 'a-league-men', name: 'A-League', raw: 121, country: 'Australia' },
  { code: 'A1', slug: 'bundesliga', name: 'Austrian Bundesliga', raw: 131, country: 'Austria' },
  { code: 'BRA1', slug: 'campeonato-brasileiro-serie-a', name: 'Brasileirão Série A', raw: 141, country: 'Brazil' },
  { code: 'KR1', slug: 'supersport-hnl', name: 'SuperSport HNL', raw: 151, country: 'Croatia' },
  { code: 'TS1', slug: 'chance-liga', name: 'Chance Liga', raw: 161, country: 'Czech Republic' },
  { code: 'DK1', slug: 'superliga', name: 'Superliga', raw: 171, country: 'Denmark' },
  { code: 'GR1', slug: 'super-league-1', name: 'Super League Greece', raw: 181, country: 'Greece' },
  { code: 'JAP1', slug: 'j1-league', name: 'J1 League', raw: 191, country: 'Japan' },
  { code: 'RSK1', slug: 'k-league-1', name: 'K League 1', raw: 201, country: 'South Korea' },
  { code: 'MEX1', slug: 'liga-mx-apertura', name: 'Liga MX', raw: 211, country: 'Mexico' },
  { code: 'NO1', slug: 'eliteserien', name: 'Eliteserien', raw: 221, country: 'Norway' },
  { code: 'PL1', slug: 'pko-bp-ekstraklasa', name: 'Ekstraklasa', raw: 231, country: 'Poland' },
  { code: 'RO1', slug: 'superliga', name: 'SuperLiga', raw: 241, country: 'Romania' },
  { code: 'RU1', slug: 'premier-liga', name: 'Russian Premier League', raw: 251, country: 'Russia' },
  { code: 'SA1', slug: 'saudi-pro-league', name: 'Saudi Pro League', raw: 261, country: 'Saudi Arabia' },
  { code: 'SER1', slug: 'super-liga-srbije', name: 'Serbian SuperLiga', raw: 271, country: 'Serbia' },
  { code: 'SE1', slug: 'allsvenskan', name: 'Allsvenskan', raw: 281, country: 'Sweden' },
  { code: 'C1', slug: 'super-league', name: 'Swiss Super League', raw: 291, country: 'Switzerland' },
  { code: 'UKR1', slug: 'premier-liga', name: 'Ukrainian Premier League', raw: 301, country: 'Ukraine' },
  { code: 'MLS1', slug: 'major-league-soccer', name: 'Major League Soccer', raw: 311, country: 'United States' },
];

const POS = {
  'Goalkeeper': 'GK', 'Centre-Back': 'CB', 'Left-Back': 'LB', 'Right-Back': 'RB',
  'Defensive Midfield': 'CDM', 'Central Midfield': 'CM', 'Attacking Midfield': 'CAM',
  'Left Midfield': 'LM', 'Right Midfield': 'RM', 'Left Winger': 'LW', 'Right Winger': 'RW',
  'Centre-Forward': 'ST', 'Second Striker': 'CF', 'Defender': 'CB', 'Midfield': 'CM',
  'Attack': 'ST', 'Sweeper': 'CB',
};
// Sensible secondary positions so squads can fill any formation.
const SECONDARY = {
  LB: ['LWB'], RB: ['RWB'], CB: [], CDM: ['CM'], CM: ['CDM'], CAM: ['CM'],
  LM: ['LW'], RM: ['RW'], LW: ['LM'], RW: ['RM'], ST: ['CF'], CF: ['ST', 'CAM'], GK: [],
};

const sleep = ms => new Promise(r => setTimeout(r, ms));

async function get(url) {
  fs.mkdirSync(CACHE, { recursive: true });
  const file = path.join(CACHE, url.replace(/^https?:\/\/[^/]+\//, '').replace(/[^a-z0-9]+/gi, '_') + '.html');
  if (fs.existsSync(file) && fs.statSync(file).size > 5000) return fs.readFileSync(file, 'utf8');
  for (let attempt = 0; attempt < 5; attempt++) {
    await sleep(DELAY_MS + attempt * 4000);
    try {
      const res = await fetch(url, { headers: { 'User-Agent': UA, 'Accept-Language': 'en-GB,en;q=0.9' } });
      if (res.ok) {
        const html = await res.text();
        fs.writeFileSync(file, html);
        return html;
      }
      console.warn(`  ${res.status} ${url}`);
      if (res.status === 404) return '';
    } catch (e) {
      console.warn(`  error ${e.message} ${url}`);
    }
  }
  return '';
}

const decode = s => s
  .replace(/&amp;/g, '&').replace(/&#039;|&#39;|&apos;/g, "'").replace(/&quot;/g, '"')
  .replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ').trim();
const norm = s => s.normalize('NFD').replace(/[̀-ͯ]/g, '').toLowerCase()
  .replace(/\b(fc|afc|cf|sc|ac|fk|sk|cd|ud|sv|vfl|vfb|tsg|1\.|ss|as|club|de|the)\b/g, ' ')
  .replace(/[^a-z0-9]+/g, ' ').trim();

function parseClubs(html) {
  const re = /href="\/([a-z0-9-]+)\/startseite\/verein\/(\d+)\/saison_id\/\d+"[^>]*>([^<]{2,})<\/a>/g;
  const seen = new Map();
  let m;
  while ((m = re.exec(html))) {
    if (!seen.has(m[2])) seen.set(m[2], { slug: m[1], id: m[2], name: decode(m[3]) });
  }
  // The competition table lists each club with its name as link text; keep those.
  const table = html.slice(html.indexOf('class="items"'));
  const ids = new Set([...table.matchAll(/startseite\/verein\/(\d+)\/saison_id/g)].map(x => x[1]));
  return [...seen.values()].filter(c => ids.has(c.id));
}

function parseValue(text) {
  const m = /€([\d.]+)(bn|m|k)?/i.exec(text || '');
  if (!m) return 0;
  const n = parseFloat(m[1]);
  const unit = (m[2] || '').toLowerCase();
  return unit === 'bn' ? n * 1e9 : unit === 'm' ? n * 1e6 : unit === 'k' ? n * 1e3 : n;
}

function parseSquad(html) {
  const players = [];
  const rows = html.split(/<tr class="(?:odd|even)">/).slice(1);
  for (const row of rows) {
    const name = /class="hauptlink">\s*<a href="\/[^"]+\/profil\/spieler\/\d+">\s*([^<]+?)\s*<\/a>/.exec(row);
    if (!name) continue;
    const pos = /<\/tr>\s*<tr>\s*<td>\s*([^<]+?)\s*<\/td>/.exec(row);
    const dob = /<td class="zentriert">([^<]*?)\((\d+)\)<\/td>/.exec(row);
    const nat = /<img src="[^"]*flagge[^"]*" title="([^"]+)"/.exec(row);
    const foot = /<td class="zentriert">(left|right|both)<\/td>/.exec(row);
    const value = /marktwertverlauf[^>]*>([^<]+)</.exec(row);
    players.push({
      fullName: decode(name[1]),
      position: pos ? decode(pos[1]) : 'Midfield',
      age: dob ? parseInt(dob[2], 10) : null,
      nationality: nat ? decode(nat[1]) : null,
      foot: foot ? foot[1] : null,
      value: value ? parseValue(value[1]) : 0,
    });
  }
  return players;
}

function parseFacts(html) {
  const colours = [...html.matchAll(/background-color:\s*(#[0-9A-Fa-f]{6})/g)].map(m => m[1].toUpperCase());
  const stadium = /Stadium:\s*<span[^>]*>\s*<a[^>]*>([^<]+)<\/a>(?:&nbsp;|\s)*<span class="tabellenplatz">([\d.,]+)\s*Seats/.exec(html);
  const name = /<h1 class="data-header__headline-wrapper[^"]*">\s*([^<]+?)\s*<\/h1>/.exec(html);
  return {
    name: name ? decode(name[1]) : null,
    primary: colours[0] || null,
    secondary: colours.find(c => c !== colours[0]) || null,
    stadium: stadium ? decode(stadium[1]) : null,
    capacity: stadium ? parseInt(stadium[2].replace(/[.,]/g, ''), 10) : null,
  };
}

function ratingFromValue(value) {
  if (!value || value <= 0) return 52;
  const v = Math.max(10_000, Math.min(200_000_000, value));
  return Math.max(40, Math.min(94, Math.round(58 + 6.2 * Math.log(v / 500_000))));
}
function potentialFrom(overall, age) {
  const boost = age <= 19 ? 15 : age <= 21 ? 12 : age <= 24 ? 8 : age <= 27 ? 4 : age <= 30 ? 2 : 0;
  return Math.max(overall, Math.min(95, overall + boost));
}
const median = xs => { const s = [...xs].sort((a, b) => a - b); return s.length ? s[Math.floor(s.length / 2)] : 0; };

function splitName(full) {
  const parts = full.split(' ');
  if (parts.length === 1) return { firstName: '', lastName: parts[0] };
  return { firstName: parts[0], lastName: parts.slice(1).join(' ') };
}

function shortNameFor(name, taken) {
  const words = norm(name).split(' ').filter(w => w.length > 1 && !/^(city|united|town|county|rovers|athletic|wanderers|real|sporting)$/.test(w));
  const base = (words[0] || norm(name).replace(/ /g, '') || 'CLB').toUpperCase();
  const candidates = [base.slice(0, 3)];
  if (words[1]) candidates.push((base[0] + words[1].slice(0, 2)).toUpperCase());
  for (let i = 3; i < base.length; i++) candidates.push((base.slice(0, 2) + base[i]).toUpperCase());
  for (const c of candidates) if (c.length === 3 && !taken.has(c)) { taken.add(c); return c; }
  for (let n = 2; n < 99; n++) { const c = base.slice(0, 2) + n; if (!taken.has(c)) { taken.add(c); return c; } }
  return base.slice(0, 3);
}

function loadOld(raw) {
  const file = path.join(OUT, `tier${raw}.json`);
  if (!fs.existsSync(file)) return null;
  return JSON.parse(fs.readFileSync(file, 'utf8'));
}

(async () => {
  const only = new Set(process.argv.slice(2));
  const leagues = only.size ? LEAGUES.filter(l => only.has(l.code)) : LEAGUES;
  // Every club already shipped, so metadata (colours, short names, stadiums)
  // survives promotion and relegation between English tiers.
  const oldClubs = new Map();
  const oldPlayers = new Map();
  for (const l of LEAGUES) {
    const old = loadOld(l.raw);
    for (const c of old?.clubs || []) {
      oldClubs.set(norm(c.name), c);
      for (const p of c.players || []) oldPlayers.set(norm(`${p.firstName} ${p.lastName}`), p);
    }
  }

  let totalPlayers = 0;
  for (const league of leagues) {
    let html = await get(`${HOST}/${league.slug}/startseite/wettbewerb/${league.code}/saison_id/${SEASON_ID}`);
    let clubs = parseClubs(html);
    if (clubs.length < 8) {
      html = await get(`${HOST}/${league.slug}/startseite/wettbewerb/${league.code}/saison_id/${Number(SEASON_ID) - 1}`);
      clubs = parseClubs(html);
    }
    if (clubs.length < 8) { console.warn(`skip ${league.code}: no clubs found`); continue; }
    console.log(`${league.code} ${league.name}: ${clubs.length} clubs`);

    const old = loadOld(league.raw);
    const oldMedian = old ? median(old.clubs.flatMap(c => c.players.map(p => p.overall))) : null;
    const taken = new Set();
    const built = [];

    for (const club of clubs) {
      const squadHtml = await get(`${HOST}/${club.slug}/kader/verein/${club.id}/saison_id/${SEASON_ID}/plus/1`);
      const factsHtml = await get(`${HOST}/${club.slug}/datenfakten/verein/${club.id}`);
      const facts = parseFacts(factsHtml);
      const squad = parseSquad(squadHtml)
        .sort((a, b) => b.value - a.value)
        .slice(0, 30);
      if (squad.length < 14) { console.warn(`  thin squad ${club.name} (${squad.length})`); }
      let name = facts.name || club.name;
      const prev = oldClubs.get(norm(name)) || oldClubs.get(norm(club.name));
      if (prev) name = prev.name;
      else if (league.country === 'England' || league.country === 'Scotland') name = name.replace(/\s+A?FC$/, '');
      const totalValue = squad.reduce((s, p) => s + p.value, 0);

      const players = squad.map(p => {
        const code = POS[p.position] || 'CM';
        const age = p.age || 25;
        const overall = ratingFromValue(p.value);
        const { firstName, lastName } = splitName(p.fullName);
        const o = {
          firstName, lastName,
          nationality: p.nationality || league.country,
          age,
          positions: [code, ...SECONDARY[code]].slice(0, 2),
          overall,
          potential: potentialFrom(overall, age),
        };
        if (p.foot === 'left' || p.foot === 'right') o.preferredFoot = p.foot;
        const known = oldPlayers.get(norm(p.fullName));
        if (known?.specialties) o.specialties = known.specialties;
        return o;
      });

      built.push({
        name,
        shortName: prev?.shortName && !taken.has(prev.shortName) ? (taken.add(prev.shortName), prev.shortName) : shortNameFor(name, taken),
        stadium: (prev && prev.stadium) || facts.stadium || `${name} Stadium`,
        stadiumCapacity: facts.capacity || prev?.stadiumCapacity || 10000,
        city: prev?.city || name.replace(/\b(FC|AFC|SC|CF|AC|United|City|Town|County|Rovers|Athletic|Wanderers|Albion)\b/g, '').replace(/\s+/g, ' ').trim() || name,
        primaryColor: (prev && prev.primaryColor !== '#1B5E20' && prev.primaryColor) || facts.primary || '#2F5BEA',
        secondaryColor: (prev && prev.primaryColor !== '#1B5E20' && prev.secondaryColor) || facts.secondary || '#FFFFFF',
        reputation: Math.max(35, Math.min(97, Math.round(40 + 18 * Math.log10(Math.max(1, totalValue / 1e6))))),
        manager: prev?.manager || 'Head Coach',
        budget: 0,
        wageBudget: 0,
        players,
      });
    }

    // Calibrate to the previously shipped league strength.
    const newMedian = median(built.flatMap(c => c.players.map(p => p.overall)));
    const shift = oldMedian ? Math.max(-8, Math.min(8, oldMedian - newMedian)) : 0;
    for (const c of built) for (const p of c.players) {
      p.overall = Math.max(38, Math.min(94, p.overall + shift));
      p.potential = Math.max(p.overall, Math.min(95, p.potential + shift));
    }
    totalPlayers += built.reduce((s, c) => s + c.players.length, 0);
    fs.writeFileSync(path.join(OUT, `tier${league.raw}.json`),
      JSON.stringify({ name: league.name, season: SEASON_LABEL, tier: league.raw, clubs: built }));
    console.log(`  wrote tier${league.raw}.json (median ${newMedian} shifted ${shift >= 0 ? '+' : ''}${shift})`);
  }
  console.log(`done: ${totalPlayers} players`);
})();
