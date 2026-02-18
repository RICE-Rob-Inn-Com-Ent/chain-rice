/**
 * Script to find and report all files that still reference user_roles table
 * This helps identify what needs to be updated
 */

import { readFileSync, readdirSync, statSync } from "fs";
import { join } from "path";

const projectRoot = "/home/mrDinkelman/rice-mono/.project/ceramix/web";

function findFiles(dir: string, pattern: RegExp, files: string[] = []): string[] {
  const entries = readdirSync(dir, { withFileTypes: true });
  
  for (const entry of entries) {
    const fullPath = join(dir, entry.name);
    
    if (entry.isDirectory()) {
      // Skip node_modules and .next
      if (!entry.name.startsWith('.') && entry.name !== 'node_modules') {
        findFiles(fullPath, pattern, files);
      }
    } else if (entry.isFile() && (entry.name.endsWith('.ts') || entry.name.endsWith('.tsx'))) {
      try {
        const content = readFileSync(fullPath, 'utf-8');
        if (pattern.test(content)) {
          files.push(fullPath);
        }
      } catch (error) {
        // Skip files that can't be read
      }
    }
  }
  
  return files;
}

const userRolesPattern = /user_roles/i;
const files = findFiles(projectRoot, userRolesPattern);

console.log(`Found ${files.length} files that reference user_roles:\n`);
files.forEach(file => {
  console.log(`  - ${file.replace(projectRoot, '.')}`);
});

console.log("\n⚠️  These files need to be updated to use role from ID prefix instead of user_roles table.");






















































