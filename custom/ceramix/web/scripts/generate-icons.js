#!/usr/bin/env node
/**
 * Generate PWA icons from favicon.svg
 * Requires: sharp package (npm install sharp)
 */

const fs = require('fs');
const path = require('path');

// For now, create placeholder icons since we don't have sharp
// In production, use sharp to convert SVG to PNG

const createPlaceholderIcon = (size) => {
  // Create a simple SVG placeholder that can be used as PNG
  // In production, replace this with actual PNG generation using sharp
  const svg = `<?xml version="1.0" encoding="UTF-8"?>
<svg width="${size}" height="${size}" viewBox="0 0 ${size} ${size}" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="g" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#f472b6"/>
      <stop offset="100%" stop-color="#f97391"/>
    </linearGradient>
  </defs>
  <rect width="${size}" height="${size}" rx="${size * 0.25}" fill="#0f172a"/>
  <path
    d="M${size * 0.28} ${size * 0.72}c-${size * 0.031} -${size * 0.156} ${size * 0.062} -${size * 0.375} ${size * 0.219} -${size * 0.438} ${size * 0.094} -${size * 0.031} ${size * 0.188} 0 ${size * 0.219} ${size * 0.094} ${size * 0.031} ${size * 0.125} -${size * 0.031} ${size * 0.188} -${size * 0.188} ${size * 0.25} ${size * 0.156} ${size * 0.062} ${size * 0.125} ${size * 0.125} ${size * 0.156} ${size * 0.125} 0 ${size * 0.062} -${size * 0.062} ${size * 0.094} -${size * 0.188} ${size * 0.094} -${size * 0.094} 0 -${size * 0.156} -${size * 0.031} -${size * 0.219} -${size * 0.125}Z"
    fill="url(#g)"
    transform="scale(${size / 32})"
  />
</svg>`;
  
  return svg;
};

const publicDir = path.join(__dirname, '..', 'public');

// Create icon-192.svg (can be converted to PNG later)
const icon192 = createPlaceholderIcon(192);
fs.writeFileSync(path.join(publicDir, 'icon-192.svg'), icon192);

// Create icon-512.svg (can be converted to PNG later)
const icon512 = createPlaceholderIcon(512);
fs.writeFileSync(path.join(publicDir, 'icon-512.svg'), icon512);

console.log('✓ Created icon-192.svg and icon-512.svg');
console.log('Note: For production, install sharp and convert these to PNG');
console.log('Run: npm install sharp && node scripts/convert-icons-to-png.js');










































