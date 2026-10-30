// Skillfyme MongoDB Init Script
// Runs once during initial container setup

db = db.getSiblingDB('skillfyme');

// Create application user
db.createUser({
  user: 'skillfyme',
  pwd: 'skillfyme_secret',
  roles: [{ role: 'readWrite', db: 'skillfyme' }],
});

// Courses collection with seed data
db.courses.insertMany([
  {
    title: 'Cloud-Native Architecture with Kubernetes',
    slug: 'cloud-native-architecture-kubernetes',
    description: 'A comprehensive course on building, deploying, and scaling cloud-native applications using Kubernetes, Docker, Istio, and modern DevOps tooling.',
    shortDescription: 'Master Kubernetes and cloud-native architecture patterns',
    category: 'Cloud & DevOps',
    level: 'intermediate',
    instructor: { id: 'inst-001', name: 'Priya Mehta', title: 'Principal Cloud Architect' },
    price: 79.99,
    currency: 'USD',
    durationHours: 24,
    lectureCount: 120,
    enrolledCount: 18500,
    rating: 4.8,
    reviewCount: 2341,
    isFeatured: true,
    status: 'published',
    publishedAt: new Date('2024-01-15'),
    tags: ['kubernetes', 'docker', 'devops', 'cloud-native', 'microservices'],
    learningOutcomes: [
      'Design and deploy microservice architectures on Kubernetes',
      'Implement CI/CD pipelines with GitHub Actions',
      'Apply distributed systems patterns',
      'Configure Istio service mesh for observability',
    ],
    createdAt: new Date(),
    updatedAt: new Date(),
  },
  {
    title: 'Full-Stack React & Node.js Development',
    slug: 'full-stack-react-nodejs',
    description: 'Build production-ready full-stack applications with React 18, Node.js, Express, MongoDB, and modern deployment patterns.',
    shortDescription: 'From zero to production full-stack developer',
    category: 'Web Development',
    level: 'beginner',
    instructor: { id: 'inst-002', name: 'James Whitfield', title: 'Senior Software Engineer' },
    price: 89.99,
    currency: 'USD',
    durationHours: 42,
    lectureCount: 210,
    enrolledCount: 42000,
    rating: 4.7,
    reviewCount: 5672,
    isFeatured: true,
    status: 'published',
    publishedAt: new Date('2024-02-01'),
    tags: ['react', 'nodejs', 'javascript', 'web-development', 'mongodb'],
    createdAt: new Date(),
    updatedAt: new Date(),
  },
  {
    title: 'Data Science with Python & Machine Learning',
    slug: 'data-science-python-ml',
    description: 'From Python fundamentals to deploying ML models in production. Covers pandas, scikit-learn, PyTorch, and MLOps.',
    shortDescription: 'End-to-end data science and ML engineering',
    category: 'Data Science',
    level: 'intermediate',
    instructor: { id: 'inst-003', name: 'Sara Chen', title: 'Staff ML Engineer' },
    price: 99.99,
    currency: 'USD',
    durationHours: 36,
    lectureCount: 180,
    enrolledCount: 28000,
    rating: 4.9,
    reviewCount: 3210,
    isFeatured: true,
    status: 'published',
    publishedAt: new Date('2024-01-20'),
    tags: ['python', 'machine-learning', 'data-science', 'pytorch', 'mlops'],
    createdAt: new Date(),
    updatedAt: new Date(),
  },
  {
    title: 'AI & Generative AI Engineering',
    slug: 'ai-generative-ai-engineering',
    description: 'Dive deep into LLMs, prompt engineering, RAG architectures, fine-tuning, and building production AI applications.',
    shortDescription: 'Build production AI systems with LLMs and RAG',
    category: 'AI & Machine Learning',
    level: 'intermediate',
    instructor: { id: 'inst-007', name: 'Fatima Al-Hassan', title: 'AI Research Engineer' },
    price: 0,
    currency: 'USD',
    durationHours: 28,
    lectureCount: 140,
    enrolledCount: 35000,
    rating: 4.8,
    reviewCount: 4200,
    isFeatured: true,
    status: 'published',
    publishedAt: new Date('2024-04-01'),
    tags: ['ai', 'llm', 'rag', 'prompt-engineering', 'generative-ai'],
    createdAt: new Date(),
    updatedAt: new Date(),
  },
]);

// Indexes
db.courses.createIndex({ status: 1, isFeatured: 1 });
db.courses.createIndex({ slug: 1 }, { unique: true });
db.courses.createIndex({ title: 'text', description: 'text', tags: 'text' });
db.courses.createIndex({ category: 1, level: 1, status: 1 });

// Live sessions
db.sessions.insertMany([
  {
    title: 'Kubernetes in Production: Lessons from the Trenches',
    description: 'Real-world war stories from running Kubernetes at scale.',
    format: 'webinar',
    instructor: { id: 'inst-001', name: 'Priya Mehta', title: 'Principal Cloud Architect' },
    scheduledAt: new Date('2026-06-15T14:00:00Z'),
    durationMinutes: 90,
    capacity: 500,
    enrolledCount: 342,
    price: 0,
    currency: 'USD',
    isLive: false,
    status: 'scheduled',
    tags: ['kubernetes', 'devops'],
    enrolledUsers: [],
    createdAt: new Date(),
    updatedAt: new Date(),
  },
  {
    title: 'React 18 Deep Dive: Concurrent Features & Suspense',
    description: 'Hands-on workshop covering React 18 concurrent mode.',
    format: 'workshop',
    instructor: { id: 'inst-002', name: 'James Whitfield', title: 'Senior Software Engineer' },
    scheduledAt: new Date('2026-06-16T10:00:00Z'),
    durationMinutes: 180,
    capacity: 30,
    enrolledCount: 28,
    price: 49,
    currency: 'USD',
    isLive: false,
    status: 'scheduled',
    tags: ['react', 'javascript'],
    enrolledUsers: [],
    createdAt: new Date(),
    updatedAt: new Date(),
  },
]);

db.sessions.createIndex({ scheduledAt: 1, status: 1 });
db.sessions.createIndex({ format: 1, status: 1 });

print('Skillfyme MongoDB initialization complete');
