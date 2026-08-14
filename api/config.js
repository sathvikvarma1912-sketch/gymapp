export default function handler(_request, response) {
  response.setHeader('Cache-Control', 'no-store');
  response.status(200).json({
    // Supabase publishable values are safe in browser code when RLS is enabled.
    supabaseUrl: process.env.SUPABASE_URL || 'https://lhabpgznkgpccfhvgyzz.supabase.co',
    supabaseKey: process.env.SUPABASE_PUBLISHABLE_KEY || process.env.SUPABASE_ANON_KEY || 'sb_publishable_OAn9J6bbvhyFWycD7eJ3FQ_Ai8QFYre',
    appUrl: process.env.APP_URL || 'https://gymapp-sathvik12.vercel.app/'
  });
}
