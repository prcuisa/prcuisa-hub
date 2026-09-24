# PRCUISA Hub MVP

Starter for app.prcuisa.com.

## Stack
- Next.js App Router + TypeScript
- Supabase Auth + PostgreSQL + RLS
- PRCUISA workspace multi-tenancy

## Setup
1. Create a Supabase project.
2. Run the SQL files in `supabase/migrations` in filename order. Existing installations only need unapplied migrations.
3. Copy `.env.example` to `.env.local` and fill the URL plus publishable key (or legacy anon key). Never use a service-role key here.
4. In Supabase Auth URL settings, add `http://localhost:3000/auth/callback` and your production callback.
5. Run:
   npm install
   npm run dev
6. Open http://localhost:3000

## MVP flow
Sign up -> verify/login -> create workspace -> dashboard.

## Production login configuration
In Vercel project settings, set these variables for Production (and Preview when testing):
- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY` or `NEXT_PUBLIC_SUPABASE_ANON_KEY`

Redeploy after changing these variables: Next.js embeds public values during the build.
In Supabase Auth URL configuration, add `https://prcuisa-hub.vercel.app/auth/callback` to the redirect allowlist.
Use the actual deployed origin for custom domains. Do not overwrite redirect URLs used by other apps sharing the project.

The Next.js proxy validates users and refreshes session cookies on protected routes.
Workspace creation uses the RLS-protected `create_workspace` RPC to create the workspace and owner membership atomically.
Database read failures show an error instead of redirecting an existing member to onboarding.

## Validation
- `npm ci` and `npm run build` check compilation and TypeScript.
- Run `supabase/tests/workspace_onboarding.sql` with an administrative SQL connection. It uses a rollback transaction and leaves no test accounts or workspaces.
- Check that anonymous visits to `/dashboard` return to login, wrong credentials show an error, and a verified account can log in, complete onboarding, reload the dashboard, and retain its session.

## Next checkpoint
- Add Revenue / Expense server actions
- Transaction history
- Date filters
- Seed categories
- Activity events
- AI only after the core loop works
