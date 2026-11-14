import { createServer } from 'node:http';
import { createHash, randomUUID, timingSafeEqual } from 'node:crypto';

const key = process.env.C5_API_KEY;
if (!key || key.length < 24) {
  throw new Error('Set C5_API_KEY to a random value of at least 24 characters');
}

const digest = (value) => createHash('sha256').update(value).digest();
const expected = digest(key);
const endpoint = '/a2a';
const maxBodyBytes = 64 * 1024;
const testCode = /^(?:生成回执|回执)\s+([A-Za-z0-9-]{6,32})$/;

function json(response, status, value) {
  response.writeHead(status, { 'Content-Type': 'application/json; charset=utf-8' });
  response.end(JSON.stringify(value));
}

function rpcError(response, id, code, message) {
  json(response, 200, { jsonrpc: '2.0', id, error: { code, message } });
}

async function handle(request, response) {
  if (request.url !== endpoint) {
    json(response, 404, { error: 'Not found' });
    return;
  }
  const authorization = request.headers.authorization ?? '';
  const apiKey = request.headers['x-api-key'];
  const credential = typeof apiKey === 'string' ? apiKey : authorization.replace(/^Bearer\s+/i, '');
  if (!timingSafeEqual(digest(credential), expected)) {
    console.log(JSON.stringify({
      event: 'auth_rejected', time: new Date().toISOString(), method: request.method,
      authorizationPresent: Boolean(authorization), apiKeyPresent: typeof apiKey === 'string',
      credentialLength: credential.length
    }));
    json(response, 401, { error: 'Unauthorized' });
    return;
  }
  if (request.method === 'GET') {
    console.log(JSON.stringify({ event: 'auth_probe_ok', time: new Date().toISOString() }));
    json(response, 200, { status: 'ready' });
    return;
  }
  if (request.method !== 'POST') {
    response.setHeader('Allow', 'GET, POST');
    json(response, 405, { error: 'Method not allowed' });
    return;
  }

  let size = 0;
  const chunks = [];
  for await (const chunk of request) {
    size += chunk.length;
    if (size > maxBodyBytes) {
      json(response, 413, { error: 'Request too large' });
      return;
    }
    chunks.push(chunk);
  }
  let message;
  try {
    message = JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    rpcError(response, null, -32700, 'Parse error');
    return;
  }

  const id = message?.id;
  if (message?.jsonrpc !== '2.0' || typeof id !== 'string' || typeof message.method !== 'string') {
    rpcError(response, null, -32600, 'Invalid request');
    return;
  }
  if (message.method !== 'message/stream') {
    rpcError(response, id, -32601, 'Method not found');
    return;
  }

  const taskId = message.params?.id;
  const parts = message.params?.message?.parts;
  if (typeof taskId !== 'string' || !taskId || !Array.isArray(parts)) {
    rpcError(response, id, -32602, 'Invalid params');
    return;
  }
  const input = parts.filter(part => part?.kind === 'text' && typeof part.text === 'string')
    .map(part => part.text).join(' ').trim();
  const code = testCode.exec(input)?.[1];
  const receipt = code ? randomUUID() : undefined;
  const reply = receipt ? `${code} ${receipt}` : '请输入「生成回执」及一个 6 到 32 位的测试码。';

  console.log(JSON.stringify({ event: 'message_received', time: new Date().toISOString(), id, taskId }));
  response.writeHead(200, {
    'Content-Type': 'text/event-stream; charset=utf-8',
    'Cache-Control': 'no-cache',
    'X-Accel-Buffering': 'no'
  });
  const result = {
    taskId,
    kind: 'artifact-update',
    append: false,
    lastChunk: true,
    final: true,
    artifact: {
      artifactId: randomUUID(),
      parts: [{ kind: 'text', text: reply }]
    }
  };
  response.end(`data: ${JSON.stringify({ jsonrpc: '2.0', id, result })}\n\n`, () => {
    console.log(JSON.stringify({ event: 'response_sent', time: new Date().toISOString(), id, taskId, code, receipt }));
  });
}

const server = createServer((request, response) => {
  handle(request, response).catch(() => {
    if (!response.headersSent) {
      json(response, 500, { error: 'Internal error' });
    } else {
      response.destroy();
    }
  });
});

server.listen(Number(process.env.PORT ?? 8787), process.env.C5_BIND ?? '127.0.0.1', () => {
  console.log(JSON.stringify({ event: 'listening', address: server.address() }));
});
