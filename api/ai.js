// Set GEMINI_API_KEY in Vercel → Project → Settings → Environment Variables.
// The API key remains server-side; the browser only calls this endpoint.
const json = (res, status, body) => {
  res.setHeader('Cache-Control', 'no-store');
  return res.status(status).json(body);
};

const geminiModel = () => (process.env.GEMINI_MODEL || 'gemini-2.5-flash').replace(/^models\//, '');
const structuredModes = new Set(['home_recap', 'template_builder', 'workout_agent', 'workout_replacements']);

function structuredOutputInstruction(mode) {
  if (mode === 'home_recap') return 'Return only valid JSON with exactly these string properties: summary, suggestion_one, suggestion_two. Do not use markdown.';
  if (mode === 'template_builder') return 'Return only valid JSON in this shape: {"templates":[{"name":"string","exercises":[{"name":"string","sets":number}]}]}. Do not use markdown.';
  if (mode === 'workout_agent' || mode === 'workout_replacements') return 'Return only valid JSON in this shape: {"message":"string","actions":[{"type":"replace_exercise","source_exercise_id":"string","replacement_name":"string","reason":"string"}]}. Do not use markdown. If no change is appropriate, return an empty actions array.';
  return '';
}

function geminiError(response, data) {
  const message = String(data?.error?.message || '');
  if ([400, 401, 403].includes(response.status)) return { error: 'Gemini rejected the API key. Replace GEMINI_API_KEY in Vercel and redeploy.', code: 'gemini_error' };
  if (response.status === 429) return { error: 'Gemini rate limit or billing limit reached. Check Gemini API billing and limits.', code: 'gemini_error' };
  if (response.status === 404) return { error: 'The configured Gemini model is unavailable. Check GEMINI_MODEL in Vercel.', code: 'gemini_error' };
  return { error: message || 'The AI service rejected the request. Please try again.', code: 'gemini_error' };
}

export default async function handler(req, res) {
  const apiKey = process.env.GEMINI_API_KEY;
  const model = geminiModel();
  const configuredMax = Number(process.env.GEMINI_MAX_OUTPUT_TOKENS);
  const maxOutputTokens = Number.isFinite(configuredMax) ? Math.min(4000, Math.max(500, configuredMax)) : 1600;

  if (req.method === 'GET') {
    if (!apiKey) return json(res, 200, { ok: true, configured: false, ready: false, provider: 'gemini' });
    try {
      const check = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}`, { headers: { 'x-goog-api-key': apiKey } });
      return json(res, 200, {
        ok: true, configured: true, ready: check.ok, provider: 'gemini',
        reason: check.ok ? undefined : [400, 401, 403].includes(check.status) ? 'invalid_key' : 'model_unavailable',
      });
    } catch (_) {
      return json(res, 200, { ok: true, configured: true, ready: false, provider: 'gemini', reason: 'upstream_unavailable' });
    }
  }

  if (req.method !== 'POST') {
    res.setHeader('Allow', 'GET, POST');
    return json(res, 405, { error: 'Method not allowed' });
  }

  const { prompt, system, mode } = req.body || {};
  if (typeof prompt !== 'string' || !prompt.trim()) return json(res, 400, { error: 'Missing prompt' });
  if (prompt.length > 100000) return json(res, 413, { error: 'This message is too large to process.' });
  if (typeof system === 'string' && system.length > 80000) return json(res, 413, { error: 'This message is too large to process.' });
  if (!apiKey) return json(res, 503, { error: 'GEMINI_API_KEY is not configured in Vercel.', code: 'missing_api_key' });

  const baseInstructions = typeof system === 'string' && system.trim() ? system.trim() : 'You are a helpful fitness coach.';
  const instructions = [baseInstructions, structuredOutputInstruction(mode)].filter(Boolean).join('\n\n');
  const generationConfig = {
    maxOutputTokens,
    ...(structuredModes.has(mode) ? { responseMimeType: 'application/json' } : {}),
  };

  try {
    const response = await fetch(`https://generativelanguage.googleapis.com/v1beta/models/${encodeURIComponent(model)}:generateContent`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', 'x-goog-api-key': apiKey },
      body: JSON.stringify({
        systemInstruction: { parts: [{ text: instructions }] },
        contents: [{ role: 'user', parts: [{ text: prompt.trim() }] }],
        generationConfig,
      }),
    });
    const data = await response.json().catch(() => ({}));
    if (!response.ok) return json(res, 502, geminiError(response, data));

    const outputText = data.candidates?.[0]?.content?.parts?.map((part) => part.text || '').join('').trim();
    if (!outputText) {
      console.error('Gemini API returned no output text', data?.promptFeedback?.blockReason || 'unknown');
      return json(res, 502, { error: 'The AI service returned an empty response.', code: 'empty_response' });
    }
    return json(res, 200, { text: outputText });
  } catch (error) {
    console.error('Gemini API request failed', error);
    return json(res, 502, { error: 'Could not connect to the AI service.', code: 'upstream_unavailable' });
  }
}
