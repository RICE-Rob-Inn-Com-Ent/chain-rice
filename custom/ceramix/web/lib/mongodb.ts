import { MongoClient, Db } from "mongodb";

const uri = process.env.MONGODB_URI;
const options = {};

// Don't throw during build - MongoDB is optional
if (!uri) {
  console.warn('MongoDB URI not found. AI workflows will not be available.');
}

let client: MongoClient | null = null;
let clientPromise: Promise<MongoClient> | null = null;

if (uri) {
  if (process.env.NODE_ENV === "development") {
    // In development mode, use a global variable so that the value
    // is preserved across module reloads caused by HMR (Hot Module Replacement).
    let globalWithMongo = global as typeof globalThis & {
      _mongoClientPromise?: Promise<MongoClient>;
    };

    if (!globalWithMongo._mongoClientPromise) {
      client = new MongoClient(uri, options);
      globalWithMongo._mongoClientPromise = client.connect();
    }
    clientPromise = globalWithMongo._mongoClientPromise;
  } else {
    // In production mode, it's best to not use a global variable.
    client = new MongoClient(uri, options);
    clientPromise = client.connect();
  }
}

// Export a module-scoped MongoClient promise. By doing this in a
// separate module, the client can be shared across functions.
export default clientPromise;

export async function getDatabase(): Promise<Db> {
  if (!clientPromise) {
    throw new Error('MongoDB is not configured. Please set MONGODB_URI in .env.local');
  }
  const client = await clientPromise;
  return client.db(process.env.MONGODB_DB_NAME || "ceramix_ai");
}

export async function getAIWorkflowsCollection() {
  const db = await getDatabase();
  return db.collection("ai_workflows");
}

export async function getLORATrainingCollection() {
  const db = await getDatabase();
  return db.collection("lora_training");
}

