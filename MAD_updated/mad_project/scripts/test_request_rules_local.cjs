// Isolated emulator-only integration test. Never contacts production Firebase.
const assert = require('node:assert/strict');
const project = 'demo-borrowit';
const root = `http://127.0.0.1:8089/v1/projects/${project}/databases/(default)/documents`;
const now = Math.floor(Date.now() / 1000);
const encode = value => Buffer.from(JSON.stringify(value)).toString('base64url');
const token = `${encode({ alg: 'none', typ: 'JWT' })}.${encode({
  iss: `https://securetoken.google.com/${project}`, aud: project,
  sub: 'rules-student', user_id: 'rules-student', iat: now, exp: now + 3600,
  firebase: { sign_in_provider: 'custom', identities: {} },
})}.`;
async function api(path, body, admin = false) {
  const response = await fetch(root + path, {
    method: body ? 'POST' : 'GET',
    headers: { Authorization: `Bearer ${admin ? 'owner' : token}`, 'Content-Type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  });
  const result = await response.json();
  return { status: response.status, body: result };
}
const s = value => ({ stringValue: value });
const n = value => ({ integerValue: String(value) });
async function main() {
  await fetch(`http://127.0.0.1:8089/emulator/v1/projects/${project}/databases/(default)/documents`, { method: 'DELETE' });
  const prefix = `projects/${project}/databases/(default)/documents`;
  assert.equal((await api(':commit', { writes: [{ update: {
    name: `${prefix}/equipment/laptop`, fields: {
      name: s('Laptop'), isActive: { booleanValue: true }, inventoryVerified: { booleanValue: true }, availableQuantity: n(2),
    },
  } }] }, true)).status, 200);
  const counterRead = await api('/counters/requests');
  console.log('Authenticated read of missing counter:', counterRead.status);
  assert.equal(counterRead.status, 404);
  for (let number = 1; number <= 2; number++) {
    const id = `BIT-${String(number).padStart(4, '0')}`;
    const result = await api(':commit', { writes: [
      { update: { name: `${prefix}/counters/requests`, fields: { lastNumber: n(number), lastRequestId: s(id) } } },
      { update: { name: `${prefix}/requests/${id}`, fields: {
        uid: s('rules-student'), equipmentId: s('laptop'), equipmentName: s('Laptop'), status: s('Approved'), purpose: s('Class presentation'),
        borrowAt: { timestampValue: new Date(Date.now() + 86400000).toISOString() },
        returnAt: { timestampValue: new Date(Date.now() + 172800000).toISOString() }, archived: { booleanValue: false },
      } }, updateTransforms: [
        { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
        { fieldPath: 'approvedAt', setToServerValue: 'REQUEST_TIME' },
      ] },
    ] });
    console.log(id, JSON.stringify(result));
    assert.equal(result.status, 200);
  }
  console.log('Both numbered request writes passed the actual Firestore rules.');
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });
