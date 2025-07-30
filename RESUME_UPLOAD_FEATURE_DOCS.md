# Resume Upload Feature Documentation

## Overview

The Resume Upload feature allows users to upload their resumes in PDF format to the AI Voice Interview App. The feature integrates with Supabase storage and database to securely store and manage user resumes.

## Features

### ✅ Core Functionality

1. **PDF Resume Upload**
   - Supports PDF files only
   - Maximum file size: 10MB
   - Automatic file validation

2. **Existing Resume Management**
   - Shows current resume if already uploaded
   - Displays file details (name, size, upload date, analysis status)
   - Replace functionality (new resume replaces old one)

3. **Resume Deletion**
   - Delete current resume from storage and database
   - Clean removal of all associated data

4. **Error Handling**
   - Comprehensive error messages
   - Permission validation
   - File size and type validation

5. **User Experience**
   - Loading states during operations
   - Success/error message notifications
   - Progress indicators for uploads

## Architecture

### Directory Structure

```
lib/features/4_resume_upload/
├── data/
│   └── resume_repository.dart      # Database operations
├── services/
│   └── resume_service.dart         # Business logic
└── presentation/
    └── screens/
        └── upload_resume_screen.dart  # UI implementation
```

### Layer Separation

1. **Presentation Layer** (`upload_resume_screen.dart`)
   - UI components and user interactions
   - State management for loading, errors, success
   - Calls service layer for operations

2. **Service Layer** (`resume_service.dart`)
   - Business logic and validation
   - File picking and permission handling
   - Orchestrates repository operations

3. **Data Layer** (`resume_repository.dart`)
   - Direct database operations
   - Supabase storage integration
   - CRUD operations for resumes

## Database Schema

### Resumes Table

```sql
CREATE TABLE public.resumes (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES public.user_profiles(id) ON DELETE CASCADE,
  file_name VARCHAR(255) NOT NULL,
  file_path TEXT NOT NULL,
  file_size_bytes BIGINT NOT NULL,
  upload_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  is_active BOOLEAN DEFAULT TRUE,
  is_analyzed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Storage Bucket

- **Bucket Name**: `resumes`
- **Access**: Private (users can only access their own files)
- **File Size Limit**: 10MB
- **Allowed MIME Types**: `application/pdf`
- **File Organization**: `{user_id}/{filename}`

## Key Components

### ResumeService

The main service class that handles all resume-related operations:

```dart
class ResumeService {
  // Singleton pattern
  static final ResumeService _instance = ResumeService._internal();
  factory ResumeService() => _instance;
  
  // Core methods
  Future<Map<String, dynamic>?> uploadResume()
  Future<Map<String, dynamic>?> getCurrentResume()
  Future<void> deleteResume(String resumeId, String filePath)
  bool validateFileSize(int fileSize)
  bool validateFileType(String fileName)
}
```

### ResumeRepository

Handles direct database and storage operations:

```dart
class ResumeRepository {
  // Database operations
  Future<Map<String, dynamic>?> getUserResume(String userId)
  Future<Map<String, dynamic>> uploadResume({...})
  Future<void> deleteResume(String resumeId, String filePath)
  Future<Map<String, dynamic>?> getResumeAnalysis(String resumeId)
}
```

### UploadResumeScreen

The main UI component with the following features:

- **State Management**: Loading, uploading, error, success states
- **File Upload**: PDF picker with validation
- **Resume Display**: Shows existing resume details
- **Actions**: Upload, replace, delete functionality

## File Upload Process

### 1. Permission Check
```dart
final hasPermission = await requestStoragePermission();
if (!hasPermission) {
  throw Exception('Storage permission is required');
}
```

### 2. File Selection
```dart
final result = await FilePicker.platform.pickFiles(
  type: FileType.custom,
  allowedExtensions: ['pdf'],
  allowMultiple: false,
);
```

### 3. Validation
```dart
// File type validation
if (!validateFileType(fileName)) {
  throw Exception('Only PDF files are supported');
}

// File size validation
if (!validateFileSize(fileSize)) {
  throw Exception('File size must be less than 10MB');
}
```

### 4. Upload Process
```dart
// Deactivate existing resume
await _supabase
    .from('resumes')
    .update({'is_active': false})
    .eq('user_id', userId)
    .eq('is_active', true);

// Upload to storage
await _supabase.storage
    .from('resumes')
    .upload(storagePath, file);

// Create database record
final response = await _supabase
    .from('resumes')
    .insert(resumeData)
    .select()
    .single();
```

## Security Features

### Row Level Security (RLS)

The resumes table has RLS policies that ensure:

- Users can only view their own resumes
- Users can only upload resumes for themselves
- Users can only delete their own resumes

```sql
CREATE POLICY "Users can view their own resumes" ON public.resumes
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own resumes" ON public.resumes
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can delete their own resumes" ON public.resumes
  FOR DELETE USING (auth.uid() = user_id);
