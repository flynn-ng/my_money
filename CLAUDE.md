# My Moneyyy!!! — Claude Code Guide

## Run the app
```
nix develop --command flutter run -d <device-id> --dart-define-from-file=.env.json
```

## Analyze / check errors
```
nix develop --command flutter analyze --no-pub
```

## Key conventions
- All UI strings go through `lib/core/l10n/app_strings.dart` (class `S`) — Vietnamese only, no hardcoded strings in widgets
- Colors: `AppColors` (`lib/core/constants/app_colors.dart`)
- Text styles: `AppTextStyles` (`lib/core/constants/app_text_styles.dart`)
- State: `flutter_riverpod` — providers live next to their repository files
- Navigation: `go_router` — all routes defined in `lib/app.dart`
- DB: Supabase (project `bvszmrfjfwjwhaxfueub`). All tables use RLS via `my_household_id()` SECURITY DEFINER helper
- Credentials: `.env.json` (gitignored) — passed via `--dart-define-from-file`

## Database (Supabase)
Tables: `households`, `profiles`, `categories`, `transactions`, `budgets`, `savings_goals`, `savings_contributions`

Critical function: `create_household_for_user(user_id uuid)` — SECURITY DEFINER RPC that atomically creates household + seeds categories. If broken, run the SQL from `supabase/migrations/` + the RPC separately.

## User profile bootstrapping
When a user registers AFTER the tables were created, the `handle_new_user` trigger auto-creates their profile. If they registered BEFORE tables existed, manually insert:
```sql
INSERT INTO public.profiles (id, display_name)
VALUES ('<auth.users.id>', '<name>') ON CONFLICT (id) DO NOTHING;
```

## Platform
iOS + Web only (no Android). Uses Nix flake — always run flutter via `nix develop --command flutter ...`.

## Nix codesign fix
`ios/nix_shims/codesign` and `ios/nix_shims/rsync` are PATH shims that fix Flutter.framework permission errors from the Nix store. Do not remove them.

## Improvement ideas (backlog)
- Push notifications when partner adds a transaction
- Monthly summary widget (total income vs expense card at top of transaction list)
- Export to CSV / Google Sheets
- Recurring transactions (auto-log monthly bills)
- Dark mode
- Widget for iOS home screen showing monthly balance
- Spending streak / gamification ("3 days under budget!")
- Bill splitting calculator (split expense between two people)
- Net worth tracker (assets - liabilities)
