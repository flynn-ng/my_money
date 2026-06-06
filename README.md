# My Moneyyy! 💰

Personal finance app for two — track shared expenses, budgets, and savings goals together.

Built with Flutter (iOS + Web) and Supabase.

## Features
- Shared household expense tracking
- Category budgets with progress tracking
- Savings goals with contribution history
- Real-time sync between partners
- Vietnamese UI

## Setup

### Prerequisites
- [Nix](https://nixos.org/download) with flakes enabled
- A [Supabase](https://supabase.com) project

### 1. Clone & configure
```bash
git clone <your-repo-url>
cd money-manage
cp .env.example.json .env.json
```

Edit `.env.json` with your Supabase project credentials:
```json
{
  "SUPABASE_URL": "https://YOUR_PROJECT_ID.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key"
}
```

### 2. Apply database migrations
```bash
# Install Supabase CLI, then:
supabase db push --project-ref YOUR_PROJECT_ID
```

### 3. Run the app
```bash
# List available devices
nix develop --command flutter devices

# Run on a device
nix develop --command flutter run -d <device-id> --dart-define-from-file=.env.json
```

## Database
Migrations live in `supabase/migrations/`. To create a new migration:
```bash
supabase migration new <name>
```
Merging to `main` auto-applies pending migrations via GitHub Actions.

## Tech stack
- Flutter + Riverpod + go_router
- Supabase (Postgres + Auth + Realtime + RLS)
- Nix flake for reproducible builds
