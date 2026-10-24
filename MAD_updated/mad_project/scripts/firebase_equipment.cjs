// Uses the existing Firebase CLI login. Tokens are never printed or saved here.
const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');
const cliPath = process.env.FIREBASE_TOOLS_PATH || path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/package.json');
const cliRequire = createRequire(cliPath);
const auth = cliRequire('./lib/auth.js');
const project = 'borrowit-5e6c3';
const root = `projects/${project}/databases/(default)/documents`;
const mode = process.argv[2] || 'inspect';

async function main() {
  const account = auth.getProjectDefaultAccount(process.cwd());
  if (!account) throw new Error('Run firebase login first.');
  const tokens = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/firebase']);
  async function api(url, method = 'GET', body) {
    const response = await fetch(url, {
      method,
      headers: { Authorization: `Bearer ${tokens.access_token}`, 'Content-Type': 'application/json' },
      body: body === undefined ? undefined : JSON.stringify(body),
      signal: AbortSignal.timeout(45000),
    });
    const data = await response.json();
    if (!response.ok) throw new Error(`${method} ${new URL(url).pathname}: ${data.error?.message || response.status}`);
    return data;
  }
  async function documents() {
    let result = [], pageToken;
    do {
      const url = new URL(`https://firestore.googleapis.com/v1/${root}/equipment`);
      url.searchParams.set('pageSize', '300');
      if (pageToken) url.searchParams.set('pageToken', pageToken);
      const page = await api(url);
      result.push(...(page.documents || []));
      pageToken = page.nextPageToken;
    } while (pageToken);
    return result;
  }
  const existing = await documents();
  if (mode === 'inspect') {
    const database = await api(`https://firestore.googleapis.com/v1/projects/${project}/databases/(default)`);
    const release = await api(`https://firebaserules.googleapis.com/v1/projects/${project}/releases/cloud.firestore`);
    const ruleset = await api(`https://firebaserules.googleapis.com/v1/${release.rulesetName}`);
    fs.mkdirSync('firebase-backups', { recursive: true });
    const stamp = new Date().toISOString().replace(/[:.]/g, '-');
    const backup = `firebase-backups/${stamp}`;
    fs.writeFileSync(`${backup}-rules.json`, JSON.stringify(ruleset, null, 2));
    fs.writeFileSync(`${backup}-equipment.json`, JSON.stringify(existing, null, 2));
    fs.writeFileSync('firebase-backups/current.rules', ruleset.source.files.map(f => f.content).join('\n'));
    console.log(JSON.stringify({ project, location: database.locationId, equipmentCount: existing.length, equipmentIds: existing.map(d => d.name.split('/').pop()), backup, liveRules: ruleset.source.files.map(f => f.content).join('\n') }, null, 2));
  } else if (mode === 'test-rules') {
    const seed = JSON.parse(fs.readFileSync('scripts/equipment_seed.json', 'utf8'))[0];
    const { id, ...record } = seed;
    const student = { uid: 'rules-test-student', token: {} };
    const admin = { uid: 'rules-test-admin', token: { admin: true } };
    const test = (method, auth, expectation, data = record) => ({
      expectation,
      request: { path: '/databases/(default)/documents/equipment/EQ-001', method, auth,
        resource: { data }, time: new Date().toISOString() },
      resource: { data: record },
    });
    const testCases = [
      test('get', student, 'ALLOW'), test('get', null, 'DENY'),
      test('create', student, 'DENY'), test('update', student, 'DENY'),
      test('delete', student, 'DENY'), test('create', admin, 'ALLOW'),
      test('update', admin, 'ALLOW', { ...record, inventoryVerified: true, totalQuantity: 3, availableQuantity: 2 }),
      test('update', admin, 'DENY', { ...record, inventoryVerified: true, totalQuantity: 1, availableQuantity: 2 }),
      test('delete', admin, 'ALLOW'),
    ];
    const result = await api(`https://firebaserules.googleapis.com/v1/projects/${project}:test`, 'POST', {
      source: { files: [{ name: 'firestore.rules', content: fs.readFileSync('firestore.rules', 'utf8') }] },
      testSuite: { testCases },
    });
    const issues = result.issues || [];
    const states = (result.testResults || []).map(r => r.state);
    console.log(JSON.stringify({ issues, states, results: result.testResults?.map(r => ({state:r.state, error:r.error, debugMessages:r.debugMessages})) }, null, 2));
    if (issues.some(i => i.severity === 'ERROR') || states.length !== testCases.length || states.some(s => s !== 'SUCCESS')) {
      throw new Error('Rules checks did not all pass.');
    }
  } else if (mode === 'import') {
    const records = JSON.parse(fs.readFileSync('scripts/equipment_seed.json', 'utf8'));
    const ids = new Set(existing.map(d => d.name.split('/').pop()));
    const writes = records.filter(item => !ids.has(item.id)).map(({ id, ...data }) => ({
      update: { name: `${root}/equipment/${id}`, fields: fields(data) },
      currentDocument: { exists: false },
      updateTransforms: [{ fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' }, { fieldPath: 'updatedAt', setToServerValue: 'REQUEST_TIME' }],
    }));
    if (writes.length) await api(`https://firestore.googleapis.com/v1/${root}:commit`, 'POST', { writes });
    console.log(JSON.stringify({ created: writes.length, skippedExistingIds: records.length - writes.length, totalEquipment: (await documents()).length }));
  } else if (mode === 'verify') {
    const records = JSON.parse(fs.readFileSync('scripts/equipment_seed.json', 'utf8'));
    const ids = new Set(existing.map(d => d.name.split('/').pop()));
    const missing = records.filter(d => !ids.has(d.id)).map(d => d.id);
    if (missing.length) throw new Error(`Missing equipment: ${missing.join(', ')}`);
    for (const record of records) {
      const actual = existing.find(d => d.name.endsWith(`/equipment/${record.id}`));
      for (const key of ['name', 'category', 'imagePath', 'description']) {
        if (actual.fields[key]?.stringValue !== record[key]) throw new Error(`Field mismatch: ${record.id}.${key}`);
      }
    }
    const release = await api(`https://firebaserules.googleapis.com/v1/projects/${project}/releases/cloud.firestore`);
    const ruleset = await api(`https://firebaserules.googleapis.com/v1/${release.rulesetName}`);
    const normalize = text => text.replace(/\r\n/g, '\n').trim();
    const rulesMatch = ruleset.source.files.some(f => normalize(f.content) === normalize(fs.readFileSync('firestore.rules', 'utf8')));
    if (!rulesMatch) throw new Error('Live rules differ from the tested local rules.');
    const anonymous = await fetch(`https://firestore.googleapis.com/v1/${root}/equipment/EQ-001`, { signal: AbortSignal.timeout(45000) });
    if (anonymous.status !== 403) throw new Error(`Expected anonymous read to be denied, got ${anonymous.status}.`);
    const authConfig = await api(`https://identitytoolkit.googleapis.com/admin/v2/projects/${project}/config`);
    console.log(JSON.stringify({ verifiedImportedRecords: records.length, totalEquipment: existing.length,
      deployedRulesMatch: rulesMatch, anonymousReadDenied: true, emailPasswordEnabled: authConfig.signIn?.email?.enabled === true }));
  } else throw new Error('Supported modes: inspect, test-rules, import, verify');
}
function value(v) {
  if (v === null) return { nullValue: null };
  if (typeof v === 'boolean') return { booleanValue: v };
  if (typeof v === 'number') return { integerValue: String(v) };
  if (Array.isArray(v)) return { arrayValue: { values: v.map(value) } };
  return { stringValue: v };
}
function fields(data) { return Object.fromEntries(Object.entries(data).map(([key, v]) => [key, value(v)])); }
main().catch(error => { console.error(error.message); process.exitCode = 1; });
