"use client";

import { SessionProvider } from "next-auth/react";

export function Providers({ children }: { children: React.ReactNode }) {
  return (
    <SessionProvider
      refetchInterval={0} // Don't auto-refetch - let user control
      refetchOnWindowFocus={true}
      basePath="/api/auth"
      // Don't set baseUrl - let NextAuth detect it automatically with trustHost
    >
      {children}
    </SessionProvider>
  );
}
