// Narrow CORS adapter for the public Taipei Travel Open API.
// CORS restricts browser reads; it is NOT authentication or anti-abuse protection.
const UPSTREAM = 'https://www.travel.taipei';
const PREFIX = '/open-api/';
const ALLOWED_ORIGINS = new Set([
  'https://travel-audio-guide-flutter.web.app',
  'https://travel-audio-guide-flutter.firebaseapp.com',
]);
// Only the `staging` Firebase Hosting preview channel, not arbitrary channels.
const STAGING_PREVIEW = /^https:\/\/travel-audio-guide-flutter--staging-[a-z0-9]+\.web\.app$/;
const LOCAL_ORIGIN = /^http:\/\/(?:localhost|127\.0\.0\.1)(?::\d{1,5})?$/;
// Allow only headers currently used by Dio/Sentry and normal browser clients.
const ALLOWED_REQUEST_HEADERS = new Set([
  'accept', 'content-type', 'sentry-trace', 'baggage', 'traceparent', 'tracestate',
]);

function isAllowedOrigin(origin, env) {
  return ALLOWED_ORIGINS.has(origin) || STAGING_PREVIEW.test(origin) ||
    (env.ALLOW_LOCALHOST === 'true' && LOCAL_ORIGIN.test(origin));
}

function corsHeaders(origin, isPreflight = false) {
  const headers = new Headers({
    'Access-Control-Allow-Origin': origin,
    'Vary': 'Origin',
    'X-Content-Type-Options': 'nosniff',
  });
  if (isPreflight) {
    headers.set('Access-Control-Allow-Methods', 'GET');
    headers.set('Access-Control-Allow-Headers', [...ALLOWED_REQUEST_HEADERS].join(', '));
    headers.set('Access-Control-Max-Age', '600');
    headers.set('Vary', 'Origin, Access-Control-Request-Method, Access-Control-Request-Headers');
  }
  return headers;
}

function textResponse(status, message, origin, extra = {}) {
  const headers = origin ? corsHeaders(origin) : new Headers();
  headers.set('Content-Type', 'text/plain; charset=utf-8');
  headers.set('Cache-Control', 'no-store');
  for (const [key, value] of Object.entries(extra)) headers.set(key, value);
  return new Response(message, { status, headers });
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const origin = request.headers.get('Origin');

    if (!url.pathname.startsWith(PREFIX)) return textResponse(404, 'Not found');
    if (!origin || !isAllowedOrigin(origin, env)) {
      return textResponse(403, 'Origin not allowed');
    }

    if (request.method === 'OPTIONS') {
      if (request.headers.get('Access-Control-Request-Method')?.toUpperCase() !== 'GET') {
        return textResponse(405, 'Only GET is allowed', origin, { Allow: 'GET, OPTIONS' });
      }
      const requested = (request.headers.get('Access-Control-Request-Headers') || '')
        .split(',').map((h) => h.trim().toLowerCase()).filter(Boolean);
      if (requested.some((h) => !ALLOWED_REQUEST_HEADERS.has(h))) {
        return textResponse(403, 'Preflight header not allowed', origin);
      }
      return new Response(null, { status: 204, headers: corsHeaders(origin, true) });
    }
    if (request.method !== 'GET') {
      return textResponse(405, 'Method not allowed', origin, { Allow: 'GET, OPTIONS' });
    }

    // Do not forward cookies, Authorization, Origin, Sentry headers, or user headers.
    // Fixed upstream host; URL is never accepted from a query parameter.
    const upstreamUrl = new URL(url.pathname + url.search, UPSTREAM);
    let upstream;
    try {
      upstream = await fetch(upstreamUrl.toString(), {
        method: 'GET',
        redirect: 'manual',
        headers: {
          accept: 'application/json',
          // The upstream WAF will block requests without a User-Agent or curl's default UA; use a fixed, honest UA to identify our proxy.
          'user-agent': 'TravelAudioGuideWebProxy/1.0',
        },
        cf: {
          cacheEverything: true,
          cacheTtlByStatus: { '200-299': 300, '300-599': 0 },
        },
      });
    } catch {
      return textResponse(502, 'Upstream unavailable', origin);
    }
    if (upstream.status >= 300 && upstream.status < 400) {
      return textResponse(502, 'Unexpected upstream redirect', origin);
    }

    const headers = corsHeaders(origin);
    headers.set('Content-Type', upstream.headers.get('content-type') ?? 'application/json; charset=utf-8');
    headers.set('Cache-Control', upstream.ok ? 'public, max-age=60' : 'no-store');
    return new Response(upstream.body, { status: upstream.status, headers });
  },
};
