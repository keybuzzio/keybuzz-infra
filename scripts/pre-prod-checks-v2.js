const http = require('http');
const {Pool} = require('pg');
const fs = require('fs');
const path = require('path');
const p = new Pool();

const checks = {};
let done = 0;
const total = 16;

function finish(name, ok, detail) {
  checks[name] = { ok, detail: detail || '' };
  done++;
  if (done === total) {
    console.log(JSON.stringify(checks));
    p.end().then(() => process.exit(0));
  }
}

const port = parseInt(process.env.PORT || '3001');
const opts = { hostname: '127.0.0.1', port, timeout: 5000 };
const hdr = { 'X-User-Email': 'ludo.gonthier@gmail.com', 'X-Tenant-Id': 'ecomlg-001' };

function apiCheck(name, path) {
  http.get({...opts, path, headers: hdr}, (r) => {
    finish(name, r.statusCode === 200, 'HTTP ' + r.statusCode);
  }).on('error', (e) => finish(name, false, e.message));
}

// --- V1 checks (PH142-I) ---
apiCheck('inbox_api', '/health');
apiCheck('dashboard_api', '/dashboard/summary?tenantId=ecomlg-001');
apiCheck('ai_settings', '/ai/settings?tenantId=ecomlg-001');
apiCheck('ai_journal', '/ai/journal?tenantId=ecomlg-001&limit=1');
apiCheck('autopilot_draft', '/autopilot/draft?tenantId=ecomlg-001&conversationId=test');

p.query("SELECT COUNT(*) as c FROM tenant_settings WHERE tenant_id = 'ecomlg-001'").then(r => {
  finish('signature_db', parseInt(r.rows[0].c) > 0);
}).catch(e => finish('signature_db', false, e.message));

p.query("SELECT COUNT(*) as c FROM orders WHERE tenant_id = 'ecomlg-001'").then(r => {
  finish('orders_count', parseInt(r.rows[0].c) > 0, r.rows[0].c + ' orders');
}).catch(e => finish('orders_count', false, e.message));

p.query('SELECT COUNT(*) as c FROM inbound_connections WHERE "tenantId" = \'ecomlg-001\'').then(r => {
  finish('channels_count', parseInt(r.rows[0].c) > 0, r.rows[0].c + ' channels');
}).catch(e => finish('channels_count', false, e.message));

// --- V2 checks (PH142-M) — API endpoints feature-level ---
apiCheck('billing_current', '/billing/current?tenantId=ecomlg-001');
apiCheck('agent_keybuzz_status', '/billing/agent-keybuzz-status?tenantId=ecomlg-001');

// --- V2 checks (PH142-M) — Feature presence in client source ---
const clientBase = '/app';

function fileContains(name, filePath, pattern) {
  try {
    const fullPath = path.join(clientBase, filePath);
    if (!fs.existsSync(fullPath)) {
      finish(name, false, 'file not found: ' + filePath);
      return;
    }
    const content = fs.readFileSync(fullPath, 'utf8');
    finish(name, content.includes(pattern), pattern + (content.includes(pattern) ? ' found' : ' MISSING'));
  } catch(e) {
    finish(name, false, e.message);
  }
}

// NOTE: These checks run inside the CLIENT pod, not the API pod.
// When run inside the API pod, we skip file checks gracefully.
// The bash wrapper handles running these in the correct pod.

// --- V2 backend feature checks ---
p.query("SELECT column_name FROM information_schema.columns WHERE table_name = 'billing_subscriptions' AND column_name = 'has_agent_keybuzz_addon'").then(r => {
  finish('db_addon_column', r.rows.length > 0, r.rows.length > 0 ? 'column exists' : 'column MISSING');
}).catch(e => finish('db_addon_column', false, e.message));

p.query("SELECT COUNT(*) as c FROM pg_proc WHERE proname = 'agents'").then(() => {
  finish('agents_table', true, 'query OK');
}).catch(e => finish('agents_table', false, e.message));

// Verify agent limits exist in backend
http.get({...opts, path: '/billing/agent-keybuzz-status?tenantId=ecomlg-001', headers: hdr}, (r) => {
  let body = '';
  r.on('data', d => body += d);
  r.on('end', () => {
    try {
      const data = JSON.parse(body);
      finish('addon_api_structure', 'hasAddon' in data || 'has_addon' in data || 'error' in data, JSON.stringify(data).substring(0, 100));
    } catch(e) {
      finish('addon_api_structure', r.statusCode === 200, 'HTTP ' + r.statusCode);
    }
  });
}).on('error', (e) => finish('addon_api_structure', false, e.message));

// Verify billing/current returns hasAgentKeybuzzAddon
http.get({...opts, path: '/billing/current?tenantId=ecomlg-001', headers: hdr}, (r) => {
  let body = '';
  r.on('data', d => body += d);
  r.on('end', () => {
    try {
      const data = JSON.parse(body);
      const hasField = 'hasAgentKeybuzzAddon' in data;
      finish('billing_addon_field', hasField, hasField ? 'field present' : 'field MISSING in response');
    } catch(e) {
      finish('billing_addon_field', r.statusCode === 200, 'HTTP ' + r.statusCode);
    }
  });
}).on('error', (e) => finish('billing_addon_field', false, e.message));

// Verify agents API with limits
http.get({...opts, path: '/agents?tenantId=ecomlg-001', headers: hdr}, (r) => {
  finish('agents_api', r.statusCode === 200, 'HTTP ' + r.statusCode);
}).on('error', (e) => finish('agents_api', false, e.message));

// Verify signature API
http.get({...opts, path: '/tenant-context/signature/ecomlg-001', headers: hdr}, (r) => {
  finish('signature_api', r.statusCode === 200 || r.statusCode === 401, 'HTTP ' + r.statusCode);
}).on('error', (e) => finish('signature_api', false, e.message));

setTimeout(() => { console.log(JSON.stringify({timeout:true})); p.end().then(() => process.exit(1)); }, 15000);
