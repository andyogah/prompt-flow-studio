// =================================
// MONGODB INITIALIZATION SCRIPT
// =================================

print("🚀 Initializing Prompt Flow MongoDB database...");

// Switch to the prompt_flow database
db = db.getSiblingDB('prompt_flow');

// Create collections with proper schemas and indexes
print("📁 Creating collections with validation schemas...");

// Flows collection - stores prompt flow definitions
db.createCollection('flows', {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["name", "version", "nodes", "created_at"],
      properties: {
        name: { bsonType: "string", description: "Flow name" },
        description: { bsonType: "string" },
        version: { bsonType: "string", description: "Semantic version" },
        tags: { bsonType: "array", items: { bsonType: "string" } },
        nodes: { bsonType: "array", description: "Flow nodes" },
        connections: { bsonType: "array", description: "Node connections" },
        status: { bsonType: "string", enum: ["draft", "active", "archived"] },
        metadata: { bsonType: "object" },
        created_at: { bsonType: "date" },
        updated_at: { bsonType: "date" }
      }
    }
  }
});

// Flow executions collection - stores execution history
db.createCollection('flow_executions', {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["flow_id", "status", "started_at"],
      properties: {
        flow_id: { bsonType: "objectId" },
        flow_version: { bsonType: "string" },
        inputs: { bsonType: "object" },
        outputs: { bsonType: "object" },
        status: { 
          bsonType: "string", 
          enum: ["pending", "running", "completed", "failed", "cancelled"]
        },
        error_message: { bsonType: "string" },
        execution_time_ms: { bsonType: "number" },
        token_usage: { bsonType: "object" },
        started_at: { bsonType: "date" },
        completed_at: { bsonType: "date" }
      }
    }
  }
});

// Prompts collection - stores individual prompt templates
db.createCollection('prompts', {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["template", "version", "created_at"],
      properties: {
        name: { bsonType: "string" },
        template: { bsonType: "string", description: "Prompt template" },
        description: { bsonType: "string" },
        version: { bsonType: "string" },
        variables: { bsonType: "array", items: { bsonType: "string" } },
        examples: { bsonType: "array" },
        model_config: { bsonType: "object" },
        performance_metrics: { bsonType: "object" },
        tags: { bsonType: "array", items: { bsonType: "string" } },
        template_hash: { bsonType: "string" },
        created_at: { bsonType: "date" },
        updated_at: { bsonType: "date" }
      }
    }
  }
});

// Experiments collection - stores A/B testing experiments
db.createCollection('experiments', {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["name", "created_at"],
      properties: {
        name: { bsonType: "string" },
        description: { bsonType: "string" },
        variants: { bsonType: "array" },
        test_cases: { bsonType: "array" },
        results: { bsonType: "array" },
        metrics: { bsonType: "object" },
        status: { 
          bsonType: "string", 
          enum: ["draft", "running", "completed", "archived"]
        },
        created_at: { bsonType: "date" },
        updated_at: { bsonType: "date" }
      }
    }
  }
});

// Experiment results collection - stores A/B test results
db.createCollection('experiment_results', {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["experiment_id", "variant", "created_at"],
      properties: {
        experiment_id: { bsonType: "objectId" },
        variant: { bsonType: "string" },
        response: { bsonType: "string" },
        metrics: { bsonType: "object" },
        user_feedback: { bsonType: "object" },
        created_at: { bsonType: "date" }
      }
    }
  }
});

// Users collection - stores user accounts and preferences
db.createCollection('users', {
  validator: {
    $jsonSchema: {
      bsonType: "object",
      required: ["username", "email", "created_at"],
      properties: {
        username: { bsonType: "string" },
        email: { bsonType: "string" },
        full_name: { bsonType: "string" },
        role: { bsonType: "string", enum: ["admin", "user", "viewer"] },
        is_active: { bsonType: "bool" },
        preferences: { bsonType: "object" },
        created_at: { bsonType: "date" },
        last_login: { bsonType: "date" }
      }
    }
  }
});

print("✅ Collections with validation schemas created successfully!");

// Create indexes for optimal query performance
print("📊 Creating performance indexes...");

// Flows indexes
db.flows.createIndex({ "name": 1 }, { unique: true });
db.flows.createIndex({ "tags": 1 });
db.flows.createIndex({ "status": 1 });
db.flows.createIndex({ "created_at": -1 });
db.flows.createIndex({ "name": "text", "description": "text" });

// Flow executions indexes
db.flow_executions.createIndex({ "flow_id": 1, "created_at": -1 });
db.flow_executions.createIndex({ "status": 1 });
db.flow_executions.createIndex({ "execution_time_ms": 1 });
db.flow_executions.createIndex({ "started_at": -1 });

