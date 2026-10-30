-- Skillfyme PostgreSQL Init Script
-- This runs once when the postgres container is first created


-- Grant all privileges to application user
GRANT ALL PRIVILEGES ON DATABASE skillfyme TO skillfyme;

-- Enable UUID extension
\c skillfyme;
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Enrollment table
CREATE TABLE IF NOT EXISTS enrollments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id VARCHAR(100) NOT NULL,
  course_id VARCHAR(100) NOT NULL,
  status VARCHAR(50) DEFAULT 'active',
  progress INTEGER DEFAULT 0,
  enrolled_at TIMESTAMP DEFAULT NOW(),
  completed_at TIMESTAMP,
  updated_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, course_id)
);
CREATE INDEX IF NOT EXISTS idx_enrollments_user ON enrollments(user_id);
CREATE INDEX IF NOT EXISTS idx_enrollments_course ON enrollments(course_id);

-- Payments table
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id VARCHAR(100) NOT NULL,
  amount NUMERIC(10,2) NOT NULL,
  currency VARCHAR(10) DEFAULT 'USD',
  status VARCHAR(50) DEFAULT 'pending',
  provider VARCHAR(50) DEFAULT 'stripe',
  provider_payment_id VARCHAR(255),
  items JSONB DEFAULT '[]',
  coupon_code VARCHAR(100),
  discount NUMERIC(10,2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_payments_user ON payments(user_id);

-- Learning paths
CREATE TABLE IF NOT EXISTS learning_paths (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  slug VARCHAR(255) UNIQUE NOT NULL,
  description TEXT,
  short_description VARCHAR(300),
  category VARCHAR(100) NOT NULL,
  level VARCHAR(50) NOT NULL,
  price NUMERIC(10,2) DEFAULT 0,
  currency VARCHAR(10) DEFAULT 'USD',
  duration_weeks INTEGER,
  course_count INTEGER DEFAULT 0,
  enrolled_count INTEGER DEFAULT 0,
  is_bestseller BOOLEAN DEFAULT FALSE,
  is_published BOOLEAN DEFAULT FALSE,
  thumbnail VARCHAR(500),
  color VARCHAR(50),
  icon_color VARCHAR(50),
  courses JSONB DEFAULT '[]',
  skills JSONB DEFAULT '[]',
  prerequisites JSONB DEFAULT '[]',
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  published_at TIMESTAMP
);

-- Seed learning paths
INSERT INTO learning_paths (title, slug, description, category, level, price, duration_weeks, course_count, enrolled_count, is_bestseller, is_published, published_at, color, icon_color)
VALUES
  ('Full-Stack Web Developer', 'full-stack-web-developer', 'Master modern web development from HTML to deploying scalable Node.js + React applications.', 'Web Development', 'beginner', 199.00, 24, 8, 45000, TRUE, TRUE, NOW(), 'bg-blue-100', 'text-blue-600'),
  ('Cloud & DevOps Engineer', 'cloud-devops-engineer', 'Learn AWS, Kubernetes, Terraform, CI/CD, and site reliability engineering practices.', 'Cloud & DevOps', 'intermediate', 249.00, 32, 10, 32000, TRUE, TRUE, NOW(), 'bg-orange-100', 'text-orange-600'),
  ('Data Scientist & ML Engineer', 'data-scientist-ml-engineer', 'From Python basics to productionizing machine learning models with MLOps.', 'Data Science', 'intermediate', 299.00, 36, 12, 28000, FALSE, TRUE, NOW(), 'bg-purple-100', 'text-purple-600'),
  ('AI & Generative AI Engineer', 'ai-generative-ai-engineer', 'Dive deep into LLMs, prompt engineering, RAG architectures, and building production AI applications.', 'AI & Machine Learning', 'intermediate', 0, 22, 7, 62000, TRUE, TRUE, NOW(), 'bg-indigo-100', 'text-indigo-600')
ON CONFLICT (slug) DO NOTHING;

-- Assessments
CREATE TABLE IF NOT EXISTS assessments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title VARCHAR(255) NOT NULL,
  description TEXT,
  course_id VARCHAR(100),
  type VARCHAR(50) NOT NULL DEFAULT 'quiz',
  level VARCHAR(50),
  duration_minutes INTEGER DEFAULT 60,
  passing_score INTEGER DEFAULT 70,
  max_attempts INTEGER DEFAULT 3,
  is_proctored BOOLEAN DEFAULT FALSE,
  is_published BOOLEAN DEFAULT FALSE,
  question_count INTEGER DEFAULT 0,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_id UUID REFERENCES assessments(id) ON DELETE CASCADE,
  text TEXT NOT NULL,
  type VARCHAR(50) DEFAULT 'multiple_choice',
  options JSONB,
  correct_answer JSONB,
  explanation TEXT,
  points INTEGER DEFAULT 1,
  order_index INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  assessment_id UUID REFERENCES assessments(id),
  user_id VARCHAR(100) NOT NULL,
  status VARCHAR(50) DEFAULT 'in_progress',
  answers JSONB DEFAULT '{}',
  score NUMERIC(5,2),
  passed BOOLEAN,
  started_at TIMESTAMP DEFAULT NOW(),
  submitted_at TIMESTAMP,
  time_spent_seconds INTEGER
);
CREATE INDEX IF NOT EXISTS idx_attempts_user ON attempts(user_id);
CREATE INDEX IF NOT EXISTS idx_attempts_assessment ON attempts(assessment_id);

-- Seed assessments
INSERT INTO assessments (title, description, type, level, duration_minutes, passing_score, is_published, question_count)
VALUES
  ('Kubernetes Fundamentals Assessment', 'Validate your understanding of core Kubernetes concepts including pods, deployments, and services.', 'quiz', 'intermediate', 45, 75, TRUE, 30),
  ('JavaScript ES2023 Proficiency Test', 'Test your knowledge of modern JavaScript including async/await, modules, and new array methods.', 'quiz', 'beginner', 30, 70, TRUE, 20),
  ('Machine Learning Practitioner Exam', 'Comprehensive assessment covering ML algorithms, model evaluation, and deployment patterns.', 'exam', 'advanced', 90, 80, TRUE, 60),
  ('Python Data Analysis Skills Check', 'Hands-on assessment with pandas, NumPy, and data visualization using real datasets.', 'practical', 'intermediate', 60, 70, TRUE, 25)
ON CONFLICT DO NOTHING;

