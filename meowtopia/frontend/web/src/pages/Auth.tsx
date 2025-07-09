import React, { useState } from "react";
import { Login } from "@/layouts/modules/Login";
import { Register } from "@/layouts/modules/Register";

const Auth: React.FC = () => {
  const [showRegister, setShowRegister] = useState(false);

  return showRegister ? (
    <Register onSwitchToLogin={() => setShowRegister(false)} />
  ) : (
    <Login onSwitchToRegister={() => setShowRegister(true)} />
  );
};

export default Auth;
