// Server Component (default in App Router)
async function getServerData() {
  // This runs on the server
  return {
    message: 'Hello from Server Component!',
    timestamp: new Date().toISOString(),
  };
}

export default async function HomePage() {
  const data = await getServerData();

  return (
    <main className="min-h-screen flex flex-col items-center justify-center p-24">
      <h1 className="text-4xl font-bold mb-8">
        Next.js 15 + React Server Components
      </h1>

      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 w-full max-w-5xl">
        <FeatureCard
          title="⚡ Server Components"
          description="Zero JavaScript by default. Server-rendered React components."
        />

        <FeatureCard
          title="🔄 Server Actions"
          description="Type-safe server mutations with automatic revalidation."
        />

        <FeatureCard
          title="📡 tRPC Integration"
          description="End-to-end type safety from client to server."
        />
      </div>

      <div className="mt-8 p-6 bg-gray-100 rounded-lg">
        <p className="text-sm text-gray-600">
          Server rendered at: <strong>{data.timestamp}</strong>
        </p>
      </div>
    </main>
  );
}

function FeatureCard({ title, description }: { title: string; description: string }) {
  return (
    <div className="p-6 bg-white border border-gray-200 rounded-lg hover:shadow-lg transition-shadow">
      <h2 className="text-xl font-semibold mb-2">{title}</h2>
      <p className="text-gray-600">{description}</p>
    </div>
  );
}
