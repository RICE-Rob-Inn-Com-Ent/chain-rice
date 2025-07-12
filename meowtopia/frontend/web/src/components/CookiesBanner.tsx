import React, { useEffect, useState } from "react";

const COOKIES_KEY = "cookies_accepted";

const bannerStyle: React.CSSProperties = {
  position: "fixed",
  bottom: 0,
  left: 0,
  width: "100%",
  background: "#222",
  color: "#fff",
  padding: "1rem",
  display: "flex",
  justifyContent: "center",
  alignItems: "center",
  zIndex: 1000,
  boxShadow: "0 -2px 8px rgba(0,0,0,0.2)",
};

const buttonStyle: React.CSSProperties = {
  marginLeft: "1rem",
  background: "#4f46e5",
  color: "#fff",
  border: "none",
  borderRadius: "4px",
  padding: "0.5rem 1rem",
  cursor: "pointer",
};

const CookiesBanner: React.FC = () => {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const accepted = localStorage.getItem(COOKIES_KEY);
    if (!accepted) setVisible(true);
  }, []);

  const acceptCookies = () => {
    localStorage.setItem(COOKIES_KEY, "true");
    setVisible(false);
  };

  if (!visible) return null;

  return (
    <div style={bannerStyle}>
      <span>
        This website uses cookies to ensure you get the best experience. See our {" "}
        <a href="/docs/policies/cookies-consent.md" style={{ color: "#a5b4fc", textDecoration: "underline" }} target="_blank" rel="noopener noreferrer">Cookies Policy</a>.
      </span>
      <button style={buttonStyle} onClick={acceptCookies}>
        Accept
      </button>
    </div>
  );
};

export default CookiesBanner; 