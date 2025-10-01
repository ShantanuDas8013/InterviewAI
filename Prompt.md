You are an expert Flutter developer with a specialization in building data-driven UIs and integrating with Supabase.

Your task is to completely refactor the `interview_result_screen.dart` file. The goal is to create a comprehensive, user-friendly, and educational screen that provides detailed feedback to a candidate after a mock interview. The screen must serve as a powerful learning tool to help the candidate understand their performance, identify mistakes, and learn how to improve.

You **must** use the database schema defined in `SUPABASE_SETUP_GUIDE.md` and the storage structure from `SUPABASE_STORAGE_BUCKETS_GUIDE.md` to ensure correct data retrieval and functionality.

---

### **Core Functional Requirements**

The `interview_result_screen` must fetch and display the complete performance data for a specific `interview_session_id`. The UI must be structured into three main sections:

**1. Overall Performance Summary:**
At the top of the screen, display a summary card that fetches data primarily from the `interview_results` table:

- **Job Role**: Display `interview_results.job_role_title`.
- **Overall Score**: Prominently display `interview_results.overall_score` (out of 10).
- **AI Summary**: Show the `interview_results.ai_summary`.
- **Category Scores**: Display a breakdown of `technical_score`, `communication_score`, `problem_solving_score`, and `confidence_score`.

**2. Detailed Question-by-Question Breakdown:**
This is the most critical section. Create a list of expandable cards. For each question, you must fetch the corresponding records from `interview_responses` and join them with `interview_questions`. Each card must contain:

- The **Question Text** from `interview_questions.question_text`.
- The candidate's **Transcribed Answer** from `interview_responses.transcribed_text`.
- **Audio Playback**: Include a button that plays the candidate's recorded answer using the `audio_file_path` from the `interview-audio` bucket, as detailed in the storage guide.
- **AI Feedback**: Display the detailed `interview_responses.ai_feedback`.
- **Suggested Answer**: Show the `interview_responses.ideal_answer_comparison` or, if that is null, fall back to `interview_questions.sample_answer`. This is crucial for learning.
- **Areas to Improve**: Display the `interview_responses.suggested_improvement`.
- **A Score** for the individual question from `interview_responses.response_score`.

**3. Actionable Improvement Plan:**
At the bottom of the screen, provide a dedicated section that synthesizes the feedback into actionable advice, using data from the `interview_results` and `job_roles` tables. This section must:

- List the key **Strengths** from `interview_results.strengths_analysis`.
- List the specific **Areas for Improvement** from `interview_results.areas_for_improvement`.
- Relate these improvement areas to the **Required Skills** for the job by fetching `job_roles.required_skills` using the `job_role_id`.

---

### **Technical Implementation & Data Handling (Supabase)**

- **Data Fetching**: The screen's state management logic must perform the necessary queries to the Supabase database upon loading. It should receive a single `interview_session_id` and use it to fetch all related data from `interview_results` and `interview_responses`.
- **Database Joins**: Your Supabase query for the question breakdown must effectively join `interview_responses` with `interview_questions` on `question_id`.
- **AI Content Generation (Fallback Logic)**: If key analytical fields like `ideal_answer_comparison` or `areas_for_improvement` are found to be `NULL` in the database, you must implement a fallback mechanism. This mechanism will make a new, on-the-fly call to the Gemini API. The prompt for this call must provide the necessary context (the question text, the user's transcribed answer, and the job role title) and explicitly ask the AI to generate the missing "ideal answer" or "improvement suggestions."

---

### **Your Task**

Please provide the complete, production-ready Dart code for the refactored `interview_result_screen.dart` file.

Your implementation must include:

1.  Robust state management (e.g., using `FutureBuilder` or a state management solution like Provider/Riverpod) to handle all asynchronous data fetching from Supabase.
2.  Clean, well-structured, and visually appealing UI widgets for each of the three required sections.
3.  The specific Supabase queries needed to fetch and join the required data.
4.  The fallback logic for making secondary API calls to Gemini to generate supplementary feedback if it is missing from the database.
5.  Proper error handling to manage scenarios where data fetching fails.

The final code should be well-documented, easy to understand, and follow modern Flutter best practices.
