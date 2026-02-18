/**
 * Update existing users to have usernames
 * Generates username from email prefix + role prefix
 */

import { prisma } from "../lib/prisma";

async function updateUsernames() {
  console.log("🔄 Updating usernames for existing users...\n");

  // Get all users (we'll check for null username in the loop)
  const users = await prisma.user.findMany();

  for (const user of users) {
    try {
      // Skip if username already exists
      if (user.username) {
        console.log(`⏭️  User ${user.email} already has username: ${user.username}`);
        continue;
      }
      
      // Extract email prefix (before @)
      const emailPrefix = user.email.split("@")[0];
      
      // Get role prefix
      let rolePrefix = "user";
      if (user.role === "ADMIN" || user.role === "SUPERADMIN") rolePrefix = "adm";
      else if (user.role === "MANAGER") rolePrefix = "mgr";
      else if (user.role === "VOLUNTEER") rolePrefix = "vol";
      else if (user.role === "OWNER") rolePrefix = "own";
      else if (user.role === "CUSTOMER" || user.role === "USER") rolePrefix = "user"; // Legacy support
      
      // Generate username
      const username = `${rolePrefix}_${emailPrefix}`;
      
      // Update user
      await prisma.user.update({
        where: { id: user.id },
        data: { username },
      });
      
      console.log(`✅ Updated ${user.email} -> username: ${username}`);
    } catch (error: any) {
      console.error(`❌ Error updating ${user.email}:`, error.message);
    }
  }

  console.log("\n✨ Username update completed!");
}

updateUsernames()
  .then(() => {
    console.log("\n✅ Done!");
    process.exit(0);
  })
  .catch((error) => {
    console.error("\n❌ Error:", error);
    process.exit(1);
  });

