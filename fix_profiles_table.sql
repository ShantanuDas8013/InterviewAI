-- Quick fix for missing user_profiles table
-- Run this in your Supabase SQL Editor

-- Create user_profiles table (simplified version for immediate fix)
CREATE TABLE
IF NOT EXISTS public.user_profiles
(
  id UUID REFERENCES auth.users
(id) PRIMARY KEY,
  email VARCHAR
(255) NOT NULL UNIQUE,
  full_name VARCHAR
(100) NOT NULL,
  phone_number VARCHAR
(20),
  location VARCHAR
(100),
  bio TEXT,
  profile_picture_url TEXT,
  experience_level VARCHAR
(20) DEFAULT 'entry' CHECK
(experience_level IN
('entry', 'mid', 'senior', 'executive')),
  current_company VARCHAR
(100),
  current_position VARCHAR
(100),
  linkedin_url VARCHAR
(255),
  github_url VARCHAR
(255),
  portfolio_url VARCHAR
(255),
  subscription_type VARCHAR
(20) DEFAULT 'free' CHECK
(subscription_type IN
('free', 'premium', 'enterprise')),
  total_interviews_taken INTEGER DEFAULT 0,
  average_interview_score DECIMAL
(3,2) DEFAULT 0.00,
  created_at TIMESTAMP
WITH TIME ZONE DEFAULT NOW
(),
  updated_at TIMESTAMP
WITH TIME ZONE DEFAULT NOW
()
);

-- Enable RLS
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own profile" ON public.user_profiles 
  FOR
SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON public.user_profiles 
  FOR
INSERT WITH CHECK (auth.uid() =
id);

CREATE POLICY "Users can update their own profile" ON public.user_profiles 
  FOR
UPDATE USING (auth.uid()
= id);

-- Create index for performance
CREATE INDEX
IF NOT EXISTS idx_user_profiles_email ON public.user_profiles
(email);

-- Insert a profile for existing users (optional)
-- This will create profiles for users who registered before the table existed
INSERT INTO public.user_profiles
    (id, email, full_name)
SELECT
    id,
    email,
    COALESCE(raw_user_meta_data->>'full_name', email) as full_name
FROM auth.users
WHERE id NOT IN (SELECT id
FROM public.user_profiles)
ON CONFLICT
(id) DO NOTHING;
