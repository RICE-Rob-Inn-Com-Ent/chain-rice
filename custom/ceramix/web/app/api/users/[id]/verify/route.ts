import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";
import { query, queryOne } from "@/lib/db";
import { isOwner } from "@/lib/rbac";
import crypto from "crypto";

// Ensure verification_codes table exists
async function ensureVerificationCodesTable() {
  await query(`
    CREATE TABLE IF NOT EXISTS verification_codes (
      id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
      user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      code VARCHAR(10) NOT NULL,
      type VARCHAR(20) NOT NULL CHECK (type IN ('email', 'sms')),
      expires_at TIMESTAMP NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(user_id, type)
    );
    CREATE INDEX IF NOT EXISTS idx_verification_codes_user_id ON verification_codes(user_id);
    CREATE INDEX IF NOT EXISTS idx_verification_codes_expires_at ON verification_codes(expires_at);
  `);
}

// POST - Wyślij kod weryfikacyjny (email lub SMS)
export async function POST(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const currentUser = await getCurrentUser();
    if (!currentUser || !isOwner(currentUser.id)) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    await ensureVerificationCodesTable();

    const body = await request.json();
    const { type } = body; // 'email' or 'sms'

    if (type !== "email" && type !== "sms") {
      return NextResponse.json({ error: "Invalid verification type" }, { status: 400 });
    }

    const user = await queryOne<{ email: string; phone: string | null }>(
      `SELECT email, get_user_phone(id) as phone FROM users WHERE id = $1`,
      [params.id]
    );

    if (!user) {
      return NextResponse.json({ error: "User not found" }, { status: 404 });
    }

    // Generate 6-digit verification code
    const verificationCode = crypto.randomInt(100000, 999999).toString();

    // Store verification code with expiration (10 minutes)
    const expiresAt = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    if (type === "email") {
      if (!user.email) {
        return NextResponse.json({ error: "User has no email address" }, { status: 400 });
      }

      // Store code in database
      await query(
        `INSERT INTO verification_codes (user_id, code, type, expires_at, created_at)
         VALUES ($1, $2, 'email', $3, CURRENT_TIMESTAMP)
         ON CONFLICT (user_id, type) DO UPDATE SET
           code = EXCLUDED.code,
           expires_at = EXCLUDED.expires_at,
           created_at = CURRENT_TIMESTAMP`,
        [params.id, verificationCode, expiresAt]
      );

      // TODO: Send email with verification code
      // For now, just log it (in production, use your email service)
      console.log(`📧 Email verification code for ${user.email}: ${verificationCode}`);

      return NextResponse.json({
        success: true,
        message: "Kod weryfikacyjny został wysłany na email",
        code: process.env.NODE_ENV === "development" ? verificationCode : undefined, // Only in dev
      });
    } else {
      // SMS
      if (!user.phone) {
        return NextResponse.json({ error: "User has no phone number" }, { status: 400 });
      }

      // Store code in database
      await query(
        `INSERT INTO verification_codes (user_id, code, type, expires_at, created_at)
         VALUES ($1, $2, 'sms', $3, CURRENT_TIMESTAMP)
         ON CONFLICT (user_id, type) DO UPDATE SET
           code = EXCLUDED.code,
           expires_at = EXCLUDED.expires_at,
           created_at = CURRENT_TIMESTAMP`,
        [params.id, verificationCode, expiresAt]
      );

      // TODO: Send SMS with verification code
      // For now, just log it (in production, use your SMS service like Twilio)
      console.log(`📱 SMS verification code for ${user.phone}: ${verificationCode}`);

      return NextResponse.json({
        success: true,
        message: "Kod weryfikacyjny został wysłany na numer telefonu",
        code: process.env.NODE_ENV === "development" ? verificationCode : undefined, // Only in dev
      });
    }
  } catch (error: any) {
    console.error("Send verification code error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// PUT - Zweryfikuj kod
export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const currentUser = await getCurrentUser();
    if (!currentUser || !isOwner(currentUser.id)) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    await ensureVerificationCodesTable();

    const body = await request.json();
    const { type, code } = body; // 'email' or 'sms', and verification code

    if (type !== "email" && type !== "sms") {
      return NextResponse.json({ error: "Invalid verification type" }, { status: 400 });
    }

    if (!code) {
      return NextResponse.json({ error: "Verification code is required" }, { status: 400 });
    }

    // Verify code
    const verification = await queryOne<{ expires_at: Date }>(
      `SELECT expires_at FROM verification_codes 
       WHERE user_id = $1 AND type = $2 AND code = $3 AND expires_at > CURRENT_TIMESTAMP`,
      [params.id, type, code]
    );

    if (!verification) {
      return NextResponse.json(
        { error: "Nieprawidłowy lub wygasły kod weryfikacyjny" },
        { status: 400 }
      );
    }

    // Mark as verified
    if (type === "email") {
      await query(`UPDATE users SET email_verified = true WHERE id = $1`, [params.id]);
    } else {
      // Safely update phone_verified - column might not exist
      try {
        await query(`UPDATE users SET phone_verified = true WHERE id = $1`, [params.id]);
      } catch (updateError: any) {
        // If column doesn't exist, that's ok - we'll handle it gracefully
        if (!updateError.message.includes("phone_verified")) {
          throw updateError;
        }
        console.warn("⚠️ phone_verified column does not exist, skipping update");
      }
    }

    // Delete used code
    await query(`DELETE FROM verification_codes WHERE user_id = $1 AND type = $2`, [
      params.id,
      type,
    ]);

    return NextResponse.json({
      success: true,
      message: type === "email" ? "Email został zweryfikowany" : "Numer telefonu został zweryfikowany",
    });
  } catch (error: any) {
    console.error("Verify code error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

