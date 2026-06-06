// Cloudflare Worker — Vitamin G AI Proxy
// Holds the Anthropic API key server-side as a Cloudflare secret (T-28-01).
// iOS sends structured payloads; Worker builds Claude prompts server-side (D-10).
// Worker returns thin JSON envelopes (D-09). Shared token deters casual abuse (D-11).
//
// DEPLOYMENT:
//   1. Replace REPLACE_WITH_UUID_AT_DEPLOY below with the output of `uuidgen`.
//   2. Paste the same UUID into AIProxyService.workerToken in the iOS app.
//   3. From worker/ directory:
//        npx wrangler secret put ANTHROPIC_API_KEY   (paste your Anthropic API key when prompted)
//        npx wrangler deploy
//
// SECURITY: env.ANTHROPIC_API_KEY is the ONLY place the Anthropic key appears — never
// as a string literal. The API key must ONLY be set via `wrangler secret put` — never in files.

const SHARED_TOKEN = "REPLACE_WITH_UUID_AT_DEPLOY"; // operator must replace before wrangler deploy

const STATIC_SUGGESTIONS = [
  "Read for 15 minutes daily",
  "Drink 8 glasses of water",
  "Meditate for 5 minutes"
];

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

    // (3) Validate shared secret token — first action after JSON parse (T-28-02)
    if (body.token !== SHARED_TOKEN) {
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

    // Safely extract and validate goals and streak (T-28-06)
    const goals = Array.isArray(body.goals) ? body.goals : [];
    const streak = typeof body.streak === "number" ? body.streak : 0;

    // (5) Build prompt server-side — prompt construction is server-side per D-10
    let prompt;
    let maxTokens;

    if (type === "motivation") {
      const goalTitles = goals.map(g => g.title).join(", ");
      prompt = `You are a warm, personal wellness coach. The user has a ${streak}-day streak and is working on: ${goalTitles || "personal goals"}. Write a motivational message in 2-3 sentences, under 40 words. Be warm, personal, and specific to their goals. Do not use generic platitudes.`;
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
          suggestions = parsed.slice(0, 3);
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
