import { MongoClient, Db } from "mongodb";

const DEFAULT_URI = "mongodb://devcontainer-mongodb:27017";
const DEFAULT_DB = "code_rice";

let clientPromise: Promise<MongoClient> | null = null;

function getMongoUri(): string {
  return process.env.CODE_RICE_MONGODB_URL || process.env.MONGODB_URL || DEFAULT_URI;
}

export function getMongoClient(): Promise<MongoClient> {
  if (!clientPromise) {
    const uri = getMongoUri();
    clientPromise = MongoClient.connect(uri, {
      maxPoolSize: 10,
    });
  }
  return clientPromise;
}

export async function getMongoDb(): Promise<Db> {
  const client = await getMongoClient();
  const dbName = process.env.CODE_RICE_MONGODB_DB || process.env.MONGODB_DB || DEFAULT_DB;
  return client.db(dbName);
}


