#!/usr/bin/env node

// Mock AI Models Health Check Server
// Uruchom to podczas gdy prawdziwe modele budują się w Docker

const http = require("http");

const models = [
  { id: "thoth", port: 8001, name: "Thoth", icon: "📚" },
  { id: "ra", port: 8002, name: "Ra", icon: "☀️" },
  { id: "isis", port: 8003, name: "Isis", icon: "✨" },
  { id: "bastet", port: 8004, name: "Bastet", icon: "🐱" },
  { id: "maat", port: 8005, name: "Maat", icon: "⚖️" },
  { id: "khnum", port: 8006, name: "Khnum", icon: "💰" },
];

const servers = [];

models.forEach((model) => {
  const server = http.createServer((req, res) => {
    // CORS headers
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
    res.setHeader("Access-Control-Allow-Headers", "Content-Type");

    if (req.method === "OPTIONS") {
      res.writeHead(200);
      res.end();
      return;
    }

    if (req.url === "/health") {
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(
        JSON.stringify({
          status: "healthy",
          model: model.name,
          id: model.id,
          icon: model.icon,
          mode: "mock",
          timestamp: new Date().toISOString(),
        })
      );
    } else {
      res.writeHead(404);
      res.end("Not Found");
    }
  });

  server.listen(model.port, "127.0.0.1", () => {
    console.log(`${model.icon} ${model.name} mock server listening on http://localhost:${model.port}`);
  });

  servers.push(server);
});

console.log("\n✅ All mock AI models are running!");
console.log("🌐 Open http://localhost:3001 to see the status\n");
console.log("💡 These are mock servers for testing");
console.log("💡 Real models are building in Docker (15-20 mins)");
console.log("💡 Press Ctrl+C to stop\n");

// Graceful shutdown
process.on("SIGINT", () => {
  console.log("\n\n🛑 Stopping all mock servers...");
  servers.forEach((server) => server.close());
  process.exit(0);
});
