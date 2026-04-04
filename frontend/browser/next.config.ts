// TODO:
// [ ] configure Next.js output: output "standalone" for Docker via Buck2; distDir from NEXT_DIST_DIR (default .next) — https://nextjs.org/docs
// [ ] configure image domains: remotePatterns from NEXT_PUBLIC_IMAGE_DOMAINS — never hardcode — https://nextjs.org/docs/app/api-reference/config/next-config-js/images
// [ ] configure i18n: locales + defaultLocale from next-intl — https://next-intl.dev/docs
// [ ] configure webpack/proto: .proto from gen/; alias @gen → frontend/gen/ — https://connectrpc.com/docs/web/getting-started
// [ ] configure headers: CSP, HSTS, X-Frame-Options; CSP allowlist from NEXT_PUBLIC_API_URL — https://nextjs.org/docs/app/api-reference/config/next-config-js/headers
// [ ] configure redirects: /api/* → NEXT_PUBLIC_API_URL proxy for dev CORS — https://nextjs.org/docs/app/api-reference/config/next-config-js/redirects
// [ ] bundle analyzer: @next/bundle-analyzer when ANALYZE=true — https://nextjs.org/docs/app/building-your-application/optimizing/bundle-analyzer
// [ ] Sentry: withSentryConfig when NEXT_PUBLIC_SENTRY_DSN set — https://docs.sentry.io/platforms/javascript/guides/nextjs/
//
import type { NextConfig } from "next";

const nextConfig: NextConfig = {
	reactStrictMode: true,
	transpilePackages: ["@connectrpc/connect", "@connectrpc/connect-web"],
};

export default nextConfig;
