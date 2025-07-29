# AI Voice Interview App - Database Schema Structure

## Overview

This document outlines the complete database schema for the AI-driven voice interview application using **Supabase** as the backend. The schema is designed to support user authentication, resume analysis, AI-powered interviews, and comprehensive performance analytics.

---

## Table of Contents

1. [Authentication & User Management](#authentication--user-management)
2. [Resume Management](#resume-management)
3. [Job Roles & Questions](#job-roles--questions)
4. [Interview Management](#interview-management)
5. [Analytics & Performance](#analytics--performance)
6. [System Configuration](#system-configuration)
7. [Indexes & Constraints](#indexes--constraints)
8. [Storage Buckets](#storage-buckets)

---

## Authentication & User Management

### 1. users (extends Supabase auth.users)

```sql
-- This table extends the default Supabase auth.users table
-- Additional user profile information
CREATE TABLE public.user_profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  full_name VARCHAR(100) NOT NULL,
  phone_number VARCHAR(20),
  date_of_birth DATE,
  gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
  location VARCHAR(100),
  bio TEXT,
  profile_picture_url TEXT,
  preferred_job_roles TEXT[], -- Array of preferred job role IDs
  experience_level VARCHAR(20) CHECK (experience_level IN ('entry', 'mid', 'senior', 'executive')),
  current_company VARCHAR(100),
  current_position VARCHAR(100),
  linkedin_url VARCHAR(255),
  github_url VARCHAR(255),
  portfolio_url VARCHAR(255),
  subscription_type VARCHAR(20) DEFAULT 'free' CHECK (subscription_type IN ('free', 'premium', 'enterprise')),
  subscription_expires_at TIMESTAMP WITH TIME ZONE,
  total_interviews_taken INTEGER DEFAULT 0,
  average_interview_score DECIMAL(3,2) DEFAULT 0.00,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## Resume Management

### 2. resumes

```sql
CREATE TABLE public.resumes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  file_name VARCHAR(255) NOT NULL,
  file_path TEXT NOT NULL, -- Supabase Storage path
  file_size_bytes BIGINT NOT NULL,
  upload_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE,
  is_analyzed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 3. resume_analysis

```sql
CREATE TABLE public.resume_analysis (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  resume_id UUID REFERENCES public.resumes(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,

  -- Overall Analysis
  overall_score DECIMAL(3,2) NOT NULL CHECK (overall_score >= 0 AND overall_score <= 10),
  overall_feedback TEXT NOT NULL,

  -- Section-wise Analysis
  contact_info_score DECIMAL(3,2) CHECK (contact_info_score >= 0 AND contact_info_score <= 10),
  summary_score DECIMAL(3,2) CHECK (summary_score >= 0 AND summary_score <= 10),
  experience_score DECIMAL(3,2) CHECK (experience_score >= 0 AND experience_score <= 10),
  education_score DECIMAL(3,2) CHECK (education_score >= 0 AND education_score <= 10),
  skills_score DECIMAL(3,2) CHECK (skills_score >= 0 AND skills_score <= 10),
  projects_score DECIMAL(3,2) CHECK (projects_score >= 0 AND projects_score <= 10),

  -- Extracted Information
  extracted_skills TEXT[], -- Array of skills found
  extracted_experience_years INTEGER,
  extracted_education_level VARCHAR(50),
  extracted_companies TEXT[], -- Previous companies
  extracted_job_titles TEXT[], -- Previous job titles

  -- Recommendations
  missing_sections TEXT[],
  improvement_suggestions TEXT[],
  recommended_job_roles TEXT[], -- Based on resume analysis

  -- Keywords Analysis
  relevant_keywords TEXT[],
  missing_keywords TEXT[],
  keyword_density JSONB, -- {"keyword": count}

  -- ATS Compatibility
  ats_score DECIMAL(3,2) CHECK (ats_score >= 0 AND ats_score <= 10),
  ats_issues TEXT[],

  -- Gemini AI Analysis Results
  gemini_analysis_raw JSONB, -- Raw response from Gemini API

  analyzed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## Job Roles & Questions

### 4. job_roles

```sql
CREATE TABLE public.job_roles (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  title VARCHAR(100) NOT NULL UNIQUE,
  category VARCHAR(50) NOT NULL, -- e.g., 'technology', 'marketing', 'finance'
  description TEXT,
  required_skills TEXT[] NOT NULL,
  experience_levels VARCHAR(20)[] DEFAULT ARRAY['entry', 'mid', 'senior'], -- Applicable experience levels
  industry VARCHAR(50),
  average_salary_range VARCHAR(50), -- e.g., "$50k-$80k"
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 5. interview_questions

```sql
CREATE TABLE public.interview_questions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  job_role_id UUID REFERENCES public.job_roles(id) ON DELETE CASCADE,
  question_text TEXT NOT NULL,
  question_type VARCHAR(30) NOT NULL CHECK (question_type IN ('technical', 'behavioral', 'situational', 'general')),
  difficulty_level VARCHAR(20) NOT NULL CHECK (difficulty_level IN ('easy', 'medium', 'hard')),
  expected_answer_keywords TEXT[], -- Keywords that should be in a good answer
  sample_answer TEXT,
  evaluation_criteria JSONB, -- Criteria for scoring the answer
  time_limit_seconds INTEGER DEFAULT 120,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## Interview Management

### 6. interview_sessions

```sql
CREATE TABLE public.interview_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  job_role_id UUID REFERENCES public.job_roles(id) ON DELETE SET NULL,
  resume_id UUID REFERENCES public.resumes(id) ON DELETE SET NULL,

  -- Session Details
  session_name VARCHAR(100),
  session_type VARCHAR(20) DEFAULT 'practice' CHECK (session_type IN ('practice', 'assessment', 'mock')),
  status VARCHAR(20) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled', 'paused')),

  -- Timing
  scheduled_at TIMESTAMP WITH TIME ZONE,
  started_at TIMESTAMP WITH TIME ZONE,
  completed_at TIMESTAMP WITH TIME ZONE,
  duration_seconds INTEGER,

  -- Configuration
  total_questions INTEGER DEFAULT 10,
  questions_answered INTEGER DEFAULT 0,
  difficulty_level VARCHAR(20) DEFAULT 'medium' CHECK (difficulty_level IN ('easy', 'medium', 'hard', 'mixed')),

  -- Results
  overall_score DECIMAL(3,2) CHECK (overall_score >= 0 AND overall_score <= 10),
  technical_score DECIMAL(3,2) CHECK (technical_score >= 0 AND technical_score <= 10),
  communication_score DECIMAL(3,2) CHECK (communication_score >= 0 AND communication_score <= 10),
  confidence_score DECIMAL(3,2) CHECK (confidence_score >= 0 AND confidence_score <= 10),

  -- AI Analysis
  ai_feedback TEXT,
  strengths TEXT[],
  areas_for_improvement TEXT[],
  recommendations TEXT[],

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 7. interview_responses

```sql
CREATE TABLE public.interview_responses (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  interview_session_id UUID REFERENCES public.interview_sessions(id) ON DELETE CASCADE,
  question_id UUID REFERENCES public.interview_questions(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,

  -- Response Details
  question_order INTEGER NOT NULL,
  audio_file_path TEXT, -- Path to recorded audio in Supabase Storage
  transcribed_text TEXT,
  response_duration_seconds INTEGER,

  -- Scoring
  response_score DECIMAL(3,2) CHECK (response_score >= 0 AND response_score <= 10),
  technical_accuracy DECIMAL(3,2) CHECK (technical_accuracy >= 0 AND technical_accuracy <= 10),
  communication_clarity DECIMAL(3,2) CHECK (communication_clarity >= 0 AND communication_clarity <= 10),
  relevance_score DECIMAL(3,2) CHECK (relevance_score >= 0 AND relevance_score <= 10),

  -- AI Analysis
  ai_feedback TEXT,
  keywords_mentioned TEXT[],
  missing_keywords TEXT[],
  suggested_improvement TEXT,
  ideal_answer_comparison TEXT,

  -- Speech Analysis
  speech_pace DECIMAL(5,2), -- Words per minute
  filler_words_count INTEGER DEFAULT 0,
  confidence_level DECIMAL(3,2) CHECK (confidence_level >= 0 AND confidence_level <= 10),

  -- Gemini Analysis
  gemini_analysis_raw JSONB,

  answered_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## Analytics & Performance

### 8. user_analytics

```sql
CREATE TABLE public.user_analytics (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,

  -- Performance Metrics
  total_interviews INTEGER DEFAULT 0,
  completed_interviews INTEGER DEFAULT 0,
  average_score DECIMAL(3,2) DEFAULT 0.00,
  best_score DECIMAL(3,2) DEFAULT 0.00,
  latest_score DECIMAL(3,2) DEFAULT 0.00,

  -- Progress Tracking
  skill_improvements JSONB, -- Track improvement in different skills over time
  weakness_areas TEXT[],
  strength_areas TEXT[],

  -- Time-based Analytics
  total_practice_time_minutes INTEGER DEFAULT 0,
  sessions_this_week INTEGER DEFAULT 0,
  sessions_this_month INTEGER DEFAULT 0,

  -- Job Role Performance
  preferred_job_roles JSONB, -- Performance per job role

  last_updated TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 9. interview_feedback

```sql
CREATE TABLE public.interview_feedback (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  interview_session_id UUID REFERENCES public.interview_sessions(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,

  -- Detailed Feedback Categories
  technical_feedback JSONB, -- Detailed technical assessment
  behavioral_feedback JSONB, -- Behavioral assessment
  communication_feedback JSONB, -- Communication skills assessment

  -- Improvement Plan
  short_term_goals TEXT[],
  long_term_goals TEXT[],
  recommended_resources JSONB, -- Links, courses, books, etc.
  practice_suggestions TEXT[],

  -- Comparative Analysis
  industry_benchmark_comparison JSONB,
  peer_comparison JSONB,

  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## System Configuration

### 10. app_settings

```sql
CREATE TABLE public.app_settings (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  setting_key VARCHAR(100) NOT NULL UNIQUE,
  setting_value JSONB NOT NULL,
  description TEXT,
  is_active BOOLEAN DEFAULT TRUE,
  updated_by UUID REFERENCES public.user_profiles(id),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### 11. gemini_api_logs

```sql
CREATE TABLE public.gemini_api_logs (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
  api_endpoint VARCHAR(255) NOT NULL,
  request_type VARCHAR(50) NOT NULL, -- 'resume_analysis', 'interview_evaluation', etc.
  request_payload JSONB,
  response_payload JSONB,
  tokens_used INTEGER,
  processing_time_ms INTEGER,
  status VARCHAR(20) NOT NULL, -- 'success', 'error', 'timeout'
  error_message TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## Indexes & Constraints

```sql
-- Performance Indexes
CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
CREATE INDEX idx_resumes_user_id ON public.resumes(user_id);
CREATE INDEX idx_resumes_is_active ON public.resumes(is_active);
CREATE INDEX idx_interview_sessions_user_id ON public.interview_sessions(user_id);
CREATE INDEX idx_interview_sessions_status ON public.interview_sessions(status);
CREATE INDEX idx_interview_responses_session_id ON public.interview_responses(interview_session_id);
CREATE INDEX idx_job_roles_category ON public.job_roles(category);
CREATE INDEX idx_interview_questions_job_role_id ON public.interview_questions(job_role_id);
CREATE INDEX idx_interview_questions_difficulty ON public.interview_questions(difficulty_level);

-- Composite Indexes
CREATE INDEX idx_interview_sessions_user_status ON public.interview_sessions(user_id, status);
CREATE INDEX idx_interview_responses_session_order ON public.interview_responses(interview_session_id, question_order);

-- Updated At Triggers (for automatic timestamp updates)
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply triggers to relevant tables
CREATE TRIGGER update_user_profiles_updated_at BEFORE UPDATE ON public.user_profiles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_resumes_updated_at BEFORE UPDATE ON public.resumes FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_job_roles_updated_at BEFORE UPDATE ON public.job_roles FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_interview_questions_updated_at BEFORE UPDATE ON public.interview_questions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_interview_sessions_updated_at BEFORE UPDATE ON public.interview_sessions FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER update_app_settings_updated_at BEFORE UPDATE ON public.app_settings FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
```

---

## Storage Buckets

### Supabase Storage Configuration

```sql
-- Create storage buckets
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types) VALUES
('resumes', 'resumes', false, 10485760, ARRAY['application/pdf']), -- 10MB limit, PDF only
('interview-audio', 'interview-audio', false, 52428800, ARRAY['audio/wav', 'audio/mp3', 'audio/m4a']), -- 50MB limit
('profile-pictures', 'profile-pictures', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']); -- 5MB limit

-- Row Level Security Policies
-- Resumes - users can only access their own resumes
CREATE POLICY "Users can upload their own resumes" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'resumes' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users can view their own resumes" ON storage.objects FOR SELECT USING (bucket_id = 'resumes' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users can delete their own resumes" ON storage.objects FOR DELETE USING (bucket_id = 'resumes' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Interview Audio - users can only access their own recordings
CREATE POLICY "Users can upload their own audio" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'interview-audio' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users can view their own audio" ON storage.objects FOR SELECT USING (bucket_id = 'interview-audio' AND auth.uid()::text = (storage.foldername(name))[1]);

-- Profile Pictures - users can manage their own profile pictures
CREATE POLICY "Users can upload their own profile pictures" ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'profile-pictures' AND auth.uid()::text = (storage.foldername(name))[1]);
CREATE POLICY "Users can view all profile pictures" ON storage.objects FOR SELECT USING (bucket_id = 'profile-pictures');
CREATE POLICY "Users can update their own profile pictures" ON storage.objects FOR UPDATE USING (bucket_id = 'profile-pictures' AND auth.uid()::text = (storage.foldername(name))[1]);
```

---

## Row Level Security (RLS) Policies

```sql
-- Enable RLS on all tables
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resumes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.resume_analysis ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interview_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interview_responses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_analytics ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.interview_feedback ENABLE ROW LEVEL SECURITY;

-- User Profiles - users can only access their own profile
CREATE POLICY "Users can view their own profile" ON public.user_profiles FOR SELECT USING (auth.uid() = id);
CREATE POLICY "Users can update their own profile" ON public.user_profiles FOR UPDATE USING (auth.uid() = id);

-- Resumes - users can only access their own resumes
CREATE POLICY "Users can view their own resumes" ON public.resumes FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own resumes" ON public.resumes FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own resumes" ON public.resumes FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Users can delete their own resumes" ON public.resumes FOR DELETE USING (auth.uid() = user_id);

-- Resume Analysis - users can only access their own analysis
CREATE POLICY "Users can view their own resume analysis" ON public.resume_analysis FOR SELECT USING (auth.uid() = user_id);

-- Interview Sessions - users can only access their own sessions
CREATE POLICY "Users can view their own interview sessions" ON public.interview_sessions FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own interview sessions" ON public.interview_sessions FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users can update their own interview sessions" ON public.interview_sessions FOR UPDATE USING (auth.uid() = user_id);

-- Interview Responses - users can only access their own responses
CREATE POLICY "Users can view their own interview responses" ON public.interview_responses FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can insert their own interview responses" ON public.interview_responses FOR INSERT WITH CHECK (auth.uid() = user_id);

-- User Analytics - users can only access their own analytics
CREATE POLICY "Users can view their own analytics" ON public.user_analytics FOR SELECT USING (auth.uid() = user_id);

-- Interview Feedback - users can only access their own feedback
CREATE POLICY "Users can view their own feedback" ON public.interview_feedback FOR SELECT USING (auth.uid() = user_id);

-- Public read access for job roles and questions
CREATE POLICY "Anyone can view job roles" ON public.job_roles FOR SELECT USING (is_active = true);
CREATE POLICY "Anyone can view interview questions" ON public.interview_questions FOR SELECT USING (is_active = true);
```

---

## Sample Data Insertion Scripts

```sql
-- Insert sample job roles
INSERT INTO public.job_roles (title, category, description, required_skills, industry) VALUES
('Frontend Developer', 'technology', 'Develop user-facing web applications', ARRAY['HTML', 'CSS', 'JavaScript', 'React', 'Vue.js'], 'Technology'),
('Backend Developer', 'technology', 'Develop server-side applications and APIs', ARRAY['Node.js', 'Python', 'Java', 'SQL', 'REST APIs'], 'Technology'),
('Full Stack Developer', 'technology', 'Develop both frontend and backend applications', ARRAY['JavaScript', 'React', 'Node.js', 'SQL', 'Git'], 'Technology'),
('Data Scientist', 'technology', 'Analyze data and build predictive models', ARRAY['Python', 'R', 'SQL', 'Machine Learning', 'Statistics'], 'Technology'),
('Product Manager', 'management', 'Manage product development lifecycle', ARRAY['Product Strategy', 'Analytics', 'Communication', 'Leadership'], 'Technology'),
('Digital Marketing Specialist', 'marketing', 'Execute digital marketing campaigns', ARRAY['SEO', 'SEM', 'Social Media', 'Analytics', 'Content Marketing'], 'Marketing');

-- Insert sample interview questions
INSERT INTO public.interview_questions (job_role_id, question_text, question_type, difficulty_level, expected_answer_keywords, time_limit_seconds) VALUES
((SELECT id FROM public.job_roles WHERE title = 'Frontend Developer' LIMIT 1), 'What is the difference between let, const, and var in JavaScript?', 'technical', 'medium', ARRAY['scope', 'hoisting', 'reassignment', 'block scope'], 120),
((SELECT id FROM public.job_roles WHERE title = 'Frontend Developer' LIMIT 1), 'Tell me about a challenging project you worked on and how you overcame the difficulties.', 'behavioral', 'medium', ARRAY['problem-solving', 'teamwork', 'communication', 'persistence'], 180),
((SELECT id FROM public.job_roles WHERE title = 'Backend Developer' LIMIT 1), 'Explain the difference between SQL and NoSQL databases.', 'technical', 'medium', ARRAY['relational', 'document', 'scalability', 'ACID', 'consistency'], 150);

-- Insert app settings
INSERT INTO public.app_settings (setting_key, setting_value, description) VALUES
('max_interview_duration', '3600', 'Maximum interview duration in seconds'),
('default_questions_per_interview', '10', 'Default number of questions per interview session'),
('gemini_api_timeout', '30', 'Gemini API timeout in seconds'),
('max_resume_size_mb', '10', 'Maximum resume file size in MB'),
('supported_audio_formats', '["wav", "mp3", "m4a"]', 'Supported audio formats for interview responses');
```

---

## Supabase Setup Recommendation

### ✅ **Supabase is Excellent for This Project**

**Advantages:**

1. **Built-in Authentication** - Handles user registration, login, password reset
2. **Real-time Subscriptions** - Perfect for live interview features
3. **File Storage** - Built-in storage for resumes, audio files, profile pictures
4. **Row Level Security** - Automatic data isolation per user
5. **RESTful APIs** - Auto-generated APIs for all tables
6. **PostgreSQL** - Full SQL support with JSON columns for flexible data
7. **Edge Functions** - For Gemini API integration
8. **Easy Scaling** - Managed infrastructure

**Easy Maintenance:**

- No server management required
- Automatic backups and scaling
- Built-in monitoring and analytics
- Simple deployment and updates

This schema provides a comprehensive foundation for your AI voice interview application with excellent scalability and maintainability using Supabase.
