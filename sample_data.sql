-- ========================================
-- SAMPLE DATA FOR AI VOICE INTERVIEW APP
-- ========================================

-- Insert sample job roles
INSERT INTO public.job_roles
    (title, category, description, required_skills, industry)
VALUES
    ('Frontend Developer', 'technology', 'Develop user-facing web applications', ARRAY
['HTML', 'CSS', 'JavaScript', 'React', 'Vue.js'], 'Technology'),
('Backend Developer', 'technology', 'Develop server-side applications and APIs', ARRAY['Node.js', 'Python', 'Java', 'SQL', 'REST APIs'], 'Technology'),
('Full Stack Developer', 'technology', 'Develop both frontend and backend applications', ARRAY['JavaScript', 'React', 'Node.js', 'SQL', 'Git'], 'Technology'),
('Data Scientist', 'technology', 'Analyze data and build predictive models', ARRAY['Python', 'R', 'SQL', 'Machine Learning', 'Statistics'], 'Technology'),
('Product Manager', 'management', 'Manage product development lifecycle', ARRAY['Product Strategy', 'Analytics', 'Communication', 'Leadership'], 'Technology'),
('Digital Marketing Specialist', 'marketing', 'Execute digital marketing campaigns', ARRAY['SEO', 'SEM', 'Social Media', 'Analytics', 'Content Marketing'], 'Marketing'),
('UI/UX Designer', 'design', 'Design user interfaces and experiences', ARRAY['Figma', 'Adobe XD', 'Sketch', 'Prototyping', 'User Research'], 'Technology'),
('DevOps Engineer', 'technology', 'Manage deployment and infrastructure', ARRAY['Docker', 'Kubernetes', 'AWS', 'CI/CD', 'Linux'], 'Technology'),
('Mobile Developer', 'technology', 'Develop mobile applications', ARRAY['Flutter', 'React Native', 'Swift', 'Kotlin', 'Mobile UI'], 'Technology'),
('Business Analyst', 'analysis', 'Analyze business requirements and processes', ARRAY['SQL', 'Excel', 'Business Intelligence', 'Requirements Analysis'], 'Business');

-- Insert sample interview questions for Frontend Developer
INSERT INTO public.interview_questions
    (job_role_id, question_text, question_type, difficulty_level, expected_answer_keywords, time_limit_seconds)
VALUES
    ((SELECT id
        FROM public.job_roles
        WHERE title = 'Frontend Developer'
LIMIT 1), 'What is the difference between let, const, and var in JavaScript?', 'technical', 'medium', ARRAY['scope', 'hoisting', 'reassignment', 'block scope'], 120),
((SELECT id
FROM public.job_roles
WHERE title = 'Frontend Developer'
LIMIT 1), 'Explain the concept of Virtual DOM in React.', 'technical', 'medium', ARRAY['virtual dom', 'performance', 'reconciliation', 'diffing'], 150),
((SELECT id
FROM public.job_roles
WHERE title = 'Frontend Developer'
LIMIT 1), 'Tell me about a challenging project you worked on and how you overcame the difficulties.', 'behavioral', 'medium', ARRAY['problem-solving', 'teamwork', 'communication', 'persistence'], 180),
((SELECT id
FROM public.job_roles
WHERE title = 'Frontend Developer'
LIMIT 1), 'How do you ensure your web applications are accessible?', 'technical', 'medium', ARRAY['accessibility', 'screen readers', 'ARIA', 'semantic HTML'], 120);

-- Insert sample interview questions for Backend Developer
INSERT INTO public.interview_questions
    (job_role_id, question_text, question_type, difficulty_level, expected_answer_keywords, time_limit_seconds)
VALUES
    ((SELECT id
        FROM public.job_roles
        WHERE title = 'Backend Developer'
LIMIT 1), 'Explain the difference between SQL and NoSQL databases.', 'technical', 'medium', ARRAY['relational', 'document', 'scalability', 'ACID', 'consistency'], 150),
((SELECT id
FROM public.job_roles
WHERE title = 'Backend Developer'
LIMIT 1), 'What is RESTful API design and its principles?', 'technical', 'medium', ARRAY['REST', 'HTTP methods', 'stateless', 'resources', 'endpoints'], 150),
((SELECT id
FROM public.job_roles
WHERE title = 'Backend Developer'
LIMIT 1), 'How do you handle database optimization?', 'technical', 'hard', ARRAY['indexing', 'query optimization', 'caching', 'normalization'], 180),
((SELECT id
FROM public.job_roles
WHERE title = 'Backend Developer'
LIMIT 1), 'Describe a time when you had to debug a complex issue in production.', 'behavioral', 'medium', ARRAY['debugging', 'problem-solving', 'monitoring', 'logs'], 180);

-- Insert sample interview questions for Data Scientist
INSERT INTO public.interview_questions
    (job_role_id, question_text, question_type, difficulty_level, expected_answer_keywords, time_limit_seconds)
VALUES
    ((SELECT id
        FROM public.job_roles
        WHERE title = 'Data Scientist'
LIMIT 1), 'Explain the difference between supervised and unsupervised learning.', 'technical', 'medium', ARRAY['supervised', 'unsupervised', 'labeled data', 'clustering', 'classification'], 150),
((SELECT id
FROM public.job_roles
WHERE title = 'Data Scientist'
LIMIT 1), 'How do you handle missing data in a dataset?', 'technical', 'medium', ARRAY['missing data', 'imputation', 'deletion', 'mean', 'median'], 120),
((SELECT id
FROM public.job_roles
WHERE title = 'Data Scientist'
LIMIT 1), 'Walk me through your approach to a data science project.', 'behavioral', 'medium', ARRAY['data collection', 'cleaning', 'analysis', 'modeling', 'validation'], 180);

-- Insert app settings
INSERT INTO public.app_settings
    (setting_key, setting_value, description)
VALUES
    ('max_interview_duration', '3600', 'Maximum interview duration in seconds'),
    ('default_questions_per_interview', '10', 'Default number of questions per interview session'),
    ('gemini_api_timeout', '30', 'Gemini API timeout in seconds'),
    ('max_resume_size_mb', '10', 'Maximum resume file size in MB'),
    ('supported_audio_formats', '["wav", "mp3", "m4a"]', 'Supported audio formats for interview responses'),
    ('max_daily_interviews', '5', 'Maximum interviews per day for free users'),
    ('premium_daily_interviews', '20', 'Maximum interviews per day for premium users'),
    ('interview_feedback_delay', '2', 'Delay in seconds before showing feedback'),
    ('speech_recognition_timeout', '10', 'Speech recognition timeout in seconds'),
    ('default_interview_difficulty', 'medium', 'Default difficulty level for interviews');
