/**
 * Fix existing users - update username if it's missing or a reserved prefix
 * 
 * Usage: tsx scripts/fix-usernames.ts
 */

import { generateUsername } from "../lib/username-utils";
import { query, queryOne } from "../lib/db";

async function fixUsernames() {
  console.log("🔧 Fixing usernames for existing users...\n");

  // Get all users without username or with reserved prefix usernames
  const users = await query<{ id: string; email: string; username: string | null; display_name: string }>(
    `SELECT id, email, username, display_name FROM users WHERE active = true`
  );

  const reservedPrefixes = ['own', 'pat', 'doc', 'adm', 'me', 'sign-in', 'sign-up', 'login', 'register', 'api', 'admin', '_next'];

  for (const user of users.rows) {
    let needsUpdate = false;
    let newUsername: string | null = null;

    if (!user.username) {
      // Missing username - generate from email
      console.log(`⚠️  User ${user.email} has no username, generating...`);
      const emailPart = user.email.split('@')[0] || user.display_name || 'user';
      newUsername = await generateUsername(emailPart);
      needsUpdate = true;
    } else if (reservedPrefixes.includes(user.username.toLowerCase())) {
      // Reserved prefix username - generate new one
      console.log(`⚠️  User ${user.email} has reserved username "${user.username}", fixing...`);
      const emailPart = user.email.split('@')[0] || user.display_name || 'user';
      newUsername = await generateUsername(emailPart);
      needsUpdate = true;
    }

    if (needsUpdate && newUsername) {
      try {
        await query(
          `UPDATE users SET username = $1 WHERE id = $2`,
          [newUsername, user.id]
        );
        console.log(`✅ Updated ${user.email}: username = "${newUsername}"`);
      } catch (error) {
        console.error(`❌ Error updating ${user.email}:`, error);
      }
    } else {
      console.log(`✓  User ${user.email} has valid username: "${user.username}"`);
    }
  }

  console.log("\n✨ Username fixing completed!");
}

// Run if executed directly
if (require.main === module) {
  fixUsernames()
    .then(() => {
      console.log("\n✅ Done!");
      process.exit(0);
    })
    .catch((error) => {
      console.error("\n❌ Error:", error);
      process.exit(1);
    });
}

export { fixUsernames };










































