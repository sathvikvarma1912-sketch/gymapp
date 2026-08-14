# BrawlBros — deploy in ~3 minutes

## 1. Deploy to Vercel (free)
1. Put this folder in a GitHub repo (or drag-and-drop at vercel.com/new)
2. Import the repo in Vercel → Deploy. No build settings needed (static + one serverless function).

## 2. Enable AI features
Vercel → your project → Settings → Environment Variables:
- `OPENAI_API_KEY` = your OpenAI key
- Optional: `OPENAI_MODEL` = a Responses API model ID (defaults to `gpt-5.6-luna`)
- Optional: `OPENAI_MAX_OUTPUT_TOKENS` = longer or shorter replies (defaults to `1600`, capped at `4000`)

Apply the variable to **Production**, then redeploy. In the app, open Profile → AI features → Check; it should say **Connected and ready**. The ✨ buttons (AI recap, AI template builder, daily briefing, and coach chat) will then work.

## 3. Enable cloud sync and friends (Supabase free tier)
1. Create a Supabase project.
2. Open **SQL Editor**, paste [`supabase/schema.sql`](supabase/schema.sql), and run it once.
3. In Supabase **Authentication → URL Configuration**, set:
   - Site URL: `https://gymapp-sathvik12.vercel.app`
   - Redirect URL: `https://gymapp-sathvik12.vercel.app/**`
4. The connected project is already the safe default in `api/config.js`. To point another deployment at a different project, add these Vercel environment variables:
   - `SUPABASE_URL` = the project URL
   - `SUPABASE_PUBLISHABLE_KEY` = the publishable key (the legacy anon key also works as `SUPABASE_ANON_KEY`)
5. If you add overrides, apply both variables to **Production** and redeploy.

No database password, service-role key, or connection string belongs in Vercel. If the app is deployed at a different public URL, add `APP_URL` in Vercel and use that same URL in Supabase Authentication URL Configuration.

The publishable key is intentionally delivered to the browser; the SQL file enables Row Level Security so it can only access authorized rows. Never add a Supabase service-role or secret key to the app.

## 4. Install on iPhone or Android
Open your Vercel URL in Safari on iPhone or Chrome on Android, then choose **Add to Home Screen**.
It launches full-screen like a native app.

## Notes
- Data is saved on-device first (IndexedDB), so workouts still work offline. After email sign-in, private data is also synced to Supabase.
- Friends can see workout overviews and aggregate volume for weekly, monthly, and all-time rankings. Exercise names, individual weights, and reps remain private.
- Use Profile → Back up data for a portable JSON export.
- After finishing a workout, tap **Copy for Google Health** to grab the summary (exercises, sets, weights, start/end time, duration) and paste it into Google Health.
