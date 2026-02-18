// Global module declarations for non-TS assets used by Next.js
// Helps TypeScript with side-effect imports and asset modules

declare module "*.css";
declare module "*.png";
declare module "*.jpg";
declare module "*.jpeg";
declare module "*.svg" {
  const content: string;
  export default content;
}
