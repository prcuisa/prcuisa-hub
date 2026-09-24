# PRCUISA Hub MVP

Starter for app.prcuisa.com.

## Stack
- Next.js App Router + TypeScript
- Supabase Auth + PostgreSQL + RLS
- PRCUISA workspace multi-tenancy

## Setup
1. Create a Supabase project.
2. Run `supabase/migrations/001_initial_schema.sql` in Supabase SQL Editor.
3. Copy `.env.example` to `.env.local` and fill URL + anon key.
4. In Supabase Auth URL settings, add `http://localhost:3000/auth/callback` and your production callback.
5. Run:
   npm install
   npm run dev
6. Open http://localhost:3000

## MVP flow
Sign up -> verify/login -> create workspace -> dashboard.

## Next checkpoint
- Add Revenue / Expense server actions
- Transaction history
- Date filters
- Seed categories
- Activity events
- AI only after the core loop works
