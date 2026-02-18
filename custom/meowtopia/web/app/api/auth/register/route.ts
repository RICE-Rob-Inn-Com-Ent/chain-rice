import { NextResponse } from "next/server";
import { prisma } from "@/lib/prisma";
import bcrypt from "bcryptjs";
import { syncUserToMongoDB } from "@/prisma/migrate-to-both-dbs";

export async function POST(req: Request) {
  try {
    const { name, email, password } = await req.json();

    if (!name || !email || !password) {
      return NextResponse.json({ error: "Wszystkie pola są wymagane" }, { status: 400 });
    }

    if (password.length < 8) {
      return NextResponse.json({ error: "Hasło musi mieć co najmniej 8 znaków" }, { status: 400 });
    }

    const normalizedEmail = email.toLowerCase();

    const existing = await prisma.user.findUnique({
      where: { email: normalizedEmail },
    });

    if (existing) {
      return NextResponse.json({ error: "Użytkownik z takim adresem email już istnieje" }, { status: 409 });
    }

    const [firstName, ...rest] = name.trim().split(" ");
    const lastName = rest.join(" ").trim() || null;

    const passwordHash = await bcrypt.hash(password, 12);

    const newUser = await prisma.user.create({
      data: {
        email: normalizedEmail,
        name: name.trim(),
        firstName: firstName || null,
        lastName,
        passwordHash,
        role: "USER",
      },
    });

    // Sync to MongoDB (optional, doesn't fail if MongoDB is unavailable)
    try {
      await syncUserToMongoDB(newUser.id, {
        id: newUser.id,
        email: newUser.email,
        name: newUser.name,
        firstName: newUser.firstName,
        lastName: newUser.lastName,
        role: newUser.role,
        emailVerified: newUser.emailVerified,
        image: newUser.image,
        createdAt: newUser.createdAt,
      });
    } catch (mongoError: any) {
      console.log("MongoDB sync failed (non-critical):", mongoError.message);
    }

    return NextResponse.json({ success: true });
  } catch (error) {
    console.error("[meowtopia][auth] register error", error);
    return NextResponse.json({ error: "Nie udało się utworzyć konta" }, { status: 500 });
  }
}

