# Share_adi

A Splitwise-style expense splitting app: create groups, add members, record
expenses with equal/amount/percentage/share splits, and see each member's
balance with automatic debt simplification.

## Stack

- Flutter + Riverpod + go_router
- Supabase (auth, Postgres storage, row-level security)
- All split and settlement math runs client-side in Dart

## Supabase setup

1. Create a project at https://supabase.com
2. Open SQL Editor and run `supabase/migrations/0001_init.sql`
3. In **Authentication**, enable the **Email** provider. For Google, enable the
   **Google** provider and fill in your OAuth client credentials.
4. Copy your project URL and publishable (anon) key from **Project Settings > API**.

## Run

Provide the credentials as `--dart-define` values (do not commit them):

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_KEY=your-publishable-key
```

## Status

- [x] Project scaffold + email/Google auth + profiles table with RLS
- [x] Groups & members (join codes, email invites, WhatsApp share)
- [x] Expense entry with 4 split models (equal / amounts / percentage / shares)
- [ ] Debt simplification + repayment
- [ ] Monthly/recurring expenses for house groups
- [ ] Charts, categories, notifications

## Useful commands

```sh
flutter analyze
flutter test
```