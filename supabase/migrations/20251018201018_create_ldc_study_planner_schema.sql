/*
  # LDC Study Planner Database Schema

  ## Overview
  This migration creates the complete database structure for the LDC Study Planner application,
  including user profiles, subjects, study sessions, and progress tracking.

  ## New Tables

  ### 1. `profiles`
  Extends Supabase auth.users with additional user information
  - `id` (uuid, primary key) - References auth.users
  - `full_name` (text) - User's full name
  - `student_id` (text) - LDC student ID (e.g., LDC/2023/001)
  - `email` (text) - User's email address
  - `telegram_connected` (boolean) - Whether Telegram is connected
  - `telegram_chat_id` (text, nullable) - Telegram chat ID for notifications
  - `created_at` (timestamptz) - Account creation timestamp
  - `updated_at` (timestamptz) - Last update timestamp

  ### 2. `subjects`
  Stores all LDC subjects and their categories
  - `id` (uuid, primary key)
  - `name` (text) - Subject name (e.g., "Civil Proceedings I")
  - `category` (text) - Subject category (e.g., "Civil Proceedings")
  - `color_class` (text) - CSS class for color scheme
  - `order_index` (integer) - Display order
  - `created_at` (timestamptz)

  ### 3. `topics`
  Stores topics within each subject
  - `id` (uuid, primary key)
  - `subject_id` (uuid) - References subjects table
  - `name` (text) - Topic name (e.g., "Pleadings")
  - `order_index` (integer) - Display order within subject
  - `created_at` (timestamptz)

  ### 4. `user_progress`
  Tracks user's completion status for each topic
  - `id` (uuid, primary key)
  - `user_id` (uuid) - References profiles table
  - `topic_id` (uuid) - References topics table
  - `completed` (boolean) - Whether topic is completed
  - `completed_at` (timestamptz, nullable) - When topic was completed
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### 5. `study_sessions`
  Stores planned study sessions
  - `id` (uuid, primary key)
  - `user_id` (uuid) - References profiles table
  - `topic_id` (uuid) - References topics table
  - `session_date` (date) - Date of study session
  - `start_time` (time) - Session start time
  - `end_time` (time) - Session end time
  - `completed` (boolean) - Whether session was completed
  - `notes` (text, nullable) - Optional notes
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ### 6. `app_settings`
  Stores application-wide settings
  - `id` (uuid, primary key)
  - `exam_date` (timestamptz) - Target exam date
  - `setting_key` (text) - Setting identifier
  - `setting_value` (jsonb) - Setting value
  - `created_at` (timestamptz)
  - `updated_at` (timestamptz)

  ## Security
  - Row Level Security (RLS) enabled on all tables
  - Users can only access their own data
  - Subjects and topics are publicly readable
  - App settings are publicly readable but only admins can modify

  ## Indexes
  - Created on foreign keys for better query performance
  - Created on commonly queried fields
*/

-- Enable UUID extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- =====================================================
-- PROFILES TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS profiles (
  id uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  full_name text NOT NULL,
  student_id text UNIQUE,
  email text NOT NULL,
  telegram_connected boolean DEFAULT false,
  telegram_chat_id text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own profile"
  ON profiles FOR SELECT
  TO authenticated
  USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
  ON profiles FOR UPDATE
  TO authenticated
  USING (auth.uid() = id)
  WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can insert own profile"
  ON profiles FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = id);