// Prompts indexes
db.prompts.createIndex({ "template_hash": 1 }, { unique: true });
db.prompts.createIndex({ "name": 1 });
db.prompts.createIndex({ "tags": 1 });
db.prompts.createIndex({ "version": 1 });
db.prompts.createIndex({ "created_at": -1 });
db.prompts.createIndex({ "template": "text", "description": "text" });

// Experiments indexes
db.experiments.createIndex({ "name": 1 });
db.experiments.createIndex({ "status": 1 });
db.experiments.createIndex({ "created_at": -1 });

// Experiment results indexes
db.experiment_results.createIndex({ "experiment_id": 1, "created_at": -1 });
db.experiment_results.createIndex({ "variant": 1 });

// Users indexes
db.users.createIndex({ "email": 1 }, { unique: true });
db.users.createIndex({ "username": 1 }, { unique: true });
db.users.createIndex({ "created_at": -1 });

print("✅ Performance indexes created successfully!");

// Insert sample data for development
print("🌱 Seeding sample data...");

// Sample flow
const sampleFlow = {
    name: "Welcome Flow",
    description: "A simple welcome message flow for new users",
    version: "1.0.0",
    nodes: [
        {
            id: "input-1",
            type: "input",
            position: { x: 100, y: 100 },
            data: { 
                label: "User Input",
                schema: { "user_name": "string" }
            }
        },
        {
            id: "prompt-1",
            type: "prompt",
            position: { x: 300, y: 100 },
            data: {
                label: "Welcome Prompt",
                template: "Hello {user_name}! Welcome to Prompt Flow. How can I help you today?",
                variables: ["user_name"]
            }
        },
        {
            id: "llm-1",
            type: "llm",
            position: { x: 500, y: 100 },
            data: {
                label: "GPT-4 Response",
                provider: "openai",
                model: "gpt-4",
                temperature: 0.7,
                max_tokens: 150
            }
        },
        {
            id: "output-1",
            type: "output",
            position: { x: 700, y: 100 },
            data: {
                label: "Response Output",
                format: "text"
            }
        }
    ],
    connections: [
        { source: "input-1", target: "prompt-1" },
        { source: "prompt-1", target: "llm-1" },
        { source: "llm-1", target: "output-1" }
    ],
    tags: ["welcome", "starter", "example"],
    status: "active",
    metadata: { created_by: "system" },
    created_at: new Date(),
    updated_at: new Date()
};

const flowResult = db.flows.insertOne(sampleFlow);
print(`✅ Sample flow created with ID: ${flowResult.insertedId}`);

// Sample prompt templates
const samplePrompts = [
    {
        name: "Sentiment Analysis",
        template: "Analyze the sentiment of the following text and respond with 'positive', 'negative', or 'neutral': {text}",
        description: "Analyzes text sentiment with structured output",
        variables: ["text"],
        tags: ["sentiment", "analysis"],
        version: "1.0",
        template_hash: "hash_sentiment_v1",
        model_config: { temperature: 0.3, max_tokens: 50 },
        created_at: new Date()
    },
    {
        name: "Code Review",
        template: "Review the following code and provide feedback on:\n1. Code quality\n2. Potential bugs\n3. Suggestions for improvement\n\nCode:\n{code}",
        description: "Comprehensive code review with structured feedback",
        variables: ["code"],
        tags: ["code", "review", "programming"],
        version: "1.0",
        template_hash: "hash_code_review_v1",
        model_config: { temperature: 0.5, max_tokens: 500 },
        created_at: new Date()
    },
    {
        name: "Email Generator",
        template: "Write a professional email with the following details:\nSubject: {subject}\nRecipient: {recipient}\nTone: {tone}\nMain message: {message}",
        description: "Generates professional emails with specified tone and content",
        variables: ["subject", "recipient", "tone", "message"],
        tags: ["email", "communication", "business"],
        version: "1.0",
        template_hash: "hash_email_gen_v1",
        model_config: { temperature: 0.7, max_tokens: 300 },
        created_at: new Date()
    }
];

const promptResult = db.prompts.insertMany(samplePrompts);
print(`✅ ${promptResult.insertedIds.length} sample prompts created`);

// Sample admin user (for development only)
const adminUser = {
    username: "admin",
    email: "admin@prompt-flow.dev",
    full_name: "System Administrator",
    role: "admin",
    is_active: true,
    preferences: {
        theme: "light",
        notifications: true,
        auto_save: true
    },
    created_at: new Date(),
    last_login: null
};

const userResult = db.users.insertOne(adminUser);
print(`✅ Admin user created with ID: ${userResult.insertedId}`);

print("🎉 MongoDB initialization completed successfully!");
print("📋 Summary:");
print(`   - Collections created: 6 (with validation schemas)`);
print(`   - Performance indexes: Created for all collections`);
print(`   - Sample flows: 1`);
print(`   - Sample prompts: ${samplePrompts.length}`);
print(`   - Users created: 1`);
print("🚀 Database is ready for Prompt Flow with enterprise-grade schema validation!");
