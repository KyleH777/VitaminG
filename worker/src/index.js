// Cloudflare Worker — Vitamin G AI Proxy
// Holds the Anthropic API key server-side as a Cloudflare secret (T-28-01).
// iOS sends structured payloads; Worker builds Claude prompts server-side (D-10).
// Worker returns thin JSON envelopes (D-09).
//
// DEPLOYMENT:
//   From worker/ directory:
//     npx wrangler secret put ANTHROPIC_API_KEY   (paste Anthropic API key)
//     npx wrangler secret put SHARED_TOKEN        (paste a fresh `uuidgen` value)
//     npx wrangler deploy
//   Then put the SAME new UUID into the iOS app via the gitignored config
//   (see Secrets.xcconfig instructions) — never as a committed string literal.
//
// SECURITY: env.ANTHROPIC_API_KEY and env.SHARED_TOKEN are the ONLY places
// secrets appear. Neither may ever be a string literal in this file.
// SECURITY: rate limiting via native ratelimits bindings — per-IP 10/min
// plus global 100/min circuit breaker, fail-open on limiter error.
// SECURITY: all client-supplied fields are type-coerced and length-clamped
// before prompt construction (see sanitizeGoals) so a client holding the
// token still cannot inflate input-token spend or crash the worker.

const STATIC_SUGGESTIONS = [
  "Read for 15 minutes daily",
  "Drink 8 glasses of water",
  "Meditate for 5 minutes"
];

// Server-side input clamps. Mirrors the iOS app's own limits but is enforced
// here because local client validation is not a trust boundary.
const MAX_GOALS = 8;
const MAX_TITLE_LENGTH = 80;
const MAX_CATEGORY_LENGTH = 40;
const MAX_STREAK = 36500; // ~100 years; anything above is a forged payload

/// Coerces the raw goals value into a bounded array of { title, category }
/// plain strings. Non-objects, nulls, and non-string fields are dropped or
/// stringified; every string is trimmed and hard-clamped. Never throws.
function sanitizeGoals(raw) {
  if (!Array.isArray(raw)) return [];
  return raw
    .filter(g => g !== null && typeof g === "object")
    .slice(0, MAX_GOALS)
    .map(g => ({
      title: String(typeof g.title === "string" ? g.title : "")
        .replace(/[\r\n]+/g, " ")
        .trim()
        .slice(0, MAX_TITLE_LENGTH),
      category: String(typeof g.category === "string" ? g.category : "")
        .replace(/[\r\n]+/g, " ")
        .trim()
        .slice(0, MAX_CATEGORY_LENGTH),
    }))
    .filter(g => g.title.length > 0);
}

