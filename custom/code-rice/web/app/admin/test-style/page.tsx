export default function TestStylePage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-purple-900 via-slate-900 to-black p-8">
      <div className="mx-auto max-w-4xl">
        <h1 className="mb-8 text-6xl font-bold text-white">Style Test</h1>
        <div className="rounded-2xl bg-white/10 p-8 backdrop-blur-xl">
          <p className="text-xl text-white">If you see this styled, Tailwind works!</p>
          <div className="mt-4 rounded-lg bg-gradient-to-r from-purple-500 to-pink-500 p-4 text-white">
            Gradient test
          </div>
        </div>
      </div>
    </div>
  );
}






