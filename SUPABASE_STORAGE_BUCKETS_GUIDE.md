# Supabase Storage Buckets Setup Guide

## ⚠️ Important Note About Storage Permissions

**DO NOT** try to run `ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;` manually. The storage.objects table is managed by Supabase and you don't have owner permissions. Supabase handles RLS for storage automatically when you create buckets and policies through the dashboard or proper SQL functions.

## Overview

This guide will help you create the necessary storage buckets for the AI Voice Interview App project. We need three main buckets to handle different types of file uploads.

## Required Storage Buckets

### 1. **resumes** - For PDF resume uploads

- **Purpose**: Store user-uploaded PDF resumes
- **File Types**: PDF only
- **Size Limit**: 10MB
- **Access**: Private (users can only access their own files)

### 2. **interview-audio** - For voice recording storage

- **Purpose**: Store interview audio recordings
- **File Types**: WAV, MP3, M4A
- **Size Limit**: 50MB
- **Access**: Private (users can only access their own recordings)

### 3. **profile-pictures** - For user profile images

- **Purpose**: Store user profile pictures
- **File Types**: JPEG, PNG, WebP
- **Size Limit**: 5MB
- **Access**: Public (for profile picture display)

---

## Quick Solution for Your Current Error

The error `ERROR: 42501: must be owner of table objects` occurs because you're trying to directly modify Supabase's internal storage tables. Here's how to fix it:

### Step-by-Step Solution:

1. **Stop trying to run the RLS command** - Supabase manages this automatically
2. **Use the Dashboard method below** - This is the safest and most reliable approach
3. **Follow the complete bucket creation process**

---

## Method 1: Using Supabase Dashboard (Recommended and Error-Free)

This method avoids all permission issues and is the most reliable way to set up storage.

### Step 1: Access Supabase Dashboard

