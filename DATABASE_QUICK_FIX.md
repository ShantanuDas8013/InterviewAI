# Quick Database Fix for Interview System

## Problem

The interview system is failing with error: `Could not find the 'problem_solving_score' column of 'interview_sessions' in the schema cache`

## Solution

Run this SQL script in your Supabase SQL Editor to fix the issue immediately:

```sql
-- Add missing problem_solving_score column to interview_sessions table
ALTER TABLE public.interview_sessions
ADD COLUMN IF NOT EXISTS problem_solving_score DECIMAL(3,2)
CHECK (problem_solving_score >= 0 AND problem_solving_score <= 10);

-- Create interview_results table if it doesn't exist
CREATE TABLE IF NOT EXISTS public.interview_results (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  interview_session_id UUID REFERENCES public.interview_sessions(id) ON DELETE CASCADE,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  job_role_id UUID REFERENCES public.job_roles(id) ON DELETE SET NULL,
  job_role_title VARCHAR(100) NOT NULL,
  overall_score DECIMAL(3,2) CHECK (overall_score >= 0 AND overall_score <= 10),
  technical_score DECIMAL(3,2) CHECK (technical_score >= 0 AND technical_score <= 10),
  communication_score DECIMAL(3,2) CHECK (communication_score >= 0 AND communication_score <= 10),
  problem_solving_score DECIMAL(3,2) CHECK (problem_solving_score >= 0 AND problem_solving_score <= 10),
  confidence_score DECIMAL(3,2) CHECK (confidence_score >= 0 AND confidence_score <= 10),
  strengths_analysis TEXT,
  areas_for_improvement TEXT,
  ai_summary TEXT,
  completed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for interview_results
ALTER TABLE public.interview_results ENABLE ROW LEVEL SECURITY;

-- Add RLS policies for interview_results
DO $$
BEGIN
  -- Check if policy exists before creating
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'interview_results' AND policyname = 'Users can view their own interview results'
  ) THEN
    CREATE POLICY "Users can view their own interview results" ON public.interview_results
      FOR SELECT USING (auth.uid() = user_id);
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE tablename = 'interview_results' AND policyname = 'Users can insert their own interview results'
  ) THEN
    CREATE POLICY "Users can insert their own interview results" ON public.interview_results
      FOR INSERT WITH CHECK (auth.uid() = user_id);
  END IF;
END $$;

-- Update existing records to have default problem_solving_score (if any exist)
UPDATE public.interview_sessions
SET problem_solving_score = 0.0
WHERE problem_solving_score IS NULL;
```

## Instructions

1. Go to your Supabase project dashboard
2. Navigate to SQL Editor
3. Copy and paste the above SQL script
4. Click "Run" to execute
5. Restart your Flutter app

The interview system should now work properly!

## What This Script Does

1. **Adds the missing `problem_solving_score` column** to the `interview_sessions` table
2. **Creates the `interview_results` table** that the system expects for storing final results
3. **Sets up proper Row Level Security (RLS)** policies for data access
4. **Updates any existing records** with default values

After running this script, the AI Voice Interview system will be able to:

- Create interview sessions successfully
- Store problem-solving scores
- Generate and save comprehensive interview results
- Function exactly as designed

## Verification

After running the script, you can verify it worked by checking:

```sql
-- Check if the column was added
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'interview_sessions'
AND column_name = 'problem_solving_score';

-- Check if the interview_results table exists
SELECT table_name
FROM information_schema.tables
WHERE table_name = 'interview_results';
```

Both queries should return results if the fix was successful.