```

### Storage Security

- Private bucket access
- User-specific file paths (`{user_id}/{filename}`)
- Automatic cleanup when resumes are deleted

## Error Handling

### Common Error Scenarios

1. **Authentication Errors**
   - User not logged in
   - Session expired

2. **Permission Errors**
   - Storage permission denied
   - File access denied

3. **Validation Errors**
   - Invalid file type (non-PDF)
   - File too large (>10MB)
   - Empty file selection

4. **Network Errors**
   - Upload timeout
   - Connection issues
   - Supabase service unavailable

### Error Display

Errors are displayed in a user-friendly format:

```dart
Container(
  padding: const EdgeInsets.all(12),
  decoration: BoxDecoration(
    color: Colors.red.shade50,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: Colors.red.shade200),
  ),
  child: Row(
    children: [
      Icon(Icons.error, color: Colors.red.shade600),
      const SizedBox(width: 8),
      Expanded(child: Text(_errorMessage!)),
      IconButton(
        icon: const Icon(Icons.close),
        onPressed: () => setState(() => _errorMessage = null),
      ),
    ],
  ),
)
```

## Usage Examples

### Basic Upload Flow

```dart
// 1. Initialize service
final resumeService = ResumeService();

// 2. Upload resume
try {
  final resumeData = await resumeService.uploadResume();
  if (resumeData != null) {
    print('Resume uploaded successfully!');
  }
} catch (e) {
  print('Upload failed: $e');
}
```

### Get Current Resume

```dart
// Get user's current resume
final currentResume = await resumeService.getCurrentResume();
if (currentResume != null) {
  print('Current resume: ${currentResume['file_name']}');
}
```

### Delete Resume

```dart
// Delete existing resume
await resumeService.deleteResume(resumeId, filePath);
print('Resume deleted successfully');
```

## Integration with Other Features

### Resume Analysis Integration

The resume upload feature is designed to integrate with the resume analysis feature:

- `is_analyzed` field tracks analysis status
- Resume analysis can be triggered after upload
- Analysis results stored in `resume_analysis` table

### Interview Session Integration

Resumes can be linked to interview sessions:

- Resume ID stored in `interview_sessions` table
- AI can use resume content for personalized questions
- Resume analysis can influence interview difficulty

## Testing

### Unit Tests

Key areas to test:

1. **File Validation**
   - PDF file type validation
   - File size validation
   - Empty file handling

2. **Upload Process**
   - Successful upload flow
   - Error handling
   - Existing resume replacement

3. **Database Operations**
   - Resume creation
   - Resume deletion
   - Active resume management

### Integration Tests

1. **Supabase Integration**
   - Storage upload/download
   - Database CRUD operations
   - RLS policy enforcement

2. **Permission Handling**
   - Storage permission requests
   - Permission denied scenarios

## Future Enhancements

### Planned Features

1. **Resume Versioning**
   - Keep history of uploaded resumes
   - Compare different versions

2. **Resume Templates**
   - Pre-built resume templates
   - Format validation

3. **Bulk Operations**
   - Upload multiple resumes
   - Batch analysis

4. **Advanced Validation**
   - Content validation
   - ATS compatibility checking

### Performance Optimizations

1. **File Compression**
   - Automatic PDF compression
   - Reduced storage costs

2. **Caching**
   - Resume metadata caching
   - Faster UI updates

3. **Background Processing**
   - Async resume analysis
   - Progress tracking

## Troubleshooting

### Common Issues

1. **Upload Fails**
   - Check file size (<10MB)
   - Verify PDF format
   - Ensure storage permission

2. **Permission Denied**
   - Request storage permission
   - Check app permissions in settings

3. **Database Errors**
   - Verify user authentication
   - Check RLS policies
   - Ensure proper table structure

### Debug Information

Enable debug logging:

```dart
// In resume_service.dart
debugPrint('Error uploading resume: $e');
```

Check Supabase logs for detailed error information.

## Dependencies

### Required Packages

```yaml
dependencies:
  file_picker: ^8.0.3
  permission_handler: ^11.3.1
  supabase_flutter: ^2.5.2
```

### Platform Permissions

#### Android
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

#### iOS
```xml
<key>NSDocumentsFolderUsageDescription</key>
<string>This app needs access to documents to upload resumes.</string>
```

## Conclusion

The Resume Upload feature provides a robust, secure, and user-friendly way for users to upload and manage their resumes. The feature follows clean architecture principles, includes comprehensive error handling, and integrates seamlessly with the broader AI Voice Interview App ecosystem.

The implementation ensures data security through proper RLS policies, provides excellent user experience with clear feedback, and maintains code quality through proper separation of concerns. 