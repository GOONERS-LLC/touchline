// Publishes the latest Touchline release IPA to the Gooners LLC website.
//
//   node tools/publish-website.js [path-to-goonersLLC-clone]
//
// Downloads the newest release's Touchline.ipa (verified against the release
// manifest's SHA-256), stores it as downloads/touchline/Touchline-<version>.ipa,
// removes older Touchline IPAs, updates the Touchline card's version and link
// in index.html, writes downloads/touchline/latest.json, then commits and pushes.
// Run this after every release.
const { execFileSync } = require('child_process');
const crypto = require('crypto');
const fs = require('fs');
const os = require('os');
const path = require('path');

const REPO = 'GOONERS-LLC/touchline';
const SITE_REPO = 'GOONERS-LLC/goonersLLC';
const run = (cmd, args, opts = {}) => execFileSync(cmd, args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'inherit'], ...opts }).trim();

const site = path.resolve(process.argv[2] || path.join(os.tmpdir(), 'goonersLLC-site'));
if (!fs.existsSync(path.join(site, '.git'))) run('gh', ['repo', 'clone', SITE_REPO, site]);
run('git', ['-C', site, 'pull', '--ff-only']);

const release = JSON.parse(run('gh', ['release', 'view', '-R', REPO, '--json', 'tagName']));
const version = release.tagName.replace(/^v/, '');
const work = fs.mkdtempSync(path.join(os.tmpdir(), 'touchline-ipa-'));
run('gh', ['release', 'download', release.tagName, '-R', REPO, '-p', 'Touchline.ipa', '-p', 'release-manifest.json', '-D', work]);

const ipa = fs.readFileSync(path.join(work, 'Touchline.ipa'));
const manifest = JSON.parse(fs.readFileSync(path.join(work, 'release-manifest.json'), 'utf8'));
const sha = crypto.createHash('sha256').update(ipa).digest('hex');
if (sha !== manifest.sha256) throw new Error(`Checksum mismatch: ${sha} vs ${manifest.sha256}`);

const dir = path.join(site, 'downloads', 'touchline');
fs.mkdirSync(dir, { recursive: true });
for (const f of fs.readdirSync(dir)) if (/^Touchline-.*\.ipa$/.test(f)) fs.rmSync(path.join(dir, f));
const fileName = `Touchline-${version}.ipa`;
fs.writeFileSync(path.join(dir, fileName), ipa);
fs.writeFileSync(path.join(dir, 'latest.json'), JSON.stringify({ version, file: fileName, sha256: sha, size: ipa.length }, null, 2) + '\n');

const indexPath = path.join(site, 'index.html');
let html = fs.readFileSync(indexPath, 'utf8');
const before = html;
html = html.replace(/downloads\/touchline\/Touchline-[\d.]+\.ipa/g, `downloads/touchline/${fileName}`);
html = html.replace(/(id="touchline"[\s\S]*?<p class="app-meta">)Version [\d.]+/, `$1Version ${version}`);
const mb = (ipa.length / 1048576).toFixed(0);
html = html.replace(/(id="touchline"[\s\S]*?iOS and iPadOS 17 or newer &middot; )(\d+ MB &middot; )?/, `$1${mb} MB &middot; `);
if (html === before && !before.includes(fileName)) throw new Error('Touchline card not found in index.html');
fs.writeFileSync(indexPath, html);

run('git', ['-C', site, 'add', 'index.html', 'downloads/touchline']);
const status = run('git', ['-C', site, 'status', '--porcelain']);
if (!status) { console.log(`Website already on Touchline ${version}`); process.exit(0); }
run('git', ['-C', site, 'commit', '-m', `Update Touchline download to version ${version}`]);
run('git', ['-C', site, '-c', 'credential.helper=', '-c', 'credential.helper=!gh auth git-credential', 'push']);
console.log(`Website updated to Touchline ${version} (${mb} MB)`);