1. Go to [https://supabase.com](https://supabase.com)
2. Sign in to your account
3. Select your project
4. Navigate to **Storage** in the left sidebar

### Step 2: Create Storage Buckets

#### Create 'resumes' Bucket:

1. Click **"New bucket"**
2. Fill in the details:
   - **Name**: `resumes`
   - **Public bucket**: ❌ (Keep unchecked - private bucket)
   - **File size limit**: `10485760` (10MB in bytes)
   - **Allowed MIME types**: `application/pdf`
3. Click **"Create bucket"**

#### Create 'interview-audio' Bucket:

1. Click **"New bucket"**
2. Fill in the details:
   - **Name**: `interview-audio`
   - **Public bucket**: ❌ (Keep unchecked - private bucket)
   - **File size limit**: `52428800` (50MB in bytes)
   - **Allowed MIME types**: `audio/wav, audio/mp3, audio/m4a`
3. Click **"Create bucket"**

#### Create 'profile-pictures' Bucket:

1. Click **"New bucket"**
2. Fill in the details:
   - **Name**: `profile-pictures`
   - **Public bucket**: ✅ (Check this - public bucket)
   - **File size limit**: `5242880` (5MB in bytes)
   - **Allowed MIME types**: `image/jpeg, image/png, image/webp`
3. Click **"Create bucket"**

### Step 3: Set Up Policies Using Dashboard

For each bucket you created:

1. Click on the bucket name
2. Go to **"Policies"** tab
3. Click **"New Policy"**
4. Choose the appropriate template or create custom policies

#### For 'resumes' and 'interview-audio' buckets:

- Select: **"Enable access to authenticated users only"**
- This ensures users can only access their own files

#### For 'profile-pictures' bucket:

- Select: **"Enable access for authenticated users to upload files"**
- Select: **"Enable public access to files"** (for viewing profile pictures)

---

## Method 2: Using SQL Commands (Advanced - Use Only If Dashboard Fails)

### Step 1: Access SQL Editor

1. In your Supabase dashboard, go to **SQL Editor**
2. Click **"New query"**

### Step 2: Execute Bucket Creation SQL

Copy and paste the following SQL command:

```sql
-- Create storage buckets for the AI Voice Interview App
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('resumes', 'resumes', false, 10485760, ARRAY['application/pdf']),
  ('interview-audio', 'interview-audio', false, 52428800, ARRAY['audio/wav', 'audio/mp3', 'audio/m4a']),
  ('profile-pictures', 'profile-pictures', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']);
```

3. Click **"Run"** to execute the command

---

## Step 3: Set Up Security Policies

After creating the buckets, you need to set up Row Level Security (RLS) policies to control access.

### ⚠️ Important: Use the Dashboard for Policy Creation

**Do not manually enable RLS on storage.objects table** - Supabase manages this automatically. Instead, use the dashboard or the correct SQL functions.

### Method A: Using Supabase Dashboard (Recommended)

1. Go to **Storage** → Select your bucket → **Policies** tab
2. Click **"New Policy"**
3. Choose policy type and configure access rules

### Method B: Using Correct SQL Functions

```sql
-- ========================================
-- STORAGE SECURITY POLICIES
-- Note: Do NOT run ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;
-- Supabase manages this automatically
-- ========================================

-- RESUMES BUCKET POLICIES
-- Users can only upload their own resumes
INSERT INTO storage.policies (bucket_id, name, definition, check_expression, command)
VALUES (
  'resumes',
  'Users can upload their own resumes',
  'bucket_id = ''resumes'' AND auth.uid()::text = (storage.foldername(name))[1]',
  'bucket_id = ''resumes'' AND auth.uid()::text = (storage.foldername(name))[1]',
  'INSERT'
);

-- Users can only view their own resumes
INSERT INTO storage.policies (bucket_id, name, definition, check_expression, command)
VALUES (
  'resumes',
  'Users can view their own resumes',
  'bucket_id = ''resumes'' AND auth.uid()::text = (storage.foldername(name))[1]',
  NULL,
  'SELECT'
);

-- Users can only delete their own resumes
INSERT INTO storage.policies (bucket_id, name, definition, check_expression, command)
VALUES (
  'resumes',
  'Users can delete their own resumes',
  'bucket_id = ''resumes'' AND auth.uid()::text = (storage.foldername(name))[1]',
  NULL,
  'DELETE'
);

-- INTERVIEW AUDIO BUCKET POLICIES
-- Users can upload their own audio recordings
INSERT INTO storage.policies (bucket_id, name, definition, check_expression, command)
VALUES (
  'interview-audio',
  'Users can upload their own audio',
  'bucket_id = ''interview-audio'' AND auth.uid()::text = (storage.foldername(name))[1]',
  'bucket_id = ''interview-audio'' AND auth.uid()::text = (storage.foldername(name))[1]',
  'INSERT'
);

-- Users can view their own audio recordings
INSERT INTO storage.policies (bucket_id, name, definition, check_expression, command)
VALUES (
  'interview-audio',
  'Users can view their own audio',
  'bucket_id = ''interview-audio'' AND auth.uid()::text = (storage.foldername(name))[1]',
  NULL,
  'SELECT'
);
  auth.uid()::text = (storage.foldername(name))[1]
);

-- PROFILE PICTURES BUCKET POLICIES
-- Users can upload their own profile pictures
    CREATE POLICY "Users can upload their own profile pictures" ON storage.objects
    FOR INSERT WITH CHECK (
    bucket_id = 'profile-pictures' AND
    auth.uid()::text = (storage.foldername(name))[1]
    );

-- Anyone can view profile pictures (public bucket)
CREATE POLICY "Anyone can view profile pictures" ON storage.objects
FOR SELECT USING (bucket_id = 'profile-pictures');

-- Users can update their own profile pictures
CREATE POLICY "Users can update their own profile pictures" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'profile-pictures' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

---

## Step 4: Verify Bucket Creation

### Using Dashboard:

1. Go to **Storage** in your Supabase dashboard
2. You should see three buckets listed:
   - ✅ `resumes` (Private)
   - ✅ `interview-audio` (Private)
   - ✅ `profile-pictures` (Public)

### Using SQL Query:

Run this query to verify buckets exist:

```sql
SELECT id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets
WHERE id IN ('resumes', 'interview-audio', 'profile-pictures');
```

---

## File Organization Structure

Once buckets are created, files will be organized as follows:

```
resumes/
├── {user_id}/
│   ├── resume_1.pdf
│   ├── resume_2.pdf
│   └── ...

interview-audio/
├── {user_id}/
│   ├── session_1_audio.wav
│   ├── session_2_audio.mp3
│   └── ...

profile-pictures/
├── {user_id}/
│   └── profile.jpg
```

---

## Testing Bucket Configuration

### Test File Upload (using Supabase Client):

```dart
// Example Flutter code to test file upload
final supabase = Supabase.instance.client;

// Upload resume
final resumeFile = File('path/to/resume.pdf');
final resumePath = '${supabase.auth.currentUser!.id}/resume.pdf';

await supabase.storage.from('resumes').upload(resumePath, resumeFile);

// Upload profile picture
final imageFile = File('path/to/profile.jpg');
final imagePath = '${supabase.auth.currentUser!.id}/profile.jpg';

await supabase.storage.from('profile-pictures').upload(imagePath, imageFile);
```

---

## Common Issues and Solutions

### Issue 1: "RLS Policy Violation"

**Solution**: Make sure you've applied the security policies correctly and the user is authenticated.

### Issue 2: "File Size Limit Exceeded"

**Solution**: Check the file size limits:

- Resumes: 10MB max
- Audio: 50MB max
- Images: 5MB max

### Issue 3: "MIME Type Not Allowed"

**Solution**: Ensure you're uploading the correct file types:

- Resumes: PDF only
- Audio: WAV, MP3, M4A only
- Images: JPEG, PNG, WebP only

### Issue 4: "Bucket Does Not Exist"

**Solution**: Verify bucket names are exactly: `resumes`, `interview-audio`, `profile-pictures`

---

## Summary: Key Points to Remember

### ✅ What You Should Do:

1. **Use the Supabase Dashboard** - It's the most reliable method
2. **Create buckets first** - Then set up policies
3. **Use policy templates** - Don't try to write custom SQL for storage policies initially

### ❌ What You Should NOT Do:

1. **Never run**: `ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;`
2. **Don't try to directly modify** `storage.objects` table
3. **Avoid complex custom policies** until you're familiar with Supabase storage

### 🚀 Expected Results:

After completing this guide, you should have:

- ✅ 3 storage buckets created (`resumes`, `interview-audio`, `profile-pictures`)
- ✅ Proper security policies in place
- ✅ File size and type restrictions configured
- ✅ Ready to implement file uploads in your Flutter app

### 🔧 If You Still Get Errors:

1. Double-check you're using the Dashboard method
2. Verify your Supabase project permissions
3. Contact Supabase support if you continue having issues
4. Consider using the service_role key (with extreme caution) for initial setup

---

## Next Steps

After setting up the storage buckets:

1. ✅ Create the database tables (if not done already)
2. ✅ Set up the storage buckets (current step)
3. 🔄 Implement file upload functionality in your Flutter app
4. 🔄 Add resume parsing and analysis features
5. 🔄 Implement audio recording and storage for interviews

---

## Support

If you encounter any issues:

1. Check the Supabase logs in your dashboard
2. Verify your RLS policies are correctly applied
3. Ensure your Flutter app has the correct Supabase configuration
4. Test with small file sizes first

---

**Note**: Remember to update your Flutter app's Supabase configuration with the correct bucket names and implement proper error handling for file uploads.