-- =====================================================
-- SUBJECTS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS subjects (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  name text NOT NULL,
  category text NOT NULL,
  color_class text NOT NULL,
  order_index integer NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE subjects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view subjects"
  ON subjects FOR SELECT
  TO authenticated
  USING (true);

-- =====================================================
-- TOPICS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS topics (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  subject_id uuid NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
  name text NOT NULL,
  order_index integer NOT NULL,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE topics ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view topics"
  ON topics FOR SELECT
  TO authenticated
  USING (true);

-- Create index on subject_id for faster queries
CREATE INDEX IF NOT EXISTS idx_topics_subject_id ON topics(subject_id);

-- =====================================================
-- USER PROGRESS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS user_progress (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  topic_id uuid NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
  completed boolean DEFAULT false,
  completed_at timestamptz,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now(),
  UNIQUE(user_id, topic_id)
);

ALTER TABLE user_progress ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own progress"
  ON user_progress FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own progress"
  ON user_progress FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own progress"
  ON user_progress FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own progress"
  ON user_progress FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_user_progress_user_id ON user_progress(user_id);
CREATE INDEX IF NOT EXISTS idx_user_progress_topic_id ON user_progress(topic_id);

-- =====================================================
-- STUDY SESSIONS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS study_sessions (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id uuid NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  topic_id uuid NOT NULL REFERENCES topics(id) ON DELETE CASCADE,
  session_date date NOT NULL,
  start_time time NOT NULL,
  end_time time NOT NULL,
  completed boolean DEFAULT false,
  notes text,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE study_sessions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own sessions"
  ON study_sessions FOR SELECT
  TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own sessions"
  ON study_sessions FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own sessions"
  ON study_sessions FOR UPDATE
  TO authenticated
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete own sessions"
  ON study_sessions FOR DELETE
  TO authenticated
  USING (auth.uid() = user_id);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_study_sessions_user_id ON study_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_study_sessions_date ON study_sessions(session_date);
CREATE INDEX IF NOT EXISTS idx_study_sessions_topic_id ON study_sessions(topic_id);

-- =====================================================
-- APP SETTINGS TABLE
-- =====================================================
CREATE TABLE IF NOT EXISTS app_settings (
  id uuid PRIMARY KEY DEFAULT uuid_generate_v4(),
  setting_key text UNIQUE NOT NULL,
  setting_value jsonb NOT NULL,
  created_at timestamptz DEFAULT now(),
  updated_at timestamptz DEFAULT now()
);

ALTER TABLE app_settings ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view app settings"
  ON app_settings FOR SELECT
  TO authenticated
  USING (true);

-- =====================================================
-- SEED DATA: Subjects and Topics
-- =====================================================

-- Insert subjects
INSERT INTO subjects (name, category, color_class, order_index) VALUES
  ('Civil Proceedings I', 'Civil Proceedings', 'bg-civil', 1),
  ('Civil Proceedings II', 'Civil Proceedings', 'bg-civil', 2),
  ('Criminal Proceedings I', 'Criminal Proceedings', 'bg-criminal', 3),
  ('Criminal Proceedings II', 'Criminal Proceedings', 'bg-criminal', 4),
  ('Family Law Practice I', 'Family Law Practice', 'bg-family', 5),
  ('Family Law Practice II', 'Family Law Practice', 'bg-family', 6),
  ('Corporate & Commercial Practice I', 'Corporate & Commercial Practice', 'bg-corporate', 7),
  ('Corporate & Commercial Practice II', 'Corporate & Commercial Practice', 'bg-corporate', 8),
  ('Land Practice I', 'Land Practice', 'bg-land', 9),
  ('Land Practice II', 'Land Practice', 'bg-land', 10)
ON CONFLICT DO NOTHING;

-- Insert topics for Civil Proceedings I
INSERT INTO topics (subject_id, name, order_index)
SELECT id, 'Pleadings', 1 FROM subjects WHERE name = 'Civil Proceedings I'
UNION ALL
SELECT id, 'Interlocutory Applications', 2 FROM subjects WHERE name = 'Civil Proceedings I'
UNION ALL
SELECT id, 'Trials', 3 FROM subjects WHERE name = 'Civil Proceedings I'
ON CONFLICT DO NOTHING;

-- Insert topics for Civil Proceedings II
INSERT INTO topics (subject_id, name, order_index)
SELECT id, 'Judgment & Appeals', 1 FROM subjects WHERE name = 'Civil Proceedings II'
UNION ALL
SELECT id, 'Execution of Decrees', 2 FROM subjects WHERE name = 'Civil Proceedings II'
ON CONFLICT DO NOTHING;

-- Insert topics for Criminal Proceedings I
INSERT INTO topics (subject_id, name, order_index)
SELECT id, 'Jurisdiction', 1 FROM subjects WHERE name = 'Criminal Proceedings I'
UNION ALL
SELECT id, 'Charge & Information', 2 FROM subjects WHERE name = 'Criminal Proceedings I'
UNION ALL
SELECT id, 'Bail & Remand', 3 FROM subjects WHERE name = 'Criminal Proceedings I'
ON CONFLICT DO NOTHING;

-- Insert topics for Criminal Proceedings II
INSERT INTO topics (subject_id, name, order_index)
SELECT id, 'Trial Process', 1 FROM subjects WHERE name = 'Criminal Proceedings II'
UNION ALL
SELECT id, 'Sentencing & Appeals', 2 FROM subjects WHERE name = 'Criminal Proceedings II'
ON CONFLICT DO NOTHING;

-- Insert topics for Family Law Practice I
INSERT INTO topics (subject_id, name, order_index)
SELECT id, 'Marriage & Divorce', 1 FROM subjects WHERE name = 'Family Law Practice I'
UNION ALL
SELECT id, 'Custody & Maintenance', 2 FROM subjects WHERE name = 'Family Law Practice I'
UNION ALL
SELECT id, 'Adoption & Guardianship', 3 FROM subjects WHERE name = 'Family Law Practice I'
ON CONFLICT DO NOTHING;

-- Insert topics for Family Law Practice II
INSERT INTO topics (subject_id, name, order_index)
SELECT id, 'Matrimonial Property', 1 FROM subjects WHERE name = 'Family Law Practice II'
UNION ALL
SELECT id, 'Domestic Violence', 2 FROM subjects WHERE name = 'Family Law Practice II'
ON CONFLICT DO NOTHING;

-- Insert topics for Corporate & Commercial Practice I
INSERT INTO topics (subject_id, name, order_index)
SELECT id, 'Company Formation', 1 FROM subjects WHERE name = 'Corporate & Commercial Practice I'
UNION ALL
SELECT id, 'Contracts', 2 FROM subjects WHERE name = 'Corporate & Commercial Practice I'
UNION ALL
SELECT id, 'Insolvency', 3 FROM subjects WHERE name = 'Corporate & Commercial Practice I'
ON CONFLICT DO NOTHING;

-- Insert topics for Corporate & Commercial Practice II
INSERT INTO topics (subject_id, name, order_index)
SELECT id, 'Mergers & Acquisitions', 1 FROM subjects WHERE name = 'Corporate & Commercial Practice II'
UNION ALL
SELECT id, 'Taxation', 2 FROM subjects WHERE name = 'Corporate & Commercial Practice II'
ON CONFLICT DO NOTHING;

-- Insert topics for Land Practice I
INSERT INTO topics (subject_id, name, order_index)
SELECT id, 'Land Registration', 1 FROM subjects WHERE name = 'Land Practice I'
UNION ALL
SELECT id, 'Conveyancing', 2 FROM subjects WHERE name = 'Land Practice I'
UNION ALL
SELECT id, 'Mortgages', 3 FROM subjects WHERE name = 'Land Practice I'
ON CONFLICT DO NOTHING;

-- Insert topics for Land Practice II
INSERT INTO topics (subject_id, name, order_index)
SELECT id, 'Leases', 1 FROM subjects WHERE name = 'Land Practice II'
UNION ALL
SELECT id, 'Dispute Resolution', 2 FROM subjects WHERE name = 'Land Practice II'
ON CONFLICT DO NOTHING;

-- Insert exam date setting
INSERT INTO app_settings (setting_key, setting_value)
VALUES ('exam_date', '"2025-12-07T12:00:00Z"'::jsonb)
ON CONFLICT (setting_key) DO NOTHING;

-- =====================================================
-- FUNCTIONS AND TRIGGERS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Triggers for updated_at
DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_progress_updated_at ON user_progress;
CREATE TRIGGER update_user_progress_updated_at
  BEFORE UPDATE ON user_progress
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_study_sessions_updated_at ON study_sessions;
CREATE TRIGGER update_study_sessions_updated_at
  BEFORE UPDATE ON study_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_app_settings_updated_at ON app_settings;
CREATE TRIGGER update_app_settings_updated_at
  BEFORE UPDATE ON app_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
