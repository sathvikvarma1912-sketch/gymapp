# BrawlBros — deploy in ~3 minutes

## 1. Deploy to Vercel (free)
1. Put this folder in a GitHub repo (or drag-and-drop at vercel.com/new)
2. Import the repo in Vercel → Deploy. No build settings needed (static + one serverless function).

## 2. Enable AI features
Vercel → your project → Settings → Environment Variables:
- `OPENAI_API_KEY` = your OpenAI key
Redeploy. The ✨ buttons (AI recap, AI template builder) now work.

## 3. Install on iPhone
Open your Vercel URL in **Safari** → Share → **Add to Home Screen**.
Launches full-screen like a native app.

## Notes
- Data lives on-device (IndexedDB). Use Profile → Back up data for a JSON export.
- After finishing a workout, tap **Copy for Google Health** to grab the summary (exercises, sets, weights, start/end time, duration) and paste it into Google Health.
