import assert from 'node:assert/strict';
import { afterEach, test } from 'node:test';
import worker from '../worker.js';

const WORKER_URL = 'https://taipei-api-proxy.example.workers.dev/open-api/zh-tw/Attractions/All?page=1';
const ALLOWED = 'https://travel-audio-guide-flutter.web.app';
const LOCAL = 'http://localhost:57748';
const originalFetch = globalThis.fetch;
afterEach(() => { globalThis.fetch = originalFetch; });

function request(method = 'GET', origin = ALLOWED, headers = {}) {
  return new Request(WORKER_URL, {
    method, headers: { ...(origin ? { Origin: origin } : {}), ...headers },
  });
}

const prod = { ALLOW_LOCALHOST: 'false' };
const dev = { ALLOW_LOCALHOST: 'true' };

test('GET forwards only safe headers and returns readable CORS response', async () => {
  let called = false;
  globalThis.fetch = async (url, options) => {
    called = true;
    assert.equal(url, 'https://www.travel.taipei/open-api/zh-tw/Attractions/All?page=1');
    assert.deepEqual(options.headers, {
      accept: 'application/json',
      'user-agent': 'TravelAudioGuideWebProxy/1.0',
    });
    assert.equal(options.redirect, 'manual');
    return new Response('{"data":[]}', { status: 200, headers: { 'content-type': 'application/json' } });
  };
  const response = await worker.fetch(request('GET', ALLOWED, { Authorization: 'Bearer SECRET', 'Sentry-Trace': 'x' }), prod);
  assert.equal(response.status, 200);
  assert.equal(response.headers.get('Access-Control-Allow-Origin'), ALLOWED);
  assert.equal(response.headers.get('Vary'), 'Origin');
  assert.equal(await response.text(), '{"data":[]}');
  assert.ok(called);
});

test('valid GET preflight admits known headers', async () => {
  const response = await worker.fetch(request('OPTIONS', ALLOWED, {
    'Access-Control-Request-Method': 'GET',
    'Access-Control-Request-Headers': 'content-type, sentry-trace, baggage',
  }), prod);
  assert.equal(response.status, 204);
  assert.match(response.headers.get('Access-Control-Allow-Headers'), /sentry-trace/);
  assert.equal(response.headers.get('Access-Control-Allow-Methods'), 'GET');
});

test('unknown preflight header is denied', async () => {
  const response = await worker.fetch(request('OPTIONS', ALLOWED, {
    'Access-Control-Request-Method': 'GET',
    'Access-Control-Request-Headers': 'x-unexpected-secret',
  }), prod);
  assert.equal(response.status, 403);
});

test('wrong preflight method is denied', async () => {
  const response = await worker.fetch(request('OPTIONS', ALLOWED, {
    'Access-Control-Request-Method': 'POST',
  }), prod);
  assert.equal(response.status, 405);
});

test('refuses unknown origin, missing origin, and localhost in production', async () => {
  for (const origin of ['https://evil.example', null, LOCAL]) {
    assert.equal((await worker.fetch(request('GET', origin), prod)).status, 403);
  }
});

test('allows localhost only in dev and staging preview origin', async () => {
  globalThis.fetch = async () => new Response('{}', { status: 200 });
  assert.equal((await worker.fetch(request('GET', LOCAL), dev)).status, 200);
  assert.equal((await worker.fetch(request('GET', 'https://travel-audio-guide-flutter--staging-123abc.web.app'), prod)).status, 200);
  assert.equal((await worker.fetch(request('GET', 'https://travel-audio-guide-flutter--other-123abc.web.app'), prod)).status, 403);
});

test('refuses arbitrary paths and methods', async () => {
  assert.equal((await worker.fetch(new Request('https://example.workers.dev/?url=https://evil.example', { headers: { Origin: ALLOWED } }), prod)).status, 404);
  assert.equal((await worker.fetch(request('POST'), prod)).status, 405);
});

test('handles upstream exceptions, redirects and 503 with CORS headers', async () => {
  globalThis.fetch = async () => { throw Error('secret internal error'); };
  let response = await worker.fetch(request(), prod);
  assert.equal(response.status, 502);
  assert.equal(response.headers.get('Access-Control-Allow-Origin'), ALLOWED);
  assert.doesNotMatch(await response.text(), /secret internal error/);

  globalThis.fetch = async () => new Response(null, { status: 302, headers: { location: 'https://evil.example/' } });
  assert.equal((await worker.fetch(request(), prod)).status, 502);

  globalThis.fetch = async () => new Response('unavailable', { status: 503 });
  response = await worker.fetch(request(), prod);
  assert.equal(response.status, 503);
  assert.equal(response.headers.get('Cache-Control'), 'no-store');
});
