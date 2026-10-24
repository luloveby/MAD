// Read-only production checks and isolated Rules API tests. No database writes.
const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');
const cli = createRequire(path.join(process.env.APPDATA, 'npm/node_modules/firebase-tools/package.json'));
const auth = cli('./lib/auth.js');
const project = 'borrowit-5e6c3';
async function main() {
  const account = auth.getProjectDefaultAccount(process.cwd());
  if (!account) throw new Error('Firebase CLI login is required.');
  const tokens = await auth.getAccessToken(account.tokens.refresh_token, ['https://www.googleapis.com/auth/cloud-platform', 'https://www.googleapis.com/auth/firebase']);
  async function api(url, body) {
    const response = await fetch(url, {
      method: body ? 'POST' : 'GET',
      headers: { Authorization: `Bearer ${tokens.access_token}`, 'Content-Type': 'application/json' },
      body: body ? JSON.stringify(body) : undefined,
      signal: AbortSignal.timeout(45000),
    });
    const data = await response.json();
    if (!response.ok) throw new Error(data.error?.message || `HTTP ${response.status}`);
    return data;
  }
  const release = await api(`https://firebaserules.googleapis.com/v1/projects/${project}/releases/cloud.firestore`);
  const ruleset = await api(`https://firebaserules.googleapis.com/v1/${release.rulesetName}`);
  const source = ruleset.source;
  const normalize = s => s.replace(/\r\n/g, '\n').trim();
  const rulesMatch = source.files.some(f => normalize(f.content) === normalize(fs.readFileSync('firestore.rules', 'utf8')));
  const root = `https://firestore.googleapis.com/v1/projects/${project}/databases/(default)/documents`;
  const page = await api(`${root}/requests?pageSize=1`);
  const sample = page.documents?.[0];
  let queryWorks = false;
  if (sample?.fields?.uid?.stringValue) {
    await api(`${root}:runQuery`, { structuredQuery: {
      from: [{ collectionId: 'requests' }],
      where: { fieldFilter: { field: { fieldPath: 'uid' }, op: 'EQUAL', value: { stringValue: sample.fields.uid.stringValue } } },
      limit: 1,
    } });
    queryWorks = true;
  } else {
    await api(`${root}:runQuery`, { structuredQuery: {
      from: [{ collectionId: 'requests' }],
      where: { fieldFilter: { field: { fieldPath: 'uid' }, op: 'EQUAL', value: { stringValue: '__connection_check_no_user__' } } },
      limit: 1,
    } });
    queryWorks = true;
  }
  const base = { uid: 'request-check-owner', status: 'Returned', archived: false };
  const cases = [
    ['get', 'request-check-owner', 'ALLOW', base, base],
    ['get', 'request-check-other', 'DENY', base, base],
    ['get', null, 'DENY', base, base],
    ['update', 'request-check-other', 'DENY', { ...base, archived: true }, base],
    ['update', 'request-check-owner', 'DENY', { ...base, archived: true }, { ...base, status: 'Borrowed' }],
    ['update', 'request-check-owner', 'DENY', { ...base, status: 'Returned' }, { ...base, status: 'Borrowed' }],
  ].map(([method, uid, expectation, data, previous]) => ({
    expectation,
    request: { path: '/databases/(default)/documents/requests/connection-check', method,
      auth: uid ? { uid, token: {} } : null,
      time: '2026-10-18T00:00:00Z', resource: { data } },
    resource: { data: previous },
  }));
  const tests = await api(`https://firebaserules.googleapis.com/v1/projects/${project}:test`, { source, testSuite: { testCases: cases } });
  const states = (tests.testResults || []).map(r => r.state);
  console.log(JSON.stringify({ project, deployedRulesMatch: rulesMatch, userQueryWorks: queryWorks, existingRequestsPresent: !!sample, liveRulesTests: states, issues: tests.issues || [] }, null, 2));
  if (!rulesMatch || states.length !== cases.length || states.some(s => s !== 'SUCCESS')) throw new Error('Firebase verification needs attention.');
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
