import { MongoClient, Db } from "mongodb";

const DEFAULT_URI = "mongodb://devcontainer-mongodb:27017";
const DEFAULT_DB = "meowtopia";

let client: MongoClient | null = null;
let clientPromise: Promise<MongoClient> | null = null;

function getMongoUri(): string {
  return process.env.MEOWTOPIA_MONGODB_URL || process.env.MONGODB_URL || DEFAULT_URI;
}

// Don't throw during build - MongoDB is optional
if (!getMongoUri()) {
  console.warn('MongoDB URI not found. MongoDB sync will not be available.');
}

if (getMongoUri()) {
  if (process.env.NODE_ENV === "development") {
    // In development mode, use a global variable so that the value
    // is preserved across module reloads caused by HMR (Hot Module Replacement).
    let globalWithMongo = global as typeof globalThis & {
      _mongoClientPromise?: Promise<MongoClient>;
    };

    if (!globalWithMongo._mongoClientPromise) {
      client = new MongoClient(getMongoUri(), {
        maxPoolSize: 10,
      });
      globalWithMongo._mongoClientPromise = client.connect().then((client) => {
        console.log("✅ MongoDB connected");
        return client;
      }).catch((error) => {
        console.warn("⚠️  MongoDB connection error (non-critical):", error.message);
        throw error;
      });
    }
    clientPromise = globalWithMongo._mongoClientPromise;
  } else {
    // In production mode, it's best to not use a global variable.
    client = new MongoClient(getMongoUri(), {
      maxPoolSize: 10,
    });
    clientPromise = client.connect().then((client) => {
      console.log("✅ MongoDB connected");
      return client;
    }).catch((error) => {
      console.warn("⚠️  MongoDB connection error (non-critical):", error.message);
      throw error;
    });
  }
}

// Export a module-scoped MongoClient promise. By doing this in a
// separate module, the client can be shared across functions.
export default clientPromise;

export async function getDatabase(): Promise<Db> {
  if (!clientPromise) {
    throw new Error('MongoDB is not configured. Please set MEOWTOPIA_MONGODB_URL or MONGODB_URL in .env.local');
  }
  const client = await clientPromise;
  const dbName = process.env.MEOWTOPIA_MONGODB_DB || process.env.MONGODB_DB || DEFAULT_DB;
  return client.db(dbName);
}

export async function getMongoClient(): Promise<MongoClient> {
  if (!clientPromise) {
    throw new Error('MongoDB is not configured. Please set MEOWTOPIA_MONGODB_URL or MONGODB_URL in .env.local');
  }
  return clientPromise;
}















