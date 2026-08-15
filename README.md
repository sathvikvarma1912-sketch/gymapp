# RepNet — deploy in ~3 minutes

## 1. Deploy to Vercel (free)
1. Put this folder in a GitHub repo (or drag-and-drop at vercel.com/new)
2. Import the repo in Vercel → Deploy. No build settings needed (static + serverless functions).

## 2. Enable AI features
Vercel → your project → Settings → Environment Variables:
- `OPENAI_API_KEY` = your OpenAI key
- Optional: `OPENAI_MODEL` = a Responses API model ID (defaults to `gpt-5.6-luna`)
- Optional: `OPENAI_MAX_OUTPUT_TOKENS` = longer or shorter replies (defaults to `1600`, capped at `4000`)

Apply the variable to **Production**, then redeploy. In the app, open Profile → AI features → Check; it should say **Connected and ready**. The ✨ buttons (AI recap, AI template builder, daily briefing, and coach chat) will then work.

## 3. Enable the exercise catalog
No API key or server configuration is required. RepNet loads the public
[hasaneyldrm/exercises-dataset](https://github.com/hasaneyldrm/exercises-dataset) catalog from GitHub and searches its 1,324 exercises on the device.

Exercise metadata is cached in IndexedDB for up to 24 hours, with stale metadata used when GitHub is temporarily unavailable. Animated GIF files stream from the repository only when a user opens a demonstration; RepNet does not cache those files. Cloud state and backups contain only the provider name, exercise ID, canonical name, and availability flag — never a GIF URL or the full catalog.

If an exercise is not in the catalog, users can add it by name as a custom exercise in an active workout or template. Custom exercises work without a GIF and can be linked to the closest catalog demonstration later. The AI template builder receives the complete catalog name list, is instructed to prefer exact catalog names, offers nearby matches for review, and keeps unmatched suggestions as custom exercises instead of blocking the template. The stable catalog instruction prefix is eligible for OpenAI prompt caching.

The dataset's code, structured data, and instructions are MIT-licensed. Its media has separate terms described in the repository's [`NOTICE.md`](https://github.com/hasaneyldrm/exercises-dataset/blob/main/NOTICE.md); the source and media terms remain documented here for project review.

## 4. Enable authentication, cloud sync and friends (Supabase free tier)
1. Create a Supabase project.
2. Open **SQL Editor**, paste [`supabase/schema.sql`](supabase/schema.sql), and run it once.
3. In Supabase **Authentication → URL Configuration**, set:
   - Site URL: `https://gymapp-sathvik12.vercel.app`
   - Redirect URL: `https://gymapp-sathvik12.vercel.app/**`
4. In Google Cloud **Google Auth Platform → Clients**, create a **Web application** OAuth client with:
   - Authorized JavaScript origin: `https://gymapp-sathvik12.vercel.app`
   - Authorized redirect URI: `https://lhabpgznkgpccfhvgyzz.supabase.co/auth/v1/callback`
5. In Supabase **Authentication → Providers → Google**, enable Google and paste the Google Client ID and Client Secret.
6. The connected project is already the safe default in `api/config.js`. To point another deployment at a different project, add these Vercel environment variables:
   - `SUPABASE_URL` = the project URL
   - `SUPABASE_PUBLISHABLE_KEY` = the publishable key (the legacy anon key also works as `SUPABASE_ANON_KEY`)
7. If you add overrides, apply both variables to **Production** and redeploy.

The Google Client Secret belongs only in Supabase. No OAuth secret, database password, service-role key, or connection string belongs in Vercel or browser code. If the app is deployed at a different public URL, add `APP_URL` in Vercel and use that same URL in Supabase Authentication URL Configuration and Google Authorized JavaScript origins.

The publishable key is intentionally delivered to the browser; the SQL file enables Row Level Security so it can only access authorized rows. Never add a Supabase service-role or secret key to the app.

## 5. Install on iPhone or Android
Open your Vercel URL in Safari on iPhone or Chrome on Android, then choose **Add to Home Screen**.
It launches full-screen like a native app.

## Local review without authentication
Serve the project on `localhost`, then open `http://localhost:3000/?demo=1` (adjust the port for your server). Demo mode uses separate local IndexedDB data and disables authentication and cloud sync. It uses the same GitHub exercise catalog as the signed-in app, so a basic static server is enough. The authentication bypass is rejected automatically on non-loopback hostnames.

## Notes
- Login is required. Google is the primary sign-in method and secure email links are the fallback.
- First-time users complete a private profile with their name, age, gender, weight, and height. Personal measurements are stored in an owner-only table and are never exposed to friends or leaderboards.
- Data is saved per authenticated user on-device first (IndexedDB), so workouts still work offline after sign-in. Private data is also synced to Supabase.
- Every signed-in user appears in the weekly, monthly, yearly, and all-time aggregate leaderboard. Accepted friends can also see workout and exercise names; individual weights and reps remain private.
- Use Profile → Back up data for a portable JSON export.
- After finishing a workout, tap **Copy for Google Health** to grab the summary (exercises, sets, weights, start/end time, duration) and paste it into Google Health.
