"use client";

import { useEffect } from "react";

// Globalny error boundary dla całej aplikacji (App Router)
export default function GlobalError({ error, reset }: { error: Error & { digest?: string }; reset: () => void }) {
  useEffect(() => {
    // eslint-disable-next-line no-console
    console.error("Global app error:", error);
  }, [error]);

  return (
    <html lang="pl">
      <body className="min-h-screen bg-black text-white flex items-center justify-center p-6">
        <div className="max-w-lg w-full rounded-xl border border-red-500/30 bg-red-950/20 p-6">
          <h1 className="text-xl font-semibold text-red-400">Błąd krytyczny aplikacji</h1>
          <p className="mt-2 text-sm text-slate-300">
            Coś poszło nie tak. Spróbuj ponownie. Szczegóły błędu znajdziesz w konsoli (F12).
          </p>
          {error?.message && (
            <pre className="mt-4 max-h-40 overflow-auto whitespace-pre-wrap text-xs text-slate-400">
              {String(error.message)}{error.digest ? `\n(digest: ${error.digest})` : ""}
            </pre>
          )}
          <div className="mt-4 flex gap-2">
            <button
              className="px-4 py-2 rounded-lg bg-red-600 hover:bg-red-500 text-white text-sm"
              onClick={() => reset()}
            >
              Spróbuj ponownie
            </button>
            <button
              className="px-4 py-2 rounded-lg border border-white/20 text-sm"
              onClick={() => (window.location.href = "/")}
            >
              Wróć na stronę główną
            </button>
          </div>
        </div>
      </body>
    </html>
  );
}
