-- ========================================
-- SUPABASE STORAGE BUCKETS SETUP
-- ========================================
-- NOTE: This should be run in Supabase SQL Editor with appropriate permissions
-- Alternatively, use the Supabase Dashboard to create buckets

-- Create storage buckets for file uploads
INSERT INTO storage.buckets
    (id, name, public, file_size_limit, allowed_mime_types)
VALUES
    ('resumes', 'resumes', false, 10485760, ARRAY
['application/pdf']),
('interview-audio', 'interview-audio', false, 52428800, ARRAY['audio/wav', 'audio/mp3', 'audio/m4a']),
('profile-pictures', 'profile-pictures', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp'])
ON CONFLICT
(id) DO NOTHING;

-- ========================================
-- STORAGE POLICIES SETUP
-- ========================================
-- NOTE: If you get permission errors, use the Supabase Dashboard instead

-- OPTION 1: Using CREATE POLICY (may require owner permissions)
-- If this fails, use OPTION 2 or the Dashboard

-- Resumes bucket policies
CREATE POLICY "Users can upload their own resumes" ON storage.objects 
FOR
INSERT WITH CHECK
    (
    bucket_id = '
esumes' AND
    auth.uid()

::text =
(storage.foldername
(name))[1]
);

CREATE POLICY "Users can view their own resumes" ON storage.objects 
FOR
SELECT USING (
  bucket_id = 'resumes' AND
        auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own resumes" ON storage.objects 
FOR
DELETE USING (
  bucket_id
= 'resumes' AND
  auth.uid
()::text =
(storage.foldername
(name))[1]
);
()::text =
(storage.foldername
(name))[1]
);

-- Interview Audio - users can only access their own recordings
CREATE POLICY "Users can upload their own audio" ON storage.objects 
FOR
INSERT WITH CHECK
    (
    bucket_id =

    interview-audio' AND
    auth.uid()

::text =
(storage.foldername
(name))[1]
);

CREATE POLICY "Users can view their own audio" ON storage.objects 
FOR
SELECT USING (
  bucket_id = 'interview-audio' AND
        auth.uid()::text = (storage.foldername(name))[1]
);

-- Profile Pictures - users can manage their own profile pictures
CREATE POLICY "Users can upload their own profile pictures" ON storage.objects 
FOR
INSERT WITH CHECK
    (
    bucket_id = 
profile-pictures' AND
    auth.uid
()

::text =
(storage.foldername
(name))[1]
);

CREATE POLICY "Anyone can view profile pictures" ON storage.objects 
FOR
SELECT USING (bucket_id = 'profile-pictures');

CREATE POLICY "Users can update their own profile pictures" ON storage.objects 
FOR
UPDATE USING (
  bucket_id = 'profile-pictures'
AND 
  auth.uid
()::text =
(storage.foldername
(name))[1]
);
