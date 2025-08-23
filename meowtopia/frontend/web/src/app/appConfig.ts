// App Configuration
// Change this value to switch between different apps
export const APP_CONFIG = {
  currentApp: "user" as "user" | "admin" | "example",
  // Add more configuration options here
  theme: "light" as "light" | "dark",
  language: "en" as "en" | "es" | "fr",
};

// Available apps
export const AVAILABLE_APPS = {
  user: "User Application",
  admin: "Admin Application",
  example: "Example Application",
} as const;

// App metadata
export const APP_METADATA = {
  user: {
    title: "User App",
    description: "Main user application",
    version: "1.0.0",
  },
  admin: {
    title: "Admin App",
    description: "Administrative application",
    version: "1.0.0",
  },
  example: {
    title: "Example App",
    description: "Example application for demonstration",
    version: "1.0.0",
  },
} as const;
