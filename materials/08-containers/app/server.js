// A tiny web service with no dependencies, so the Dockerfile is about containers rather than npm.
const http = require('node:http');
const os = require('node:os');

const port = Number(process.env.PORT || 8080);
const greeting = process.env.GREETING || 'Hello from a container';
const started = new Date();

const server = http.createServer((req, res) => {
  if (req.url === '/healthz') {
    res.writeHead(200, { 'content-type': 'text/plain' });
    res.end('ok\n');
    return;
  }
  res.writeHead(200, { 'content-type': 'application/json' });
  res.end(JSON.stringify({ greeting, hostname: os.hostname(), started }) + '\n');
});

server.listen(port, () => console.log(`listening on ${port}`));

// A container is stopped with SIGTERM. Exit cleanly instead of waiting to be killed ten seconds later.
process.on('SIGTERM', () => server.close(() => process.exit(0)));
