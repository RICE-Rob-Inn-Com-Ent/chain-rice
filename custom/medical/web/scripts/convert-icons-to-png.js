#!/usr/bin/env node
/**
 * Convert SVG icons to PNG using sharp
 * Run: npm install sharp && node scripts/convert-icons-to-png.js
 */

try {
  const sharp = require('sharp');
  const fs = require('fs');
  const path = require('path');

  const publicDir = path.join(__dirname, '..', 'public');
  const faviconPath = path.join(publicDir, 'favicon.svg');

  if (!fs.existsSync(faviconPath)) {
    console.error('Error: favicon.svg not found');
    process.exit(1);
  }

  // Read SVG
  const svg = fs.readFileSync(faviconPath);

  // Generate 192x192 icon
  sharp(svg)
    .resize(192, 192)
    .png()
    .toFile(path.join(publicDir, 'icon-192.png'))
    .then(() => {
      console.log('✓ Created icon-192.png');
      
      // Generate 512x512 icon
      return sharp(svg)
        .resize(512, 512)
        .png()
        .toFile(path.join(publicDir, 'icon-512.png'));
    })
    .then(() => {
      console.log('✓ Created icon-512.png');
      console.log('✓ Icons generated successfully!');
    })
    .catch((error) => {
      console.error('Error generating icons:', error);
      process.exit(1);
    });
} catch (error) {
  if (error.code === 'MODULE_NOT_FOUND') {
    console.error('Error: sharp package not found');
    console.error('Install it with: npm install sharp');
    process.exit(1);
  }
  throw error;
}








