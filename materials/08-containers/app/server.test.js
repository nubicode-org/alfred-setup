const { test } = require('node:test');
const assert = require('node:assert');
const { spawn } = require('node:child_process');

test('answers /healthz and the greeting', async (t) => {
  const port = 18080 + Math.floor(Math.random() * 1000);
  const child = spawn(process.execPath, ['server.js'], {
    cwd: __dirname,
    env: { ...process.env, PORT: String(port), GREETING: 'test greeting' },
  });
  t.after(() => child.kill('SIGTERM'));
  await new Promise((resolve) => child.stdout.once('data', resolve));

  const health = await fetch(`http://127.0.0.1:${port}/healthz`);
  assert.strictEqual(health.status, 200);

  const body = await (await fetch(`http://127.0.0.1:${port}/`)).json();
  assert.strictEqual(body.greeting, 'test greeting');
});
