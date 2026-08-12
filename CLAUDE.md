# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
- State: `flutter_riverpod` — providers live next to their repository files (co-located, not in a separate providers/ folder)
- Navigation: `go_router` — all routes defined in `lib/app.dart`
- DB: Supabase (project `bvszmrfjfwjwhaxfueub`). All tables use RLS via `my_household_id()` SECURITY DEFINER helper
- Credentials: `.env.json` (gitignored) — passed via `--dart-define-from-file`
- Errors: use `friendlyError()` from `lib/core/utils/error_handler.dart` to convert Supabase/auth exceptions to Vietnamese user-facing strings

## Architecture

Feature-slice layout under `lib/features/`:
```
auth/        — login, register, household link/join; authStateProvider + currentProfileProvider (StreamProvider → FutureProvider chain)
transactions/ — transaction CRUD, categories; selectedMonthProvider drives transactionsProvider
budget/      — per-category monthly limits
savings/     — savings goals + contributions
reports/     — fl_chart bar/pie charts, last-6-months data
home/        — FinanceScreen (3-tab: Transactions / Budget / Savings); financeTabProvider
household/   — household management screen (name, members, invite)
profile/     — profile + settings screen
```

Each feature follows `data/` (model + repository + providers) → `domain/` (if needed) → `presentation/` (screens + widgets).

**Shell / navigation coupling:** `_AppShell` in `lib/app.dart` watches `financeTabProvider` to render the correct FAB per sub-tab. When `/home` is active and `financeTabProvider == 1` (Budget) the FAB opens `SetBudgetScreen`; when `== 2` (Savings) it opens `AddGoalScreen`. `FinanceTabNotifier` in `home_screen.dart` drives this.

**Auth flow:** `routerProvider` redirects based on `authStateProvider` (session) → `currentProfileProvider` (profile.householdId). Unauthenticated → `/login`; authenticated + no household → `/household-link`; fully set up → `/home`.

**Modal sheets:** screens presented as bottom sheets (e.g. `AddTransactionScreen.show(context)`, `AddGoalScreen.show(context)`) are full-screen sheets wrapped in `SheetWrapper` + `DraggableScrollableSheet`. Prefer this pattern over pushing a new route for forms.

**Providers:** `currentProfileProvider` is the root dependency for anything household-scoped — always guard with `if (profile?.householdId == null) return []`.

## Database (Supabase)
Tables: `households`, `profiles`, `categories`, `transactions`, `budgets`, `savings_goals`, `savings_contributions`

Migrations in `supabase/migrations/` — apply in order. The `categories` and `transactions` tables have indexes added in later migrations.

Critical function: `create_household_for_user(user_id uuid)` — SECURITY DEFINER RPC that atomically creates household + seeds categories. If broken, run the SQL from `supabase/migrations/` + the RPC separately.

## User profile bootstrapping
When a user registers AFTER the tables were created, the `handle_new_user` trigger auto-creates their profile. If they registered BEFORE tables existed, manually insert:
```sql
INSERT INTO public.profiles (id, display_name)
VALUES ('<auth.users.id>', '<name>') ON CONFLICT (id) DO NOTHING;
```

## Platform
iOS + Web only (no Android). Uses Nix flake — always run flutter via `nix develop --command flutter ...`.

## Offline
`lib/core/offline/` — list reads fall back to the last server response when the network is unreachable:
- `offline_cache.dart` — `fetchWithCache()` wraps a fetch, stores the **raw rows** in `shared_preferences` (raw, so embedded joins survive), and replays them on failure. Only transport failures fall back; anything the server answered (`PostgrestException`, auth) is rethrown so real bugs stay visible. Cleared on sign-out
- `connectivity_provider.dart` — `isOnlineProvider`. Browser online/offline events on web; on iOS the flag is driven by the data layer reporting transport failures/successes
- Repositories expose `*Rows` variants returning raw rows next to the model methods; the co-located providers call `fetchWithCache`
- `OfflineBanner` in `_AppShell` marks the session as showing saved data

Writes still require a connection — there is no queue, so an offline save surfaces the usual network error.

## PWA (web build)
The web app is installable and boots offline. Everything lives in `web/`:
- `manifest.json` — name/icons/shortcuts; `display: standalone`, scope `/`
- `sw.js` — our own service worker (Flutter's generated one is never registered). Offline app shell + web push in one file. Same-origin GETs are network-first with a cache fallback so a deploy can't leave `main.dart.js` skewed against the shell; icons are cache-first; cross-origin (Supabase) requests pass straight through. **Bump `SW_VERSION` when the caching rules change** — `activate` drops every cache that doesn't match
- `pwa_helper.js` — stashes `beforeinstallprompt` and reports standalone/iOS; read from Dart via `lib/features/pwa/`
- `flutter_bootstrap.js` — registers `/sw.js`, then removes the boot splash from `index.html` after `runApp()`
- `_headers` — Cloudflare Pages cache rules; `sw.js` / `index.html` / `flutter_bootstrap.js` must stay `no-cache`

Settings → "Cài app vào máy" opens `InstallGuideSheet`: a native install button on Chromium, written per-platform steps everywhere else (iOS Safari has no prompt API). The row hides itself once the app runs standalone.

## Nix codesign fix
`ios/nix_shims/codesign` and `ios/nix_shims/rsync` are PATH shims that fix Flutter.framework permission errors from the Nix store. Do not remove them.

## Improvement ideas (backlog)
- Push notifications when partner adds a transaction
- Monthly summary widget (total income vs expense card at top of transaction list)
- Google Sheets sync (monthly CSV export already ships on the Reports screen)
- Recurring transactions (auto-log monthly bills)
- Dark mode
- Widget for iOS home screen showing monthly balance
- Spending streak / gamification ("3 days under budget!")
- Bill splitting calculator (split expense between two people)
- Net worth tracker (assets - liabilities)
