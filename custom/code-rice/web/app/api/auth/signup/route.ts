import { NextRequest, NextResponse } from "next/server";
import { query, queryOne } from "@/lib/db";
import { generateUserId } from "@/lib/user-id-generator";
import { hashPassword } from "@/lib/auth";

export async function POST(request: NextRequest) {
  try {
    const { name, email, password } = await request.json();

    if (!name || !email || !password) {
      return NextResponse.json({ error: "Wszystkie pola są wymagane" }, { status: 400 });
    }

    if (password.length < 8) {
      return NextResponse.json({ error: "Hasło musi mieć co najmniej 8 znaków" }, { status: 400 });
    }

    const existing = await queryOne<{ id: string }>(
      `SELECT id FROM users WHERE LOWER(email) = $1`,
      [email.toLowerCase()],
    );

    if (existing) {
      return NextResponse.json({ error: "Użytkownik o takim emailu już istnieje" }, { status: 409 });
    }

    const userId = await generateUserId("user");
    const passwordHash = await hashPassword(password);
    const [firstName, ...rest] = name.trim().split(" ");
    const lastName = rest.join(" ");

    await query(
      `INSERT INTO users (id, email, password_hash, display_name, first_name, last_name, active, email_verified, account_state)
       VALUES ($1, $2, $3, $4, $5, $6, true, true, 'ACTIVE')`,
      [userId, email.toLowerCase(), passwordHash, name.trim(), firstName || null, lastName || null],
    );

    await query(
      `INSERT INTO user_roles (user_id, role) VALUES ($1, $2)
       ON CONFLICT (user_id, role) DO NOTHING`,
      [userId, "user"],
    );

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error("[code-rice][auth] signup error", error);
    return NextResponse.json({ error: "Nie udało się utworzyć konta" }, { status: 500 });
  }
}


