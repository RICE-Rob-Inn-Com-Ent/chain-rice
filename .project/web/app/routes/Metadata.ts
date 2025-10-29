import type { MetadataRoute } from "next";

/**
 * PWA Manifest Configuration
 * Defines app manifest for progressive web app functionality
 */
export function generateManifest(): MetadataRoute.Manifest {
  return {
    name: "RICE — Nowoczesna firma technologiczna",
    short_name: "RICE",
    description: "Minimalistyczna, czarno-biała wizytówka IT z SEO/SSR i szybkim UX.",
    start_url: "/",
    display: "standalone",
    background_color: "#000000",
    theme_color: "#0b0f1a",
    icons: [
      {
        src: "/apple-touch-icon.png",
        sizes: "180x180",
        type: "image/png",
  purpose: "maskable",
      },
      {
        src: "/img/agent.png",
        type: "image/png",
      },
    ],
  };
}

/**
 * Robots.txt Configuration
 * Defines crawling rules for search engine bots
 */
export function generateRobots(): MetadataRoute.Robots {
  const site = process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000";
  return {
    rules: {
      userAgent: "*",
      allow: "/",
      disallow: ["/api"],
    },
    sitemap: `${site}/sitemap.xml`,
  };
}

/**
 * Sitemap Configuration
 * Generates XML sitemap for search engines
 */
export function generateSitemap(): MetadataRoute.Sitemap {
  const site = process.env.NEXT_PUBLIC_SITE_URL || "http://localhost:3000";
  const now = new Date();

  const staticRoutes = ["", "/about", "/contact", "/services", "/team", "/pricing"];

  return staticRoutes.map((path) => ({
    url: `${site}${path}`,
    lastModified: now,
    changeFrequency: "weekly" as const,
    priority: path === "" ? 1 : 0.7,
  }));
}
