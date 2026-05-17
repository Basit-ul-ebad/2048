# Database seed (Auth + Firestore)

Creates **real Firebase Auth users** and matching Firestore documents for local testing.

## One-time setup

1. Open [Firebase Console](https://console.firebase.google.com) → your **2048** project.
2. **Project settings** → **Service accounts** → **Generate new private key**.
3. Save the JSON file as:

   `scripts/seed/serviceAccountKey.json`

4. Install and run:

```bash
cd scripts/seed
npm install
npm run seed
```

## Test accounts (created by `npm run seed`)

| Email | Password | Nickname |
|-------|----------|----------|
| alice.2048@test.com | `Test2048!` | Alice |
| bob.2048@test.com | `Test2048!` | Bob |
| carol.2048@test.com | `Test2048!` | Carol |

## Backfill users already in Auth Console

If you already have users (e.g. `faizamunir501@gmail.com`), run:

```bash
npm run seed:existing
```

This adds Firestore profiles, runs, and leaderboard entries for those emails without changing passwords.

## What gets created

- `users/{uid}` full profile
- `nickname_index/{nickname}`
- `users/{uid}/runs` sample games
- `users/{uid}/user_skins/owned`
- `leaderboard/global/topPlayers/{uid}`
- `friend_requests` (Bob → Alice, pending)
- `party_rooms` (code `PLAY42`)
- `notifications` sample inbox items

## Security

Never commit `serviceAccountKey.json`. It is listed in `.gitignore`.
