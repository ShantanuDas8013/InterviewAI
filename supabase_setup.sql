-- AI Voice Interview App - Supabase Database Setup
-- Execute these SQL commands in your Supabase SQL Editor

-- ========================================
-- 1. USER PROFILES TABLE (extends auth.users)
-- ========================================

CREATE TABLE public.user_profiles
(
    id UUID REFERENCES auth.users(id) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(100) NOT NULL,
    phone_number VARCHAR(20),
    date_of_birth DATE,
    gender VARCHAR(20) CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say')),
    location VARCHAR(100),
    bio TEXT,
    profile_picture_url TEXT,
    preferred_job_roles TEXT
    [],
  experience_level VARCHAR
    (20) CHECK
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
  subscription_expires_at TIMESTAMP
    WITH TIME ZONE,
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

    -- ========================================
    -- 2. JOB ROLES TABLE
    -- ========================================

    CREATE TABLE public.job_roles
    (
        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
        title VARCHAR(100) NOT NULL UNIQUE,
        category VARCHAR(50) NOT NULL,
        description TEXT,
        required_skills TEXT
        [] NOT NULL,
  experience_levels VARCHAR
        (20)[] DEFAULT ARRAY['entry', 'mid', 'senior'],
  industry VARCHAR
        (50),
  average_salary_range VARCHAR
        (50),
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP
        WITH TIME ZONE DEFAULT NOW
        (),
  updated_at TIMESTAMP
        WITH TIME ZONE DEFAULT NOW
        ()
);

        -- ========================================
        -- 3. RESUMES TABLE
        -- ========================================

        CREATE TABLE public.resumes
        (
            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
            user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
            file_name VARCHAR(255) NOT NULL,
            file_path TEXT NOT NULL,
            file_size_bytes BIGINT NOT NULL,
            upload_date TIMESTAMP
            WITH TIME ZONE DEFAULT NOW
            (),
  is_active BOOLEAN DEFAULT TRUE,
  is_analyzed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP
            WITH TIME ZONE DEFAULT NOW
            (),
  updated_at TIMESTAMP
            WITH TIME ZONE DEFAULT NOW
            ()
);

            -- ========================================
            -- 4. RESUME ANALYSIS TABLE
            -- ========================================

            CREATE TABLE public.resume_analysis
            (
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
                extracted_skills TEXT
                [],
  extracted_experience_years INTEGER,
  extracted_education_level VARCHAR
                (50),
  extracted_companies TEXT[],
  extracted_job_titles TEXT[],

  -- Recommendations
  missing_sections TEXT[],
  improvement_suggestions TEXT[],
  recommended_job_roles TEXT[],

  -- Keywords Analysis
  relevant_keywords TEXT[],
  missing_keywords TEXT[],
  keyword_density JSONB,

  -- ATS Compatibility
  ats_score DECIMAL
                (3,2) CHECK
                (ats_score >= 0 AND ats_score <= 10),
  ats_issues TEXT[],

  -- Gemini AI Analysis Results
  gemini_analysis_raw JSONB,

  analyzed_at TIMESTAMP
                WITH TIME ZONE DEFAULT NOW
                (),
  created_at TIMESTAMP
                WITH TIME ZONE DEFAULT NOW
                ()
);

                -- ========================================
                -- 5. INTERVIEW QUESTIONS TABLE
                -- ========================================

                CREATE TABLE public.interview_questions
                (
                    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
                    job_role_id UUID REFERENCES public.job_roles(id) ON DELETE CASCADE,
                    question_text TEXT NOT NULL,
                    question_type VARCHAR(30) NOT NULL CHECK (question_type IN ('technical', 'behavioral', 'situational', 'general')),
                    difficulty_level VARCHAR(20) NOT NULL CHECK (difficulty_level IN ('easy', 'medium', 'hard')),
                    expected_answer_keywords TEXT
                    [],
  sample_answer TEXT,
  evaluation_criteria JSONB,
  time_limit_seconds INTEGER DEFAULT 120,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMP
                    WITH TIME ZONE DEFAULT NOW
                    (),
  updated_at TIMESTAMP
                    WITH TIME ZONE DEFAULT NOW
                    ()
);

                    -- ========================================
                    -- 6. INTERVIEW SESSIONS TABLE
                    -- ========================================

                    CREATE TABLE public.interview_sessions
                    (
                        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
                        user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
                        job_role_id UUID REFERENCES public.job_roles(id) ON DELETE SET NULL,
                        resume_id UUID REFERENCES public.resumes(id) ON DELETE SET NULL,

                        -- Session Details
                        session_name VARCHAR(100),
                        session_type VARCHAR(20) DEFAULT 'practice' CHECK (session_type IN ('practice', 'assessment', 'mock')),
                        status VARCHAR(20) DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'in_progress', 'completed', 'cancelled', 'paused')),

                        -- Timing
                        scheduled_at TIMESTAMP
                        WITH TIME ZONE,
  started_at TIMESTAMP
                        WITH TIME ZONE,
  completed_at TIMESTAMP
                        WITH TIME ZONE,
  duration_seconds INTEGER,

  -- Configuration
  total_questions INTEGER DEFAULT 10,
  questions_answered INTEGER DEFAULT 0,
  difficulty_level VARCHAR
                        (20) DEFAULT 'medium' CHECK
                        (difficulty_level IN
                        ('easy', 'medium', 'hard', 'mixed')),

  -- Results
  overall_score DECIMAL
                        (3,2) CHECK
                        (overall_score >= 0 AND overall_score <= 10),
  technical_score DECIMAL
                        (3,2) CHECK
                        (technical_score >= 0 AND technical_score <= 10),
  communication_score DECIMAL
                        (3,2) CHECK
                        (communication_score >= 0 AND communication_score <= 10),
  confidence_score DECIMAL
                        (3,2) CHECK
                        (confidence_score >= 0 AND confidence_score <= 10),

  -- AI Analysis
  ai_feedback TEXT,
  strengths TEXT[],
  areas_for_improvement TEXT[],
  recommendations TEXT[],

  created_at TIMESTAMP
                        WITH TIME ZONE DEFAULT NOW
                        (),
  updated_at TIMESTAMP
                        WITH TIME ZONE DEFAULT NOW
                        ()
);

                        -- ========================================
                        -- 7. INTERVIEW RESPONSES TABLE
                        -- ========================================

                        CREATE TABLE public.interview_responses
                        (
                            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
                            interview_session_id UUID REFERENCES public.interview_sessions(id) ON DELETE CASCADE,
                            question_id UUID REFERENCES public.interview_questions(id) ON DELETE CASCADE,
                            user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,

                            -- Response Details
                            question_order INTEGER NOT NULL,
                            audio_file_path TEXT,
                            transcribed_text TEXT,
                            response_duration_seconds INTEGER,

                            -- Scoring
                            response_score DECIMAL(3,2) CHECK (response_score >= 0 AND response_score <= 10),
                            technical_accuracy DECIMAL(3,2) CHECK (technical_accuracy >= 0 AND technical_accuracy <= 10),
                            communication_clarity DECIMAL(3,2) CHECK (communication_clarity >= 0 AND communication_clarity <= 10),
                            relevance_score DECIMAL(3,2) CHECK (relevance_score >= 0 AND relevance_score <= 10),

                            -- AI Analysis
                            ai_feedback TEXT,
                            keywords_mentioned TEXT
                            [],
  missing_keywords TEXT[],
  suggested_improvement TEXT,
  ideal_answer_comparison TEXT,

  -- Speech Analysis
  speech_pace DECIMAL
                            (5,2),
  filler_words_count INTEGER DEFAULT 0,
  confidence_level DECIMAL
                            (3,2) CHECK
                            (confidence_level >= 0 AND confidence_level <= 10),

  -- Gemini Analysis
  gemini_analysis_raw JSONB,

  answered_at TIMESTAMP
                            WITH TIME ZONE DEFAULT NOW
                            (),
  created_at TIMESTAMP
                            WITH TIME ZONE DEFAULT NOW
                            ()
);

                            -- ========================================
                            -- 8. USER ANALYTICS TABLE
                            -- ========================================

                            CREATE TABLE public.user_analytics
                            (
                                id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
                                user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,

                                -- Performance Metrics
                                total_interviews INTEGER DEFAULT 0,
                                completed_interviews INTEGER DEFAULT 0,
                                average_score DECIMAL(3,2) DEFAULT 0.00,
                                best_score DECIMAL(3,2) DEFAULT 0.00,
                                latest_score DECIMAL(3,2) DEFAULT 0.00,

                                -- Progress Tracking
                                skill_improvements JSONB,
                                weakness_areas TEXT
                                [],
  strength_areas TEXT[],

  -- Time-based Analytics
  total_practice_time_minutes INTEGER DEFAULT 0,
  sessions_this_week INTEGER DEFAULT 0,
  sessions_this_month INTEGER DEFAULT 0,

  -- Job Role Performance
  preferred_job_roles JSONB,

  last_updated TIMESTAMP
                                WITH TIME ZONE DEFAULT NOW
                                (),
  created_at TIMESTAMP
                                WITH TIME ZONE DEFAULT NOW
                                ()
);

                                -- ========================================
                                -- 9. INTERVIEW FEEDBACK TABLE
                                -- ========================================

                                CREATE TABLE public.interview_feedback
                                (
                                    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
                                    interview_session_id UUID REFERENCES public.interview_sessions(id) ON DELETE CASCADE,
                                    user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,

                                    -- Detailed Feedback Categories
                                    technical_feedback JSONB,
                                    behavioral_feedback JSONB,
                                    communication_feedback JSONB,

                                    -- Improvement Plan
                                    short_term_goals TEXT
                                    [],
  long_term_goals TEXT[],
  recommended_resources JSONB,
  practice_suggestions TEXT[],

  -- Comparative Analysis
  industry_benchmark_comparison JSONB,
  peer_comparison JSONB,

  created_at TIMESTAMP
                                    WITH TIME ZONE DEFAULT NOW
                                    ()
);

                                    -- ========================================
                                    -- 10. APP SETTINGS TABLE
                                    -- ========================================

                                    CREATE TABLE public.app_settings
                                    (
                                        id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
                                        setting_key VARCHAR(100) NOT NULL UNIQUE,
                                        setting_value JSONB NOT NULL,
                                        description TEXT,
                                        is_active BOOLEAN DEFAULT TRUE,
                                        updated_by UUID REFERENCES public.user_profiles(id),
                                        created_at TIMESTAMP
                                        WITH TIME ZONE DEFAULT NOW
                                        (),
  updated_at TIMESTAMP
                                        WITH TIME ZONE DEFAULT NOW
                                        ()
);

                                        -- ========================================
                                        -- 11. GEMINI API LOGS TABLE
                                        -- ========================================

                                        CREATE TABLE public.gemini_api_logs
                                        (
                                            id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
                                            user_id UUID REFERENCES public.user_profiles(id) ON DELETE SET NULL,
                                            api_endpoint VARCHAR(255) NOT NULL,
                                            request_type VARCHAR(50) NOT NULL,
                                            request_payload JSONB,
                                            response_payload JSONB,
                                            tokens_used INTEGER,
                                            processing_time_ms INTEGER,
                                            status VARCHAR(20) NOT NULL,
                                            error_message TEXT,
                                            created_at TIMESTAMP
                                            WITH TIME ZONE DEFAULT NOW
                                            ()
);

                                            -- ========================================
                                            -- INDEXES FOR PERFORMANCE
                                            -- ========================================

                                            CREATE INDEX idx_user_profiles_email ON public.user_profiles(email);
                                            CREATE INDEX idx_resumes_user_id ON public.resumes(user_id);
                                            CREATE INDEX idx_resumes_is_active ON public.resumes(is_active);
                                            CREATE INDEX idx_interview_sessions_user_id ON public.interview_sessions(user_id);
                                            CREATE INDEX idx_interview_sessions_status ON public.interview_sessions(status);
                                            CREATE INDEX idx_interview_responses_session_id ON public.interview_responses(interview_session_id);
                                            CREATE INDEX idx_job_roles_category ON public.job_roles(category);
                                            CREATE INDEX idx_interview_questions_job_role_id ON public.interview_questions(job_role_id);
                                            CREATE INDEX idx_interview_questions_difficulty ON public.interview_questions(difficulty_level);
                                            CREATE INDEX idx_interview_sessions_user_status ON public.interview_sessions(user_id, status);
                                            CREATE INDEX idx_interview_responses_session_order ON public.interview_responses(interview_session_id, question_order);

                                            -- ========================================
                                            -- AUTOMATIC UPDATED_AT TRIGGERS
                                            -- ========================================

                                            CREATE OR REPLACE FUNCTION update_updated_at_column
                                            ()
