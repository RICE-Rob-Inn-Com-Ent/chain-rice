import { useEffect, useState } from "react";

interface UserProfile {
  id: string;
  username: string;
  email: string;
  wallet_address?: string;
  game_level: number;
  mwt_balance: number;
  cats_owned: number;
  created_at: string;
  last_login?: string;
}

export function useSession() {
  const [loading, setLoading] = useState(true);
  const [authenticated, setAuthenticated] = useState(false);
  const [user, setUser] = useState<UserProfile | null>(null);

  useEffect(() => {
    const token = localStorage.getItem("access_token");
    if (!token) {
      setAuthenticated(false);
      setLoading(false);
      return;
    }
    fetch("/api/v1/auth/me", {
      headers: {
        Authorization: `Bearer ${token}`,
      },
    })
      .then(async (res) => {
        if (res.ok) {
          const data = await res.json();
          setUser(data);
          setAuthenticated(true);
        } else {
          setAuthenticated(false);
          setUser(null);
        }
      })
      .catch(() => {
        setAuthenticated(false);
        setUser(null);
      })
      .finally(() => {
        setLoading(false);
      });
  }, []);

  return { loading, authenticated, user };
}
