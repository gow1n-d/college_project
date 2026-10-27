-- =============================================================
-- Migration 001: Full schema for College Bus Attendance System
-- Run in Supabase SQL Editor or via supabase db push
-- =============================================================

-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =============================================================
-- PROFILES (extends auth.users)
-- =============================================================
CREATE TABLE IF NOT EXISTS public.profiles (
    id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    username      TEXT UNIQUE NOT NULL,
    display_name  TEXT NOT NULL,
    role          TEXT NOT NULL CHECK (role IN ('admin', 'conductor')),
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Prevent clients from self-assigning admin role via trigger
CREATE OR REPLACE FUNCTION public.prevent_role_self_assign()
RETURNS TRIGGER LANGUAGE plpgsql SECURITY DEFINER AS $$
BEGIN
    -- Only service-role can set role=admin on INSERT
    -- On UPDATE, only service-role can change the role field
    IF TG_OP = 'INSERT' AND NEW.role = 'admin' THEN
        IF current_setting('role') != 'service_role' THEN
            RAISE EXCEPTION 'Cannot self-assign admin role';
        END IF;
    END IF;
    IF TG_OP = 'UPDATE' AND NEW.role != OLD.role THEN
        IF current_setting('role') != 'service_role' THEN
            RAISE EXCEPTION 'Cannot change role without service privileges';
        END IF;
    END IF;
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_profiles_role_guard
    BEFORE INSERT OR UPDATE ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.prevent_role_self_assign();

-- =============================================================
-- STUDENTS
-- =============================================================
CREATE TABLE IF NOT EXISTS public.students (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    roll_number   TEXT UNIQUE NOT NULL,
    name          TEXT NOT NULL,
    academic_year TEXT NOT NULL,
    department    TEXT NOT NULL,
    bus_eligible  BOOLEAN NOT NULL DEFAULT TRUE,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_students_roll ON public.students (roll_number);
CREATE INDEX IF NOT EXISTS idx_students_dept ON public.students (department);
CREATE INDEX IF NOT EXISTS idx_students_year ON public.students (academic_year);
CREATE INDEX IF NOT EXISTS idx_students_active ON public.students (is_active, bus_eligible);

CREATE OR REPLACE FUNCTION public.update_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN NEW.updated_at = NOW(); RETURN NEW; END;
$$;

CREATE TRIGGER trg_students_updated_at
    BEFORE UPDATE ON public.students
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- =============================================================
-- BUSES
-- =============================================================
CREATE TABLE IF NOT EXISTS public.buses (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bus_number    TEXT UNIQUE NOT NULL,
    description   TEXT,
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_buses_number ON public.buses (bus_number);

CREATE TRIGGER trg_buses_updated_at
    BEFORE UPDATE ON public.buses
    FOR EACH ROW EXECUTE FUNCTION public.update_updated_at();

-- =============================================================
-- CONDUCTOR BUS ASSIGNMENTS
-- =============================================================
CREATE TABLE IF NOT EXISTS public.conductor_bus_assignments (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conductor_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    bus_id        UUID NOT NULL REFERENCES public.buses(id) ON DELETE CASCADE,
    valid_from    DATE NOT NULL DEFAULT CURRENT_DATE,
    valid_until   DATE,  -- NULL = open-ended
    is_active     BOOLEAN NOT NULL DEFAULT TRUE,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Only one active assignment per conductor at a time
CREATE UNIQUE INDEX IF NOT EXISTS idx_cba_active_conductor
    ON public.conductor_bus_assignments (conductor_id)
    WHERE is_active = TRUE AND (valid_until IS NULL OR valid_until >= CURRENT_DATE);

CREATE INDEX IF NOT EXISTS idx_cba_bus ON public.conductor_bus_assignments (bus_id);
CREATE INDEX IF NOT EXISTS idx_cba_conductor ON public.conductor_bus_assignments (conductor_id);

-- =============================================================
-- ATTENDANCE SESSIONS
-- =============================================================
CREATE TABLE IF NOT EXISTS public.attendance_sessions (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_type  TEXT NOT NULL CHECK (session_type IN ('morning', 'evening')),
    service_date  DATE NOT NULL,
    status        TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'open', 'closed')),
    opens_at      TIMESTAMPTZ,
    closes_at     TIMESTAMPTZ,
    created_by    UUID REFERENCES public.profiles(id),
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- One session type per day
CREATE UNIQUE INDEX IF NOT EXISTS idx_sessions_type_date
    ON public.attendance_sessions (session_type, service_date);

CREATE INDEX IF NOT EXISTS idx_sessions_date ON public.attendance_sessions (service_date);
CREATE INDEX IF NOT EXISTS idx_sessions_status ON public.attendance_sessions (status);

-- =============================================================
-- ATTENDANCE RECORDS
-- =============================================================
CREATE TABLE IF NOT EXISTS public.attendance_records (
    id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    student_id           UUID NOT NULL REFERENCES public.students(id),
    session_id           UUID NOT NULL REFERENCES public.attendance_sessions(id),
    bus_id               UUID NOT NULL REFERENCES public.buses(id),
    conductor_id         UUID NOT NULL REFERENCES public.profiles(id),
    scanned_roll_number  TEXT NOT NULL,
    scanned_at           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at           TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Core business rule: one record per student per session
CREATE UNIQUE INDEX IF NOT EXISTS idx_attendance_student_session
    ON public.attendance_records (student_id, session_id);

CREATE INDEX IF NOT EXISTS idx_attendance_session ON public.attendance_records (session_id);
CREATE INDEX IF NOT EXISTS idx_attendance_bus ON public.attendance_records (bus_id);
CREATE INDEX IF NOT EXISTS idx_attendance_conductor ON public.attendance_records (conductor_id);
CREATE INDEX IF NOT EXISTS idx_attendance_scanned_at ON public.attendance_records (scanned_at DESC);

-- =============================================================
-- SCAN ERRORS (for admin review)
-- =============================================================
CREATE TABLE IF NOT EXISTS public.scan_errors (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conductor_id   UUID REFERENCES public.profiles(id),
    bus_id         UUID REFERENCES public.buses(id),
    session_id     UUID REFERENCES public.attendance_sessions(id),
    scanned_value  TEXT NOT NULL,
    error_type     TEXT NOT NULL CHECK (error_type IN (
        'unknown_student', 'duplicate', 'session_closed',
        'unauthorized', 'inactive_student', 'other'
    )),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_scan_errors_session ON public.scan_errors (session_id);
CREATE INDEX IF NOT EXISTS idx_scan_errors_conductor ON public.scan_errors (conductor_id);

-- =============================================================
-- AUDIT LOGS
-- =============================================================
CREATE TABLE IF NOT EXISTS public.audit_logs (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id     UUID REFERENCES public.profiles(id),
    action       TEXT NOT NULL,
    entity_type  TEXT NOT NULL,
    entity_id    UUID,
    details      JSONB NOT NULL DEFAULT '{}',
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_audit_actor ON public.audit_logs (actor_id);
CREATE INDEX IF NOT EXISTS idx_audit_entity ON public.audit_logs (entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_created ON public.audit_logs (created_at DESC);

-- =============================================================
-- Enable Realtime on attendance_records
-- =============================================================
ALTER PUBLICATION supabase_realtime ADD TABLE public.attendance_records;
ALTER PUBLICATION supabase_realtime ADD TABLE public.attendance_sessions;