RETURNS TRIGGER AS $$
                                            BEGIN
    NEW.updated_at = NOW
                                            ();
                                            RETURN NEW;
                                            END;
$$ language 'plpgsql';

                                            CREATE TRIGGER update_user_profiles_updated_at BEFORE
                                            UPDATE ON public.user_profiles FOR EACH ROW
                                            EXECUTE FUNCTION update_updated_at_column
                                            ();
                                            CREATE TRIGGER update_resumes_updated_at BEFORE
                                            UPDATE ON public.resumes FOR EACH ROW
                                            EXECUTE FUNCTION update_updated_at_column
                                            ();
                                            CREATE TRIGGER update_job_roles_updated_at BEFORE
                                            UPDATE ON public.job_roles FOR EACH ROW
                                            EXECUTE FUNCTION update_updated_at_column
                                            ();
                                            CREATE TRIGGER update_interview_questions_updated_at BEFORE
                                            UPDATE ON public.interview_questions FOR EACH ROW
                                            EXECUTE FUNCTION update_updated_at_column
                                            ();
                                            CREATE TRIGGER update_interview_sessions_updated_at BEFORE
                                            UPDATE ON public.interview_sessions FOR EACH ROW
                                            EXECUTE FUNCTION update_updated_at_column
                                            ();
                                            CREATE TRIGGER update_app_settings_updated_at BEFORE
                                            UPDATE ON public.app_settings FOR EACH ROW
                                            EXECUTE FUNCTION update_updated_at_column
                                            ();

                                            -- ========================================
                                            -- ROW LEVEL SECURITY (RLS) POLICIES
                                            -- ========================================

                                            -- Enable RLS on all tables
                                            ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;
                                            ALTER TABLE public.resumes ENABLE ROW LEVEL SECURITY;
                                            ALTER TABLE public.resume_analysis ENABLE ROW LEVEL SECURITY;
                                            ALTER TABLE public.interview_sessions ENABLE ROW LEVEL SECURITY;
                                            ALTER TABLE public.interview_responses ENABLE ROW LEVEL SECURITY;
                                            ALTER TABLE public.user_analytics ENABLE ROW LEVEL SECURITY;
                                            ALTER TABLE public.interview_feedback ENABLE ROW LEVEL SECURITY;

                                            -- User Profiles Policies
                                            CREATE POLICY "Users can view their own profile" ON public.user_profiles FOR
                                            SELECT USING (auth.uid() = id);
                                            CREATE POLICY "Users can update their own profile" ON public.user_profiles FOR
                                            UPDATE USING (auth.uid()
                                            = id);
                                            CREATE POLICY "Users can insert their own profile" ON public.user_profiles FOR
                                            INSERT WITH CHECK (auth.uid() =
                                            id);

                                            -- Resumes Policies
                                            CREATE POLICY "Users can view their own resumes" ON public.resumes FOR
                                            SELECT USING (auth.uid() = user_id);
                                            CREATE POLICY "Users can insert their own resumes" ON public.resumes FOR
                                            INSERT WITH CHECK (auth.uid() =
                                            user_id);
                                            CREATE POLICY "Users can update their own resumes" ON public.resumes FOR
                                            UPDATE USING (auth.uid()
                                            = user_id);
                                            CREATE POLICY "Users can delete their own resumes" ON public.resumes FOR
                                            DELETE USING (auth.uid
                                            () = user_id);

                                            -- Resume Analysis Policies
                                            CREATE POLICY "Users can view their own resume analysis" ON public.resume_analysis FOR
                                            SELECT USING (auth.uid() = user_id);
                                            CREATE POLICY "Users can insert their own resume analysis" ON public.resume_analysis FOR
                                            INSERT WITH CHECK (auth.uid() =
                                            user_id);

                                            -- Interview Sessions Policies
                                            CREATE POLICY "Users can view their own interview sessions" ON public.interview_sessions FOR
                                            SELECT USING (auth.uid() = user_id);
                                            CREATE POLICY "Users can insert their own interview sessions" ON public.interview_sessions FOR
                                            INSERT WITH CHECK (auth.uid() =
                                            user_id);
                                            CREATE POLICY "Users can update their own interview sessions" ON public.interview_sessions FOR
                                            UPDATE USING (auth.uid()
                                            = user_id);

                                            -- Interview Responses Policies
                                            CREATE POLICY "Users can view their own interview responses" ON public.interview_responses FOR
                                            SELECT USING (auth.uid() = user_id);
                                            CREATE POLICY "Users can insert their own interview responses" ON public.interview_responses FOR
                                            INSERT WITH CHECK (auth.uid() =
                                            user_id);

                                            -- User Analytics Policies
                                            CREATE POLICY "Users can view their own analytics" ON public.user_analytics FOR
                                            SELECT USING (auth.uid() = user_id);
                                            CREATE POLICY "Users can insert their own analytics" ON public.user_analytics FOR
                                            INSERT WITH CHECK (auth.uid() =
                                            user_id);
                                            CREATE POLICY "Users can update their own analytics" ON public.user_analytics FOR
                                            UPDATE USING (auth.uid()
                                            = user_id);

                                            -- Interview Feedback Policies
                                            CREATE POLICY "Users can view their own feedback" ON public.interview_feedback FOR
                                            SELECT USING (auth.uid() = user_id);
                                            CREATE POLICY "Users can insert their own feedback" ON public.interview_feedback FOR
                                            INSERT WITH CHECK (auth.uid() =
                                            user_id);

                                            -- Public read access for job roles and questions
                                            CREATE POLICY "Anyone can view job roles" ON public.job_roles FOR
                                            SELECT USING (is_active = true);
                                            CREATE POLICY "Anyone can view interview questions" ON public.interview_questions FOR
                                            SELECT USING (is_active = true);
