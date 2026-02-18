import { NextRequest, NextResponse } from "next/server";
import { cookies } from "next/headers";
import { query, queryOne } from "@/lib/db";
import { hashPassword, createSession, getSessionCookieMaxAge, generateCSRFToken } from "@/lib/auth";
import { upsertPatientProfile } from "@/lib/patient-profiles";
import { generateUserId } from "@/lib/user-id-generator";
import { generateUsername } from "@/lib/username-utils";
import { setRoleSessionCookie, setCSRFToken } from "@/lib/cookie-utils";

export async function POST(request: NextRequest) {
  try {
    const {
      email,
      password,
      displayName,
      firstName,
      lastName,
      phone,
      patientProfile,
    } = await request.json();

    if (!email || !password || !displayName) {
      return NextResponse.json(
        { error: "Email, hasło i nazwa wyświetlana są wymagane" },
        { status: 400 }
      );
    }
    
    if (
      !patientProfile ||
      !patientProfile.pesel ||
      !patientProfile.dateOfBirth ||
      !patientProfile.gender ||
      !patientProfile.nfzBranch ||
      !patientProfile.insuranceConfirmationStatus
    ) {
      return NextResponse.json(
        { error: "Uzupełnij dane pacjenta (PESEL, data urodzenia, płeć, NFZ, status potwierdzenia)." },
        { status: 400 }
      );
    }

    // Validate email format
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return NextResponse.json({ error: "Nieprawidłowy format email" }, { status: 400 });
    }

    // Validate password strength
    if (password.length < 8) {
      return NextResponse.json(
        { error: "Hasło musi mieć co najmniej 8 znaków" },
        { status: 400 }
      );
    }

    // Check if user already exists
    const existingUser = await queryOne<{ id: string }>(
      `SELECT id FROM users WHERE email = $1`,
      [email.toLowerCase()]
    );

    if (existingUser) {
      return NextResponse.json(
        { error: "Użytkownik z tym emailem już istnieje" },
        { status: 409 }
      );
    }

    // Hash password
    const passwordHash = await hashPassword(password);

    // Generate role-based user ID (patient role for signup)
    const userId = await generateUserId("patient");
    
    // Generate username from email (part before @) or display name
    const username = await generateUsername(email.split('@')[0] || displayName);

    // Create user
    const result = await queryOne<{ id: string }>(
      `INSERT INTO users (id, username, email, password_hash, display_name, first_name, last_name, phone, active, email_verified, account_state)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, true, false, 'ACTIVE')
       RETURNING id`,
      [userId, username, email.toLowerCase(), passwordHash, displayName, firstName || null, lastName || null, phone || null]
    );

    if (!result) {
      return NextResponse.json(
        { error: "Nie udało się utworzyć konta" },
        { status: 500 }
      );
    }

    // Role is now in ID prefix - no need to insert into user_roles

    await upsertPatientProfile(result.id, {
      pesel: patientProfile.pesel,
      dateOfBirth: patientProfile.dateOfBirth,
      gender: patientProfile.gender,
      peselStatus: patientProfile.peselStatus,
      childNumber: patientProfile.childNumber,
      nfzBranch: patientProfile.nfzBranch,
      insuranceEntitlement: patientProfile.insuranceEntitlement,
      insuranceConfirmationStatus: patientProfile.insuranceConfirmationStatus,
      additionalEntitlements: patientProfile.additionalEntitlements,
      ekuNumber: patientProfile.ekuNumber,
      euPatientNumber: patientProfile.euPatientNumber,
      maidenName: patientProfile.maidenName,
      fatherName: patientProfile.fatherName,
      motherName: patientProfile.motherName,
      authorizedPerson: patientProfile.authorizedPerson,
      documentsInfo: patientProfile.documentsInfo,
      consentAccepted: patientProfile.consentAccepted,
    });

    // Create session
    const sessionToken = await createSession(result.id);

    // Update last login
    await query(
      `UPDATE users SET last_login_at = CURRENT_TIMESTAMP WHERE id = $1`,
      [result.id]
    );

    // Redirect based on username (not role prefix)
    const { getRoleFromId } = await import("@/lib/user-id-generator");
    const role = getRoleFromId(result.id) || "user";
    
    // Set role-based session cookie
    await setRoleSessionCookie(role, sessionToken, getSessionCookieMaxAge());
    const csrfToken = generateCSRFToken();
    await setCSRFToken(csrfToken);
    
    // Get username from created user
    const createdUser = await queryOne<{ username: string }>(
      `SELECT username FROM users WHERE id = $1`,
      [result.id]
    );
    
    // Use username for routing (e.g., /username/dashboard)
    const redirect = createdUser ? `/${createdUser.username}/dashboard` : '/me';
    
    // After signup, always redirect to panel subdomain (standardized)
    const panelDomain = process.env.PROJECT_PANEL_DOMAIN || 'panel.ceramix.ltd';
    
    return NextResponse.json({
      success: true,
      redirect,
      usePanelDomain: true,
      panelDomain,
      message: "Konto zostało utworzone pomyślnie",
    });
  } catch (error: any) {
    console.error("Signup error:", error);
    
    // Provide more detailed error messages
    let errorMessage = "Wystąpił błąd podczas rejestracji";
    
    if (error?.code === "ECONNREFUSED") {
      errorMessage = "Nie można połączyć się z bazą danych. Sprawdź czy PostgreSQL jest uruchomiony.";
    } else if (error?.code === "42P01") {
      errorMessage = "Tabela nie istnieje. Uruchom migracje bazy danych.";
    } else if (error?.code === "23505") {
      errorMessage = "Użytkownik z tym emailem już istnieje";
    } else if (error?.message) {
      errorMessage = `Błąd: ${error.message}`;
    }
    
    return NextResponse.json(
      { error: errorMessage, details: process.env.NODE_ENV === "development" ? error?.message : undefined },
      { status: 500 }
    );
  }
}

