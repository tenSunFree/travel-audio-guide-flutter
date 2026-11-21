# Taipei Travel API CORS Proxy

Browser-only CORS adapter for the public Taipei Travel API. The upstream is fixed
at `https://www.travel.taipei`; only `GET /open-api/*` is forwarded. Only a
small allow-list of browser origins and request headers is permitted.

**CORS is not authentication.** Other HTTP clients can spoof `Origin`.
For abuse protection, use Cloudflare rate limiting/WAF and monitor usage.

## 1. Install and test (Node.js 22.12+)

Wrangler 4 requires Node.js 22.12 or newer (`node --version`).

```powershell
cd infra/taipei-api-proxy
npm ci
npm test
```

## 2. Run locally (separate terminal)

```powershell
cd infra/taipei-api-proxy
npx wrangler dev --env dev --port 8787
```

From the repository root, run Flutter Web with the local Worker (no Worker
deployment required):

```powershell
fvm flutter run -d chrome --web-port 5555 -t lib/main_staging.dart --dart-define-from-file=env/dev.json --dart-define=TAIPEI_API_BASE_URL=http://127.0.0.1:8787/open-api
```

Verify Chrome Network shows requests to `127.0.0.1:8787`, not `travel.taipei`.
Local development accepts any loopback port for the requesting Flutter app.

The upstream's firewall rejects requests without a `User-Agent` (HTTP 403 "Sorry, you have been
blocked"), so the Worker sends a fixed one: `TravelAudioGuideWebProxy/1.0`. If a request through the
Worker returns 403 with an HTML body, the block comes from `travel.taipei`, not from this Worker.

## 3. Deploy production Worker

```powershell
cd infra/taipei-api-proxy
npx wrangler login
npx wrangler deploy
```

Use the exact `https://...workers.dev` URL printed by Wrangler; do not invent
the account subdomain. A Worker running on Cloudflare's network is not the same as a local request
to the upstream, so always repeat step 4 against the deployed URL. Add `/open-api` to form `TAIPEI_API_BASE_URL`.
If using custom Hosting domains, add their exact origins to `ALLOWED_ORIGINS`.

## 4. Verify with actual preflight (PowerShell)

```powershell
$worker = 'https://YOUR-WORKER.workers.dev'
curl.exe -i -X OPTIONS "$worker/open-api/zh-tw/Attractions/All?page=1" -H "Origin: https://travel-audio-guide-flutter.web.app" -H "Access-Control-Request-Method: GET" -H "Access-Control-Request-Headers: sentry-trace,baggage,content-type"
curl.exe -i "$worker/open-api/zh-tw/Attractions/All?page=1" -H "Origin: https://travel-audio-guide-flutter.web.app"
```

Expect `204` with `Access-Control-Allow-Origin` and allowed headers, then a
successful upstream status (usually `200`). Upstream rate limits / outages may
cause a different status; read the body. These tests require network access.

## 5. Production Flutter Web build

Set `TAIPEI_API_BASE_URL=https://YOUR-WORKER.workers.dev/open-api` in the
appropriate `--dart-define-from-file` JSON. For CI, define the GitHub Actions
**variable** `TAIPEI_API_BASE_URL` and pass it to `scripts/create_runtime_env.sh`.
Run the validator on deploy-time settings, then build Flutter Web.

Do not deploy the `dev` Wrangler environment publicly. The Worker does not
proxy image/audio URLs; test those separately as browser resources.
