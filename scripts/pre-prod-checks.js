const http = require('http');
const {Pool} = require('pg');
const p = new Pool();

const checks = {};
let done = 0;
const total = 8;

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

setTimeout(() => { console.log(JSON.stringify({timeout:true})); p.end().then(() => process.exit(1)); }, 10000);