export default {
  async fetch(request, env, ctx) {
    // (1) OPTIONS preflight — must return 204 with CORS headers (T-28-03)
    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers: {
          "Access-Control-Allow-Origin": "*",
          "Access-Control-Allow-Methods": "POST, OPTIONS",
          "Access-Control-Allow-Headers": "Content-Type",
          "Access-Control-Max-Age": "86400",
        },
      });
    }

    // (2) Non-POST methods return 405
    if (request.method !== "POST") {
      return new Response("Method not allowed", {
        status: 405,
        headers: { "Access-Control-Allow-Origin": "*" },
      });
    }

    // (2b) Rate limiting — native Workers Rate Limiting binding.
    // Per-IP first (10/min), then global circuit breaker (100/min per location).
    // CF-Connecting-IP is set by Cloudflare and cannot be spoofed by the client.
    // iOS client treats 429 like any error: silent fallback to VGQuoteBank.
    const clientIP = request.headers.get("CF-Connecting-IP") ?? "unknown";
    try {
      const ipCheck = await env.IP_LIMITER.limit({ key: clientIP });
      if (!ipCheck.success) {
        return new Response("Too many requests", {
          status: 429,
          headers: {
            "Access-Control-Allow-Origin": "*",
            "Retry-After": "60",
          },
        });
      }
      const globalCheck = await env.GLOBAL_LIMITER.limit({ key: "global" });
      if (!globalCheck.success) {
        return new Response("Service busy", {
          status: 429,
          headers: {
            "Access-Control-Allow-Origin": "*",
            "Retry-After": "60",
          },
        });
      }
    } catch (_) {
      // Fail OPEN: if the rate limiter itself errors, serve the request.
      // Availability for real users beats strictness; the global cap still
      // bounds worst-case cost on subsequent requests.
    }

    // Parse JSON body
    let body;
    try {
      body = await request.json();
    } catch (_) {
      return new Response("Bad request: invalid JSON", {
        status: 400,
        headers: { "Access-Control-Allow-Origin": "*" },
      });
    }

    // (3) Validate shared secret token — first action after JSON parse (T-28-02).
    // Token now lives in a Cloudflare secret, never in source. If the secret
    // is unset (misconfigured deploy), fail CLOSED with 500 rather than
    // comparing against undefined.
    if (typeof env.SHARED_TOKEN !== "string" || env.SHARED_TOKEN.length === 0) {
      return new Response("Server misconfigured", {
        status: 500,
        headers: { "Access-Control-Allow-Origin": "*" },
      });
    }
    if (body.token !== env.SHARED_TOKEN) {
      return new Response("Unauthorized", {
        status: 401,
        headers: { "Access-Control-Allow-Origin": "*" },
      });
    }

    // (4) Validate type field (T-28-06)
    const type = body.type;
    if (type !== "motivation" && type !== "suggestions") {
      return new Response("Bad request: type must be motivation or suggestions", {
        status: 400,
        headers: { "Access-Control-Allow-Origin": "*" },
      });
    }

    // Safely extract, validate, and CLAMP goals and streak (T-28-06).
    // sanitizeGoals never throws — malformed entries (null, numbers, giant
    // strings) are dropped or truncated instead of reaching the prompt.
    const goals = sanitizeGoals(body.goals);
    const rawStreak = typeof body.streak === "number" && Number.isFinite(body.streak)
      ? Math.trunc(body.streak)
      : 0;
    const streak = Math.min(Math.max(rawStreak, 0), MAX_STREAK);

    // (5) Build prompt server-side — prompt construction is server-side per D-10
    let prompt;
    let maxTokens;

    if (type === "motivation") {
      const goalTitles = goals.map(g => g.title).join(", ");
      prompt = `You are a warm, personal wellness coach. The user has a ${streak}-day streak and is working on: ${goalTitles || "personal goals"}. Write a motivational message in 2-3 sentences, under 40 words. Be warm, personal, and specific to their goals. Do not use generic platitudes. Plain text only — no markdown, no headings, no title line; the app renders your reply verbatim.`;
      maxTokens = 150;
    } else {
      // type === "suggestions"
      const goalTitles = goals.map(g => `${g.title} (${g.category})`).join(", ");
      prompt = `The user is already working on these goals: ${goalTitles || "personal growth"}. Suggest exactly 3 new, specific, actionable goals that complement their existing ones. Return ONLY a raw JSON array of 3 strings. No markdown, no code fences, no explanation. Example: ["Goal 1", "Goal 2", "Goal 3"]`;
      maxTokens = 200;
    }

    // (6) POST to Anthropic Messages API — key only via env.ANTHROPIC_API_KEY (T-28-01)
    let anthropicResponse;
    try {
      anthropicResponse = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "anthropic-version": "2023-06-01",
          "X-Api-Key": env.ANTHROPIC_API_KEY,  // secret — never a string literal
        },
        body: JSON.stringify({
          model: "claude-haiku-4-5-20251001",
          max_tokens: maxTokens,
          messages: [{ role: "user", content: prompt }],
        }),
      });
    } catch (err) {
      return new Response("Claude API error", {
        status: 502,
        headers: { "Access-Control-Allow-Origin": "*" },
      });
    }

    // (7) Non-OK Anthropic response returns 502
    if (!anthropicResponse.ok) {
      return new Response("Claude API error", {
        status: 502,
        headers: { "Access-Control-Allow-Origin": "*" },
      });
    }

    const claude = await anthropicResponse.json();

    // (8) Extract content[0].text
    const text = claude.content?.[0]?.text ?? "";

    // (9) Wrap in thin envelope per D-09
    let responseBody;
    if (type === "motivation") {
      responseBody = { text };
    } else {
      // suggestions: strip markdown fences before JSON.parse (Pitfall 5 — T-28-07)
      let suggestions = STATIC_SUGGESTIONS;
      try {
        const cleaned = text.replace(/```json?/g, "").replace(/```/g, "").trim();
        const parsed = JSON.parse(cleaned);
        if (Array.isArray(parsed) && parsed.length >= 3) {
          // Coerce to strings and clamp — Claude output is untrusted too.
          suggestions = parsed.slice(0, 3).map(s => String(s).slice(0, 120));
        }
      } catch (_) {
        // Fallback to static suggestions if Claude returns malformed JSON (D-07)
      }
      responseBody = { suggestions };
    }

    // (10) All success responses include Access-Control-Allow-Origin: *
    return new Response(JSON.stringify(responseBody), {
      status: 200,
      headers: {
        "Content-Type": "application/json",
        "Access-Control-Allow-Origin": "*",
      },
    });
  },
};
