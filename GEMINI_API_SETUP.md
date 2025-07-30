# Gemini API Setup Guide

## Overview
This app uses Google's Gemini AI API to analyze uploaded resumes and provide comprehensive insights.

## Setup Instructions

### 1. Get Gemini API Key
1. Go to [Google AI Studio](https://makersuite.google.com/app/apikey)
2. Sign in with your Google account
3. Click "Create API Key"
4. Copy the generated API key

### 2. Configure Environment Variables
Create a `.env` file in the root directory with the following variables:

```env
# Supabase Configuration
SUPABASE_URL=your_supabase_url_here
SUPABASE_ANON_KEY=your_supabase_anon_key_here

# Google Gemini API
GEMINI_API_KEY=your_gemini_api_key_here
```

### 3. Features
The Gemini API integration provides:

- **Skills Assessment**: Categorizes technical, soft, and domain skills
- **Experience Summary**: Analyzes work experience and achievements
- **Strengths Analysis**: Identifies key strengths and unique selling points
- **Improvement Suggestions**: Areas where the resume can be enhanced
- **Interview Tips**: Personalized interview preparation advice
- **Job Recommendations**: Suitable job roles based on experience
- **Overall Score**: Resume quality rating out of 100

### 4. Usage
1. Upload a resume in PDF format
2. Click "Analyze Resume" button
3. Wait for AI analysis to complete
4. View comprehensive analysis results

### 5. Security Notes
- Never commit your `.env` file to version control
- Keep your API keys secure
- Monitor API usage to stay within limits

## Troubleshooting

### Common Issues
1. **API Key Not Found**: Ensure `.env` file exists and contains `GEMINI_API_KEY`
2. **Analysis Fails**: Check internet connection and API key validity
3. **PDF Parsing Issues**: Ensure PDF is readable and not corrupted

### Support
For API-related issues, refer to the [Google AI Studio documentation](https://ai.google.dev/docs). 