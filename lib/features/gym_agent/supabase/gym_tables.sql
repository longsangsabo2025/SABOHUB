-- ============================================
-- GYM AGENT TABLES — Supabase Migration
-- ============================================
-- For SABOHUB's Gym Coach AI Agent feature.
-- Tables: gym_profiles, gym_sessions, gym_exercise_logs, gym_set_logs
-- ============================================

-- ─── 1. GYM PROFILES ────────────────────────
-- Store user gym profile (level, goal, body metrics, training preferences)
CREATE TABLE IF NOT EXISTS public.gym_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  level TEXT NOT NULL DEFAULT 'intermediate' CHECK (level IN ('beginner', 'intermediate', 'advanced')),
  goal TEXT NOT NULL DEFAULT 'muscle_gain' CHECK (goal IN ('muscle_gain', 'fat_loss', 'strength', 'health', 'endurance')),
  weight DOUBLE PRECISION,
  height DOUBLE PRECISION,
  age INTEGER CHECK (age > 0 AND age < 150),
  training_days_per_week INTEGER NOT NULL DEFAULT 4 CHECK (training_days_per_week BETWEEN 1 AND 7),
  injuries TEXT[] DEFAULT '{}',
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE(user_id)
);

-- ─── 2. GYM SESSIONS ────────────────────────
-- A completed workout session
CREATE TABLE IF NOT EXISTS public.gym_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  workout_name TEXT NOT NULL,
  workout_type TEXT NOT NULL DEFAULT 'custom' CHECK (workout_type IN ('push', 'pull', 'legs', 'upper', 'lower', 'fullBody', 'cardio', 'custom')),
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  ended_at TIMESTAMPTZ,
  notes TEXT,
  mood_rating INTEGER CHECK (mood_rating BETWEEN 1 AND 5),
  energy_level INTEGER CHECK (energy_level BETWEEN 1 AND 5),
  body_weight DOUBLE PRECISION,
  is_ai_generated BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── 3. GYM EXERCISE LOGS ───────────────────
-- Each exercise performed in a session
CREATE TABLE IF NOT EXISTS public.gym_exercise_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID NOT NULL REFERENCES public.gym_sessions(id) ON DELETE CASCADE,
  exercise_id TEXT NOT NULL,
  exercise_name TEXT NOT NULL,
  sort_order INTEGER NOT NULL DEFAULT 0,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── 4. GYM SET LOGS ────────────────────────
-- Each set performed for an exercise
CREATE TABLE IF NOT EXISTS public.gym_set_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  exercise_log_id UUID NOT NULL REFERENCES public.gym_exercise_logs(id) ON DELETE CASCADE,
  set_number INTEGER NOT NULL,
  reps INTEGER,
  weight DOUBLE PRECISION,
  duration_seconds INTEGER,
  distance_meters DOUBLE PRECISION,
  set_type TEXT NOT NULL DEFAULT 'working' CHECK (set_type IN ('warmup', 'working', 'dropset', 'failure', 'rest_pause')),
  rpe DOUBLE PRECISION CHECK (rpe BETWEEN 1 AND 10),
  is_pr BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── 5. GYM CHAT HISTORY ────────────────────
-- Persist AI coaching conversations
CREATE TABLE IF NOT EXISTS public.gym_chat_messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  session_id TEXT, -- client-side session grouping
  role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
  content TEXT NOT NULL,
  message_type TEXT NOT NULL DEFAULT 'text' CHECK (message_type IN ('text', 'workoutPlan', 'exerciseRecommendation', 'nutritionAdvice', 'progressAnalysis', 'formCorrection')),
  tokens_used INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─── INDEXES ─────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_gym_profiles_user ON public.gym_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_gym_sessions_user ON public.gym_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_gym_sessions_started ON public.gym_sessions(user_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_gym_exercise_logs_session ON public.gym_exercise_logs(session_id);
CREATE INDEX IF NOT EXISTS idx_gym_set_logs_exercise ON public.gym_set_logs(exercise_log_id);
CREATE INDEX IF NOT EXISTS idx_gym_chat_user ON public.gym_chat_messages(user_id, created_at DESC);

-- ─── RLS POLICIES ────────────────────────────
ALTER TABLE public.gym_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gym_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gym_exercise_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gym_set_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.gym_chat_messages ENABLE ROW LEVEL SECURITY;

-- Users can only see/edit their own data
CREATE POLICY gym_profiles_own ON public.gym_profiles
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY gym_sessions_own ON public.gym_sessions
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY gym_exercise_logs_own ON public.gym_exercise_logs
  FOR ALL USING (
    session_id IN (SELECT id FROM public.gym_sessions WHERE user_id = auth.uid())
  );

CREATE POLICY gym_set_logs_own ON public.gym_set_logs
  FOR ALL USING (
    exercise_log_id IN (
      SELECT el.id FROM public.gym_exercise_logs el
      JOIN public.gym_sessions s ON el.session_id = s.id
      WHERE s.user_id = auth.uid()
    )
  );

CREATE POLICY gym_chat_own ON public.gym_chat_messages
  FOR ALL USING (auth.uid() = user_id);

-- ─── UPDATED_AT TRIGGER ─────────────────────
CREATE OR REPLACE FUNCTION update_gym_profile_timestamp()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER gym_profile_updated
  BEFORE UPDATE ON public.gym_profiles
  FOR EACH ROW EXECUTE FUNCTION update_gym_profile_timestamp();
