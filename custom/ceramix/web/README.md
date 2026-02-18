# Ceramix Web Application

Modern web application for Ceramix & Esteticdent dental clinics management system.

## Features

- 🏠 Modern homepage with clinic information
- 🔐 Authentication system (login/register) with OAuth support
- 👥 Patient management
- 🦷 Dentist management with schedules
- 📅 Appointment scheduling
- 💰 Accounting and invoicing system
- 📊 Admin dashboard

## Tech Stack

- **Framework**: Next.js 14 (App Router)
- **Database**: PostgreSQL
- **Styling**: Tailwind CSS
- **Authentication**: Session-based with OAuth support
- **Language**: TypeScript

## Setup

### Prerequisites

- Node.js 18+ 
- PostgreSQL 12+
- Yarn package manager

### Installation

1. Install dependencies:
```bash
bun install
```

2. Set up environment variables:
```bash
# Database
CERAMIX_DB_HOST=localhost
CERAMIX_DB_PORT=5432
CERAMIX_DB_USER=rice
CERAMIX_DB_PASSWORD=rice
CERAMIX_DB_NAME=ceramix_db
CERAMIX_DB_SSL=false

# Application
NEXT_PUBLIC_BASE_URL=http://ceramix.ltd
NODE_ENV=development

# OAuth (optional)
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
FACEBOOK_CLIENT_ID=your_facebook_client_id
FACEBOOK_CLIENT_SECRET=your_facebook_client_secret
```

3. Initialize the database:
```bash
# Create the database first
createdb ceramix_db

# Run the schema
psql ceramix_db < lib/db/schema.sql

# Or use the TypeScript initialization script
yarn ts-node lib/db/init.ts
```

4. Run the development server:
```bash
yarn dev
```

The application will be available at `http://localhost:3003`

## Database Schema

The database includes tables for:
- Users and authentication
- Patients (clients)
- Dentists
- Dentist schedules
- Appointments
- Treatments
- Invoices and payments
- OAuth accounts

See `lib/db/schema.sql` for the complete schema.

## Project Structure

```
app/
  ├── admin/          # Admin panel pages
  ├── api/            # API routes
  ├── zaloguj/        # Login page
  ├── zarejestruj/    # Register page
  └── page.tsx        # Homepage

lib/
  ├── auth.ts         # Authentication utilities
  ├── db.ts           # Database connection
  └── db/
      ├── schema.sql  # Database schema
      └── init.ts     # Database initialization
```

## Admin Panel

Access the admin panel at `/admin` after logging in. Features include:

- **Dashboard**: Overview statistics
- **Pacjenci**: Patient management
- **Dentyści**: Dentist management and schedules
- **Wizyty**: Appointment scheduling
- **Księgowość**: Invoicing and accounting

## OAuth Setup

To enable OAuth authentication:

1. Create OAuth applications with Google/Facebook
2. Add the credentials to environment variables
3. Update the callback URLs in your OAuth provider settings:
   - Google: `http://ceramix.ltd/api/auth/oauth/google/callback`
   - Facebook: `http://ceramix.ltd/api/auth/oauth/facebook/callback`

## Production Deployment

1. Build the application:
```bash
yarn build
```

2. Start the production server:
```bash
yarn start
```

3. Configure your reverse proxy (e.g., Traefik) to route `ceramix.ltd` to the application.

## License

Copyright © 2024 Esteticdent & Ceramix

