#!/usr/bin/env node

/**
 * Skrypt do tworzenia przykładowych użytkowników z prawidłowymi hashami haseł
 * Używa bcrypt do hashowania haseł
 */

// Use bcryptjs which is already in dependencies
const bcrypt = require('bcryptjs');
const { randomUUID } = require('crypto');
const { Pool } = require('pg');

const pool = new Pool({
  connectionString: process.env.DATABASE_URL || 'postgresql://rice_user:rice_password@localhost:5432/ceramix?sslmode=disable',
});

const TEST_PASSWORD = 'Test1234!';

async function hashPassword(password) {
  return bcrypt.hash(password, 12);
}

async function createUsers() {
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');
    
    const passwordHash = await hashPassword(TEST_PASSWORD);
    
    const coreUsers = [
      {
        id: '00000000-0000-0000-0000-000000000001',
        email: 'superadmin@ceramix.pl',
        passwordHash,
        displayName: 'Super Administrator',
        firstName: 'Jan',
        lastName: 'Kowalski',
        phone: '+48 600 000 001',
        role: 'superadmin'
      },
      {
        id: '00000000-0000-0000-0000-000000000002',
        email: 'admin@ceramix.pl',
        passwordHash,
        displayName: 'Administrator',
        firstName: 'Anna',
        lastName: 'Nowak',
        phone: '+48 600 000 002',
        role: 'admin'
      }
    ];

    const dentists = [
      {
        email: 'dr.piotr@ceramix.pl',
        displayName: 'Dr Piotr Wiśniewski',
        firstName: 'Piotr',
        lastName: 'Wiśniewski',
        phone: '+48 601 111 001'
      },
      {
        email: 'dr.magda@ceramix.pl',
        displayName: 'Dr Magdalena Zielińska',
        firstName: 'Magdalena',
        lastName: 'Zielińska',
        phone: '+48 601 111 002'
      },
      {
        email: 'dr.kamil@ceramix.pl',
        displayName: 'Dr Kamil Jankowski',
        firstName: 'Kamil',
        lastName: 'Jankowski',
        phone: '+48 601 111 003'
      }
    ].map((doc, idx) => ({
      id: randomUUID(),
      passwordHash,
      role: 'dentist',
      license: `TEST-LIC-${(idx + 1).toString().padStart(2, '0')}`,
      ...doc,
    }));

    const samplePatients = [
      ['user01@ceramix.pl', 'Alicja', 'Kamińska'],
      ['user02@ceramix.pl', 'Bartek', 'Lewandowski'],
      ['user03@ceramix.pl', 'Celina', 'Mazur'],
      ['user04@ceramix.pl', 'Daniel', 'Piotrowski'],
      ['user05@ceramix.pl', 'Ewa', 'Lis'],
      ['user06@ceramix.pl', 'Filip', 'Grabowski'],
      ['user07@ceramix.pl', 'Gosia', 'Król'],
      ['user08@ceramix.pl', 'Hubert', 'Sikora'],
      ['user09@ceramix.pl', 'Iga', 'Kucharska'],
      ['user10@ceramix.pl', 'Jakub', 'Włodarczyk'],
    ].map(([email, firstName, lastName], idx) => ({
      id: randomUUID(),
      email,
      passwordHash,
      displayName: `${firstName} ${lastName}`,
      firstName,
      lastName,
      phone: `+48 602 22${(idx + 1).toString().padStart(3, '0')}`,
      patientNote: `Pacjent testowy #${idx + 1}`,
      role: 'user',
    }));

    const users = [
      ...coreUsers,
      ...dentists,
      ...samplePatients,
    ];
    
    for (const user of users) {
      // Insert or update user
      await client.query(`
        INSERT INTO users (
          id, email, password_hash, display_name, first_name, last_name, phone,
          active, email_verified, account_state, created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, true, true, 'ACTIVE', CURRENT_TIMESTAMP)
        ON CONFLICT (email) DO UPDATE SET
          password_hash = EXCLUDED.password_hash,
          display_name = EXCLUDED.display_name,
          first_name = EXCLUDED.first_name,
          last_name = EXCLUDED.last_name,
          phone = EXCLUDED.phone,
          active = true
      `, [user.id, user.email, user.passwordHash, user.displayName, user.firstName, user.lastName, user.phone || null]);
      
      // Insert role
      await client.query(`
        INSERT INTO user_roles (user_id, role, granted_at)
        VALUES ($1, $2, CURRENT_TIMESTAMP)
        ON CONFLICT (user_id, role) DO NOTHING
      `, [user.id, user.role]);
      
      console.log(`✅ Utworzono użytkownika: ${user.email} (${user.role})`);
    }

    // Ensure profiles exist in dentists table
    for (const dentist of dentists) {
      await client.query(`
        INSERT INTO dentists (
          id,
          license_number,
          user_id,
          first_name,
          last_name,
          email,
          phone,
          specialization,
          clinic_location,
          bio,
          active
        )
        VALUES ($1, $2, $3, $4, $5, $6, $7, ARRAY['stomatologia zachowawcza'], 'ceramix', 'Dentysta testowy', true)
        ON CONFLICT (id) DO UPDATE SET
          license_number = EXCLUDED.license_number,
          user_id = EXCLUDED.user_id,
          first_name = EXCLUDED.first_name,
          last_name = EXCLUDED.last_name,
          email = EXCLUDED.email,
          phone = EXCLUDED.phone,
          specialization = EXCLUDED.specialization,
          clinic_location = EXCLUDED.clinic_location,
          bio = EXCLUDED.bio,
          active = true
      `, [
        dentist.id,
        dentist.license,
        dentist.id,
        dentist.firstName,
        dentist.lastName,
        dentist.email,
        dentist.phone || null,
      ]);
    }
    
    await client.query('COMMIT');
    
    // Show created users
    const result = await client.query(`
      SELECT 
        u.email,
        u.display_name,
        u.first_name,
        u.last_name,
        ur.role,
        u.active,
        u.email_verified
      FROM users u
      LEFT JOIN user_roles ur ON u.id = ur.user_id
      WHERE u.email IN (
        'superadmin@ceramix.pl',
        'admin@ceramix.pl',
        'dr.piotr@ceramix.pl',
        'dr.magda@ceramix.pl',
        'dr.kamil@ceramix.pl'
      )
      OR u.email LIKE 'user0%@ceramix.pl'
      ORDER BY ur.role, u.email
    `);
    
    console.log('\n📋 Utworzeni użytkownicy:');
    console.table(result.rows);
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Błąd:', error.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

createUsers();

