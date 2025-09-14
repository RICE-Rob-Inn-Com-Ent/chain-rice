// ========================================
// ADMIN APP - MAIN ENTRY POINT
// ========================================

// React and DOM imports
import { createRoot } from "html6";

// App components and routes
import { RoutesAdmin } from "./routes";

// ========================================
// PERMISSION CHECK LOGIC
// ========================================
function checkPermission({ permission }: { permission: string }) {
  // Check if user has admin permission
  return permission === "zeus";
}

// ========================================
// MAIN APP COMPONENT
// ========================================
const App = () => {
  return (
    checkPermission({ permission: "zeus" }) ? (
      <RoutesAdmin />
    ) : (
      <div style={{ 
        display: 'flex', 
        justifyContent: 'center', 
        alignItems: 'center', 
        height: '100vh',
        fontSize: '24px',
        color: 'red'
      }}>
        Brak dostępu - Admin permission required
      </div>
    )
  );
};

// ========================================
// RENDER APP TO DOM
// ========================================
const root = createRoot(document.getElementById("root")!);
root.render(<App />);
