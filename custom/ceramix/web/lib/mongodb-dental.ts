import { getDatabase } from "@/lib/mongodb";
import { ObjectId } from "mongodb";

export interface DentalVisit {
  _id?: ObjectId;
  visitId?: string; // UUID string for backward compatibility
  patientId: string; // UUID from PostgreSQL
  visitDate: string; // ISO date string (YYYY-MM-DD)
  visitTime?: string | null; // Time string (HH:MM:SS)
  dentistId?: string | null; // UUID from PostgreSQL (dentists table)
  notes?: string | null;
  createdBy: string; // UUID from PostgreSQL (users table)
  createdAt: Date;
  updatedAt: Date;
}

export interface DentalChartEntry {
  _id?: ObjectId;
  visitId: string; // UUID string - reference to DentalVisit.visitId
  patientId: string; // UUID from PostgreSQL
  toothNumber: number;
  surface?: string | null;
  category: string;
  conditionType: string;
  notes?: string | null;
  createdBy: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface DentalChartCustomEntry {
  _id?: ObjectId;
  visitId: string; // UUID string - reference to DentalVisit.visitId
  patientId: string; // UUID from PostgreSQL
  toothNumber: number;
  customText: string;
  createdBy: string;
  createdAt: Date;
  updatedAt: Date;
}

// Collections
export async function getDentalVisitsCollection() {
  const db = await getDatabase();
  return db.collection<DentalVisit>("dental_visits");
}

export async function getDentalChartEntriesCollection() {
  const db = await getDatabase();
  return db.collection<DentalChartEntry>("dental_chart_entries");
}

export async function getDentalChartCustomEntriesCollection() {
  const db = await getDatabase();
  return db.collection<DentalChartCustomEntry>("dental_chart_custom_entries");
}

// Create indexes on first use
export async function ensureDentalChartIndexes() {
  const visitsCollection = await getDentalVisitsCollection();
  const entriesCollection = await getDentalChartEntriesCollection();
  const customCollection = await getDentalChartCustomEntriesCollection();

  // Visit indexes
  await visitsCollection.createIndexes([
    { key: { patientId: 1 } },
    { key: { visitDate: -1 } },
    { key: { visitId: 1 }, unique: true, sparse: true },
    { key: { patientId: 1, visitDate: -1 } },
    { key: { createdAt: -1 } },
  ]);

  // Entry indexes
  await entriesCollection.createIndexes([
    { key: { patientId: 1 } },
    { key: { visitId: 1 } },
    { key: { toothNumber: 1 } },
    { key: { patientId: 1, visitId: 1 } },
    { key: { patientId: 1, visitId: 1, toothNumber: 1 } },
  ]);

  // Custom entry indexes
  await customCollection.createIndexes([
    { key: { patientId: 1 } },
    { key: { visitId: 1 } },
    { key: { toothNumber: 1 } },
    { key: { patientId: 1, visitId: 1 } },
    { key: { patientId: 1, visitId: 1, toothNumber: 1 } },
  ]);
}

// Generate UUID v4 using crypto.randomUUID()
function generateUUID(): string {
  if (typeof crypto !== "undefined" && crypto.randomUUID) {
    return crypto.randomUUID();
  }
  // Fallback for environments without crypto.randomUUID (should not happen in Node.js 19+)
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function (c) {
    const r = (Math.random() * 16) | 0;
    const v = c === "x" ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

// Create a new dental visit
export async function createDentalVisit(
  visit: Omit<DentalVisit, "_id" | "visitId" | "createdAt" | "updatedAt">
): Promise<string> {
  await ensureDentalChartIndexes();
  const collection = await getDentalVisitsCollection();

  const now = new Date();
  const visitId = generateUUID();
  const document: DentalVisit = {
    ...visit,
    visitId,
    createdAt: now,
    updatedAt: now,
  };

  await collection.insertOne(document);
  return visitId;
}

// Get visits for a patient
export async function getDentalVisits(
  patientId: string,
  limit: number = 10
): Promise<DentalVisit[]> {
  await ensureDentalChartIndexes();
  const collection = await getDentalVisitsCollection();

  return collection
    .find({ patientId })
    .sort({ visitDate: -1, visitTime: -1 })
    .limit(limit)
    .toArray();
}

// Get latest visit ID for a patient
export async function getLatestVisitId(patientId: string): Promise<string | null> {
  await ensureDentalChartIndexes();
  const collection = await getDentalVisitsCollection();

  const latestVisit = await collection
    .findOne(
      { patientId },
      { sort: { visitDate: -1, visitTime: -1 } }
    );

  return latestVisit?.visitId || null;
}

// Get visit by ID
export async function getDentalVisitById(visitId: string): Promise<DentalVisit | null> {
  await ensureDentalChartIndexes();
  const collection = await getDentalVisitsCollection();

  return collection.findOne({ visitId });
}

// Get entries for a patient and visit
export async function getDentalChartEntries(
  patientId: string,
  visitId?: string | null
): Promise<DentalChartEntry[]> {
  await ensureDentalChartIndexes();
  const collection = await getDentalChartEntriesCollection();

  const query: any = { patientId };
  if (visitId) {
    query.visitId = visitId;
  } else {
    // Get latest visit entries
    const latestVisit = await getLatestVisitId(patientId);
    if (latestVisit) {
      query.visitId = latestVisit;
    } else {
      return [];
    }
  }

  return collection.find(query).sort({ createdAt: 1 }).toArray();
}

// Get custom entries for a patient and visit
export async function getDentalChartCustomEntries(
  patientId: string,
  visitId?: string | null
): Promise<DentalChartCustomEntry[]> {
  await ensureDentalChartIndexes();
  const collection = await getDentalChartCustomEntriesCollection();

  const query: any = { patientId };
  if (visitId) {
    query.visitId = visitId;
  } else {
    // Get latest visit entries
    const latestVisit = await getLatestVisitId(patientId);
    if (latestVisit) {
      query.visitId = latestVisit;
    } else {
      return [];
    }
  }

  return collection.find(query).sort({ createdAt: 1 }).toArray();
}

// Save a dental chart entry
export async function saveDentalChartEntry(
  entry: Omit<DentalChartEntry, "_id" | "createdAt" | "updatedAt">
): Promise<string> {
  await ensureDentalChartIndexes();
  const collection = await getDentalChartEntriesCollection();

  const now = new Date();
  const document: DentalChartEntry = {
    ...entry,
    createdAt: now,
    updatedAt: now,
  };

  const result = await collection.insertOne(document);
  return result.insertedId.toString();
}

// Save a custom entry
export async function saveDentalChartCustomEntry(
  entry: Omit<DentalChartCustomEntry, "_id" | "createdAt" | "updatedAt">
): Promise<string> {
  await ensureDentalChartIndexes();
  const collection = await getDentalChartCustomEntriesCollection();

  const now = new Date();
  const document: DentalChartCustomEntry = {
    ...entry,
    createdAt: now,
    updatedAt: now,
  };

  const result = await collection.insertOne(document);
  return result.insertedId.toString();
}

// Delete all entries for a tooth
export async function deleteDentalChartEntries(
  visitId: string,
  patientId: string,
  toothNumber: number
): Promise<void> {
  const entriesCollection = await getDentalChartEntriesCollection();
  const customCollection = await getDentalChartCustomEntriesCollection();

  await Promise.all([
    entriesCollection.deleteMany({
      visitId,
      patientId,
      toothNumber,
    }),
    customCollection.deleteMany({
      visitId,
      patientId,
      toothNumber,
    }),
  ]);
}

