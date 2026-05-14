// import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
// import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

// const corsHeaders = {
//   'Access-Control-Allow-Origin': '*',
//   'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
// }

// serve(async (req) => {
//   if (req.method === 'OPTIONS') {
//     return new Response('ok', { headers: corsHeaders })
//   }

//   try {
//     const supabaseClient = createClient(
//       Deno.env.get('SUPABASE_URL') ?? '',
//       Deno.env.get('SUPABASE_ANON_KEY') ?? '',
//       { global: { headers: { Authorization: req.headers.get('Authorization')! } } }
//     )

//     const { target_id, is_recognized } = await req.json()

//     // Get the user from the JWT
//     const { data: { user }, error: authError } = await supabaseClient.auth.getUser()
//     if (authError || !user) throw new Error('Unauthorized')

//     // Upsert the vote
//     const { error: dbError } = await supabaseClient
//       .from('votes')
//       .upsert({
//         voter_id: user.id,
//         target_id: target_id,
//         is_recognized: is_recognized,
//       }, { onConflict: 'voter_id,target_id' })

//     if (dbError) throw dbError

//     return new Response(JSON.stringify({ success: true }), {
//       headers: { ...corsHeaders, 'Content-Type': 'application/json' },
//       status: 200,
//     })
//   } catch (error) {
//     return new Response(JSON.stringify({ error: error.message }), {
//       headers: { ...corsHeaders, 'Content-Type': 'application/json' },
//       status: 400,
//     })
//   }
// })
