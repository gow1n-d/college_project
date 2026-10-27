// Edge Function: conductor-login
// Custom username+bus login — returns a Supabase session
// Conductors log in with username+bus_number+password (not email directly)

/// <reference path="../types.d.ts" />

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const { username, bus_number, password } = await req.json()
    if (!username || !bus_number || !password) {
      return error(400, 'Username, bus number, and password are required')
    }

    const service = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // 1. Look up profile by username
    const { data: profile } = await service
      .from('profiles')
      .select('id, role, is_active, display_name')
      .eq('username', username.trim())
      .single()

    if (!profile) return error(401, 'Invalid credentials')
    if (!profile.is_active) return error(403, 'Account is deactivated')
    if (profile.role !== 'conductor') return error(403, 'Not a conductor account')

    // 2. Verify bus assignment
    const { data: bus } = await service
      .from('buses')
      .select('id, bus_number, is_active')
      .eq('bus_number', bus_number.trim().toUpperCase())
      .single()

    if (!bus || !bus.is_active) return error(401, 'Invalid bus number')

    const { data: assignment } = await service
      .from('conductor_bus_assignments')
      .select('id')
      .eq('conductor_id', profile.id)
      .eq('bus_id', bus.id)
      .eq('is_active', true)
      .or(`valid_until.is.null,valid_until.gte.${new Date().toISOString().split('T')[0]}`)
      .single()

    if (!assignment) return error(403, 'Not assigned to this bus')

    // 3. Get the auth user's email to sign in (stored in auth.users)
    const { data: authUser } = await service.auth.admin.getUserById(profile.id)
    if (!authUser?.user?.email) return error(500, 'Account configuration error')

    // 4. Sign in with password — returns actual session tokens
    const userClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
    )

    const { data: session, error: signInError } = await userClient.auth.signInWithPassword({
      email: authUser.user.email,
      password,
    })

    if (signInError || !session.session) {
      return error(401, 'Invalid credentials')
    }

    return json(200, {
      access_token: session.session.access_token,
      refresh_token: session.session.refresh_token,
      expires_in: session.session.expires_in,
      conductor: {
        id: profile.id,
        display_name: profile.display_name,
        username,
        bus_number: bus.bus_number,
        bus_id: bus.id,
      },
    })

  } catch (e) {
    console.error(e)
    return error(500, 'Internal server error')
  }
})

function json(status: number, body: unknown) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}
function error(status: number, message: string) {
  return json(status, { error: message })
}
