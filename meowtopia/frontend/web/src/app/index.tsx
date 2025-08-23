// App exports
export { default as UserApp } from "./main/UserApp";
export { default as AdminApp } from "./main/AdminApp";

// Main App component that can be customized
import React from "react";
import UserApp from "./main/UserApp";
import AdminApp from "./main/AdminApp";
import { APP_CONFIG } from "./appConfig";

const App: React.FC = () => {
  switch (APP_CONFIG.currentApp) {
    case "admin":
      return <AdminApp />;
    case "user":
    default:
      return <UserApp />;
  }
};

export default App;
