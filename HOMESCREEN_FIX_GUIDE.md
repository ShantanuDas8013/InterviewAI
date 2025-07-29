# Quick Fix for HomeScreen setState() Error

## The Issue

You're getting a `setState() called after dispose()` error because:

1. The `user_profiles` table doesn't exist in your Supabase database
2. Async operations continue after the widget is disposed

## Solutions Applied

### 1. Fixed HomeScreen Code

- Added `mounted` checks before all `setState()` calls
- Added proper error handling with fallback to user metadata
- Added `dispose()` method for cleanup

### 2. Database Table Missing

You need to create the `user_profiles` table in your Supabase database.

## Quick Database Fix

**Option 1: Use Supabase Dashboard**

1. Go to your Supabase Dashboard
2. Navigate to **Table Editor**
3. Click **"New table"**
4. Name: `user_profiles`
5. Add these columns:
   - `id` (uuid, primary key, references auth.users)
   - `email` (varchar)
   - `full_name` (varchar)
   - `phone_number` (varchar, nullable)
   - `location` (varchar, nullable)
   - `bio` (text, nullable)
   - `experience_level` (varchar, default: 'entry')
   - `created_at` (timestamptz, default: now())
   - `updated_at` (timestamptz, default: now())

**Option 2: Use SQL (Copy-paste into Supabase SQL Editor)**

```sql
-- Create user_profiles table
CREATE TABLE public.user_profiles (
  id UUID REFERENCES auth.users(id) PRIMARY KEY,
  email VARCHAR(255) NOT NULL UNIQUE,
  full_name VARCHAR(100) NOT NULL,
  phone_number VARCHAR(20),
  location VARCHAR(100),
  bio TEXT,
  experience_level VARCHAR(20) DEFAULT 'entry',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.user_profiles ENABLE ROW LEVEL SECURITY;

-- Create policies
CREATE POLICY "Users can view their own profile" ON public.user_profiles
  FOR SELECT USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile" ON public.user_profiles
  FOR INSERT WITH CHECK (auth.uid() = id);

CREATE POLICY "Users can update their own profile" ON public.user_profiles
  FOR UPDATE USING (auth.uid() = id);
```

## Test the Fix

1. Create the `user_profiles` table using one of the methods above
2. Restart your Flutter app
3. Try registering/logging in again
4. The error should be resolved

## What Changed in the Code

### HomeScreen (\_loadUserProfile method)

```dart
// Before
setState(() => _isLoading = true);

// After
if (!mounted) return;
setState(() => _isLoading = true);

// And before every setState():
if (mounted) {
  setState(() {
    // your state updates
  });
}
```

### DatabaseService

- Changed table name from `profiles` to `user_profiles`
- Added proper column mappings for all user profile fields

The error should now be completely resolved!
