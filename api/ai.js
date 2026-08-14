// Vercel serverless function — keeps your OpenAI key off the client.
// Set OPENAI_API_KEY in Vercel → Project → Settings → Environment Variables.
export default async function handler(req, res) {
  if (req.method !== 'POST') return res.status(405).json({ error: 'POST only' });
  const { prompt, system } = req.body || {};
  if (!prompt) return res.status(400).json({ error: 'Missing prompt' });

  try {
    const r = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${process.env.OPENAI_API_KEY}`,
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',
        max_tokens: 500,
        messages: [
          { role: 'system', content: system || 'You are a helpful fitness coach.' },
          { role: 'user', content: prompt },
        ],
      }),
    });
    const d = await r.json();
    if (!r.ok) return res.status(500).json({ error: d.error?.message || 'OpenAI error' });
    res.status(200).json({ text: d.choices[0].message.content });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
}
