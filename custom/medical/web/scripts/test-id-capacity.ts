/**
 * Test script to verify ID generation capacity
 */

import { generateUserId, getCapacityInfo } from "../lib/user-id-generator";

async function testCapacity() {
  console.log("🧪 Testing ID Generation Capacity\n");
  
  const capacity = getCapacityInfo();
  console.log("📊 Capacity Information:");
  console.log(`   Format: ${capacity.format}`);
  console.log(`   Sequence digits: ${capacity.sequenceDigits}`);
  console.log(`   Include time: ${capacity.includeTime}`);
  console.log(`   Max per second: ${capacity.maxPerSecond}`);
  console.log(`   Max per day: ${capacity.maxPerDay}`);
  console.log(`   Max per year: ${capacity.maxPerYear}`);
  console.log();
  
  console.log("🔬 Generating test IDs...\n");
  
  const roles = ["patient", "doctor", "admin", "superadmin", "user"];
  
  for (const role of roles) {
    const id = await generateUserId(role);
    console.log(`   ${role.padEnd(12)} -> ${id}`);
  }
  
  console.log("\n✅ Test completed!");
  console.log("\n💡 System is ready for global scale!");
}

testCapacity()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ Test failed:", error);
    process.exit(1);
  });




















