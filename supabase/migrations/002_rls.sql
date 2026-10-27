-- =============================================================
-- Migration 002: Row Level Security Policies
-- =============================================================

-- Helper function: get current user's role
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT role FROM public.profiles WHERE id = auth.uid();
$$;

-- Helper function: check if current user is admin
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'admin' AND is_active = TRUE
    );
$$;

-- Helper function: check if current user is active conductor
CREATE OR REPLACE FUNCTION public.is_conductor()
RETURNS BOOLEAN LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.profiles
        WHERE id = auth.uid() AND role = 'conductor' AND is_active = TRUE
    );
$$;

-- Helper: get conductor's active bus_id
CREATE OR REPLACE FUNCTION public.conductor_bus_id()
RETURNS UUID LANGUAGE sql SECURITY DEFINER STABLE AS $$
    SELECT bus_id FROM public.conductor_bus_assignments
    WHERE conductor_id = auth.uid()
      AND is_active = TRUE
      AND (valid_until IS NULL OR valid_until >= CURRENT_DATE)
    LIMIT 1;
$$;

-- =============================================================
-- PROFILES RLS
-- =============================================================
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Admins can read all profiles
CREATE POLICY profiles_admin_select ON public.profiles
    FOR SELECT TO authenticated
    USING (public.is_admin());

-- Users can read their own profile
CREATE POLICY profiles_own_select ON public.profiles
    FOR SELECT TO authenticated
    USING (id = auth.uid());

-- Admins can insert/update profiles (conductor creation)
CREATE POLICY profiles_admin_insert ON public.profiles
    FOR INSERT TO authenticated
    WITH CHECK (public.is_admin());

CREATE POLICY profiles_admin_update ON public.profiles
    FOR UPDATE TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- Users can update their own non-role fields
CREATE POLICY profiles_own_update ON public.profiles
    FOR UPDATE TO authenticated
    USING (id = auth.uid() AND NOT public.is_admin())
    WITH CHECK (id = auth.uid());

-- =============================================================
-- STUDENTS RLS
-- =============================================================
ALTER TABLE public.students ENABLE ROW LEVEL SECURITY;

-- Admins: full access
CREATE POLICY students_admin ON public.students
    FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- Conductors: select only active, bus-eligible students (for lookup)
CREATE POLICY students_conductor_select ON public.students
    FOR SELECT TO authenticated
    USING (public.is_conductor() AND is_active = TRUE);

-- =============================================================
-- BUSES RLS
-- =============================================================
ALTER TABLE public.buses ENABLE ROW LEVEL SECURITY;

CREATE POLICY buses_admin ON public.buses
    FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- Conductors can see their assigned bus only
CREATE POLICY buses_conductor_select ON public.buses
    FOR SELECT TO authenticated
    USING (public.is_conductor() AND id = public.conductor_bus_id());

-- =============================================================
-- CONDUCTOR BUS ASSIGNMENTS RLS
-- =============================================================
ALTER TABLE public.conductor_bus_assignments ENABLE ROW LEVEL SECURITY;

CREATE POLICY cba_admin ON public.conductor_bus_assignments
    FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- Conductors can see their own assignments
CREATE POLICY cba_conductor_select ON public.conductor_bus_assignments
    FOR SELECT TO authenticated
    USING (public.is_conductor() AND conductor_id = auth.uid());

-- =============================================================
-- ATTENDANCE SESSIONS RLS
-- =============================================================
ALTER TABLE public.attendance_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY sessions_admin ON public.attendance_sessions
    FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- Conductors can see open sessions
CREATE POLICY sessions_conductor_select ON public.attendance_sessions
    FOR SELECT TO authenticated
    USING (public.is_conductor() AND status = 'open');

-- =============================================================
-- ATTENDANCE RECORDS RLS
-- =============================================================
ALTER TABLE public.attendance_records ENABLE ROW LEVEL SECURITY;

CREATE POLICY attendance_admin ON public.attendance_records
    FOR ALL TO authenticated
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- Conductors: select only their bus's records for today
CREATE POLICY attendance_conductor_select ON public.attendance_records
    FOR SELECT TO authenticated
    USING (
        public.is_conductor()
        AND bus_id = public.conductor_bus_id()
        AND scanned_at::DATE = CURRENT_DATE
    );

-- Conductors INSERT goes through Edge Function (service role) — no direct insert RLS needed
-- But add a restrictive policy so direct inserts are blocked:
CREATE POLICY attendance_conductor_no_direct_insert ON public.attendance_records
    FOR INSERT TO authenticated
    WITH CHECK (FALSE); -- all conductor writes go through Edge Function

-- =============================================================
-- SCAN ERRORS RLS
-- =============================================================
ALTER TABLE public.scan_errors ENABLE ROW LEVEL SECURITY;

CREATE POLICY scan_errors_admin ON public.scan_errors
    FOR SELECT TO authenticated
    USING (public.is_admin());

-- Conductors cannot read scan errors (inserted via Edge Function)

-- =============================================================
-- AUDIT LOGS RLS
-- =============================================================
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

CREATE POLICY audit_admin_select ON public.audit_logs
    FOR SELECT TO authenticated
    USING (public.is_admin());

-- No direct inserts from client; inserted via Edge Functions / triggers

-- =============================================================
-- Grant usage to authenticated role
-- =============================================================
GRANT USAGE ON SCHEMA public TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.profiles TO authenticated;
GRANT SELECT ON public.students TO authenticated;
GRANT SELECT ON public.buses TO authenticated;
GRANT SELECT ON public.conductor_bus_assignments TO authenticated;
GRANT SELECT ON public.attendance_sessions TO authenticated;
GRANT SELECT ON public.attendance_records TO authenticated;
