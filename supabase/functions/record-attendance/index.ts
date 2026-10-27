// Edge Function: record-attendance
// Validates all business rules server-side and inserts attendance record
// Called by conductor app with user JWT — uses service role internally

/// <reference path="../types.d.ts" />

import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface AttendanceRequest {
  roll_number: string
  session_id: string
  idempotency_key: string // client-generated UUID to prevent duplicate submissions
}

Deno.serve(async (req: Request) => {
  if (req.method === 'OPTIONS') return new Response('ok', { headers: corsHeaders })

  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) return error(401, 'Missing authorization')

    // Service client for privileged operations
    const service = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    )

    // User client to validate JWT and get caller identity
    const userClient = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } },
    )

    const { data: { user }, error: authError } = await userClient.auth.getUser()
    if (authError || !user) return error(401, 'Invalid session')

    const body: AttendanceRequest = await req.json()
    const roll = body.roll_number?.trim().toUpperCase()
    if (!roll || !body.session_id || !body.idempotency_key) {
      return error(400, 'Missing required fields')
    }

    // 1. Verify conductor profile
    const { data: profile } = await service
      .from('profiles')
      .select('id, role, is_active, display_name')
      .eq('id', user.id)
      .single()

    if (!profile || profile.role !== 'conductor' || !profile.is_active) {
      return error(403, 'Unauthorized: not an active conductor')
    }

    // 2. Get conductor's active bus assignment
    const { data: assignment } = await service
      .from('conductor_bus_assignments')
      .select('bus_id, buses(bus_number)')
      .eq('conductor_id', user.id)
      .eq('is_active', true)
      .or(`valid_until.is.null,valid_until.gte.${new Date().toISOString().split('T')[0]}`)
      .single()

    if (!assignment) return error(403, 'No active bus assignment')

    // 3. Verify session is open
    const { data: session } = await service
      .from('attendance_sessions')
      .select('id, session_type, service_date, status')
      .eq('id', body.session_id)
      .eq('status', 'open')
      .single()

    if (!session) {
      await service.from('scan_errors').insert({
        conductor_id: user.id,
        bus_id: assignment.bus_id,
        session_id: body.session_id,
        scanned_value: roll,
        error_type: 'session_closed',
      })
      return error(409, 'Session is not open')
    }

    // 4. Look up student
    const { data: student } = await service
      .from('students')
      .select('id, name, roll_number, department, academic_year, is_active, bus_eligible')
      .eq('roll_number', roll)
      .single()

    if (!student) {
      await service.from('scan_errors').insert({
        conductor_id: user.id,
        bus_id: assignment.bus_id,
        session_id: session.id,
        scanned_value: roll,
        error_type: 'unknown_student',
      })
      return error(404, 'Student not found', { roll_number: roll })
    }

    if (!student.is_active) {
      await service.from('scan_errors').insert({
        conductor_id: user.id,
        bus_id: assignment.bus_id,
        session_id: session.id,
        scanned_value: roll,
        error_type: 'inactive_student',
      })
      return error(422, 'Student is inactive')
    }

    // 5. Check duplicate (using upsert with ON CONFLICT DO NOTHING equivalent)
    const { data: existing } = await service
      .from('attendance_records')
      .select('id, scanned_at')
      .eq('student_id', student.id)
      .eq('session_id', session.id)
      .single()

    if (existing) {
      return json(200, {
        status: 'duplicate',
        message: 'Already marked',
        attendance_id: existing.id,
        scanned_at: existing.scanned_at,
        student,
      })
    }

    // 6. Insert attendance record
    const { data: record, error: insertError } = await service
      .from('attendance_records')
      .insert({
        student_id: student.id,
        session_id: session.id,
        bus_id: assignment.bus_id,
        conductor_id: user.id,
        scanned_roll_number: roll,
        scanned_at: new Date().toISOString(),
      })
      .select()
      .single()

    if (insertError) {
      // Unique constraint violation = race condition duplicate
      if (insertError.code === '23505') {
        return json(200, { status: 'duplicate', message: 'Already marked (concurrent)' })
      }
      console.error('Insert error:', insertError)
      return error(500, 'Failed to record attendance')
    }

    return json(201, {
      status: 'success',
      message: 'Attendance recorded',
      attendance_id: record.id,
      scanned_at: record.scanned_at,
      student,
      session: { type: session.session_type, date: session.service_date },
      bus_number: (assignment.buses as any)?.bus_number,
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

function error(status: number, message: string, extra?: Record<string, unknown>) {
  return json(status, { status: 'error', message, ...(extra ?? {}) })
}
