-- =============================================================
-- Migration 003: Development seed data
-- DO NOT run in production
-- =============================================================

-- Create admin user in auth.users (run via Supabase Dashboard or service-role API)
-- This seed only inserts the profile row — the auth.users entry must be created first
-- via: Supabase Dashboard > Auth > Users > Add User
-- Email: admin@college-bus.local  Password: superadmin

-- Seed buses
INSERT INTO public.buses (id, bus_number, description) VALUES
    ('11111111-0000-0000-0000-000000000001', 'V1', 'Vellore Route 1'),
    ('11111111-0000-0000-0000-000000000002', 'V2', 'Vellore Route 2'),
    ('11111111-0000-0000-0000-000000000003', 'K1', 'Katpadi Route 1'),
    ('11111111-0000-0000-0000-000000000004', 'K2', 'Katpadi Route 2')
ON CONFLICT (bus_number) DO NOTHING;

-- Seed sample students (development only)
INSERT INTO public.students (roll_number, name, academic_year, department, bus_eligible) VALUES
    ('23AD001', 'Alice Ramasamy', 'III Year', 'AI&DS', TRUE),
    ('23AD002', 'Bob Krishnan', 'III Year', 'CSE', TRUE),
    ('23AD003', 'Carol Murugan', 'III Year', 'ECE', TRUE),
    ('24AD001', 'David Selvam', 'II Year', 'AI&DS', TRUE),
    ('24AD002', 'Eva Nair', 'II Year', 'CSE', FALSE),
    ('24AD003', 'Frank Thomas', 'II Year', 'MECH', TRUE)
ON CONFLICT (roll_number) DO NOTHING;

-- Note: attendance_sessions for today can be created via admin dashboard
-- or by running:
-- INSERT INTO public.attendance_sessions (session_type, service_date, status)
-- VALUES ('morning', CURRENT_DATE, 'open'), ('evening', CURRENT_DATE, 'scheduled');
