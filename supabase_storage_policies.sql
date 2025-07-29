-- Storage Policies for AI Voice Interview App
-- Run this in your Supabase SQL Editor

-- Enable RLS on storage.objects (if not already enabled)
-- Note: This might already be enabled by Supabase
-- ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- Policy 1: Users can upload their own profile pictures
CREATE OR REPLACE POLICY "Users can upload profile pictures" ON storage.objects
FOR
INSERT WITH CHECK
    (
    bucket_id = '
rofile-pictures' AND
    auth.uid()

::text =
(storage.foldername
(name))[1]
);

-- Policy 2: Users can view all profile pictures (public bucket)
CREATE OR REPLACE POLICY "Profile pictures are publicly viewable" ON storage.objects
FOR
SELECT USING (bucket_id = 'profile-pictures');

-- Policy 3: Users can update their own profile pictures
CREATE OR REPLACE POLICY "Users can update their profile pictures" ON storage.objects
FOR
UPDATE USING (
  bucket_id = 'profile-pictures'
AND
  auth.uid
()::text =
(storage.foldername
(name))[1]
);

-- Policy 4: Users can delete their own profile pictures
CREATE OR REPLACE POLICY "Users can delete their profile pictures" ON storage.objects
FOR
DELETE USING (
  bucket_id
= 'profile-pictures' AND
  auth.uid
()::text =
(storage.foldername
(name))[1]
);

-- Verify the policies were created
SELECT bucket_id, name, definition
FROM storage.policies
WHERE bucket_id = 'profile-pictures';
