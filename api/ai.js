// Vercel serverless function — keeps the OpenAI key off the client.
// Set OPENAI_API_KEY in Vercel → Project → Settings → Environment Variables.
const json = (res, status, body) => {
  res.setHeader('Cache-Control', 'no-store');
  return res.status(status).json(body);
};

export default async function handler(req, res) {
  const apiKey = process.env.OPENAI_API_KEY;
  const model = process.env.OPENAI_MODEL || 'gpt-5.6-luna';
  const configuredMax = Number(process.env.OPENAI_MAX_OUTPUT_TOKENS);
  const maxOutputTokens = Number.isFinite(configuredMax)
    ? Math.min(4000, Math.max(500, configuredMax))
    : 1600;

  if (req.method === 'GET') {
    if (!apiKey) return json(res, 200, { ok: true, configured: false, ready: false });
    try {
      const check = await fetch(`https://api.openai.com/v1/models/${encodeURIComponent(model)}`, {
        headers: { Authorization: `Bearer ${apiKey}` },
      });
      return json(res, 200, {
        ok: true,
        configured: true,
        ready: check.ok,
        reason: check.ok ? undefined : check.status === 401 ? 'invalid_key' : 'model_unavailable',
      });
    } catch (_) {
      return json(res, 200, {
        ok: true,
        configured: true,
        ready: false,
        reason: 'upstream_unavailable',
      });
    }
  }

  if (req.method !== 'POST') {
    res.setHeader('Allow', 'GET, POST');
    return json(res, 405, { error: 'Method not allowed' });
  }

  const { prompt, system, mode } = req.body || {};
  if (typeof prompt !== 'string' || !prompt.trim()) {
    return json(res, 400, { error: 'Missing prompt' });
  }
  if (prompt.length > 100000) {
    return json(res, 413, { error: 'This message is too large to process.' });
  }
  if (typeof system === 'string' && system.length > 80000) {
    return json(res, 413, { error: 'The AI instructions are too large to process.' });
  }
  if (!apiKey) {
    return json(res, 503, {
      error: 'OPENAI_API_KEY is not configured in Vercel.',
      code: 'missing_api_key',
    });
  }

  try {
    const structuredText = mode === 'home_recap' ? {
      format: {
        type: 'json_schema',
        name: 'home_workout_recap',
        strict: true,
        schema: {
          type: 'object',
          properties: {
            summary: { type: 'string' },
            suggestion_one: { type: 'string' },
            suggestion_two: { type: 'string' },
          },
          required: ['summary', 'suggestion_one', 'suggestion_two'],
          additionalProperties: false,
        },
      },
    } : mode === 'template_builder' ? {
      format: {
        type: 'json_schema',
        name: 'workout_templates',
        strict: true,
        schema: {
          type: 'object',
          properties: {
            templates: {
              type: 'array',
              minItems: 1,
              maxItems: 12,
              items: {
                type: 'object',
                properties: {
                  name: { type: 'string' },
                  exercises: {
                    type: 'array',
                    minItems: 1,
                    maxItems: 20,
                    items: {
                      type: 'object',
                      properties: {
                        name: { type: 'string' },
                        sets: { type: 'integer', minimum: 1, maximum: 20 },
                      },
                      required: ['name', 'sets'],
                      additionalProperties: false,
                    },
                  },
                },
                required: ['name', 'exercises'],
                additionalProperties: false,
              },
            },
          },
          required: ['templates'],
          additionalProperties: false,
        },
      },
    } : undefined;
    const response = await fetch('https://api.openai.com/v1/responses', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${apiKey}`,
      },
      body: JSON.stringify({
        model,
        instructions: typeof system === 'string' && system.trim()
          ? system
          : 'You are a helpful fitness coach.',
        input: prompt.trim(),
        reasoning: { effort: 'none' },
        max_output_tokens: maxOutputTokens,
        ...(mode === 'template_builder' ? { prompt_cache_key: 'repnet-template-catalog-v1' } : {}),
        ...(structuredText ? { text: structuredText } : {}),
      }),
    });

    const data = await response.json().catch(() => ({}));
    if (!response.ok) {
      console.error('OpenAI API error', response.status, data.error?.code || 'unknown');
      const error = response.status === 401
        ? 'OpenAI rejected the API key. Replace OPENAI_API_KEY in Vercel and redeploy.'
        : response.status === 429
          ? 'OpenAI rate limit or billing limit reached. Check API billing and limits.'
          : response.status === 404
            ? 'The configured OpenAI model is unavailable. Check OPENAI_MODEL in Vercel.'
            : 'The AI service rejected the request. Please try again.';
      return json(res, 502, {
        error,
        code: 'openai_error',
      });
    }

    const outputText = typeof data.output_text === 'string'
      ? data.output_text
      : data.output
        ?.flatMap((item) => item.content || [])
        .find((part) => part.type === 'output_text')?.text;

    if (typeof outputText !== 'string' || !outputText.trim()) {
      console.error('OpenAI API returned no output text', data.id || 'unknown');
      return json(res, 502, {
        error: 'The AI service returned an empty response.',
        code: 'empty_response',
      });
    }

    return json(res, 200, { text: outputText.trim() });
  } catch (error) {
    console.error('AI endpoint request failed', error);
    return json(res, 502, {
      error: 'Could not connect to the AI service.',
      code: 'upstream_unavailable',
    });
  }
}
