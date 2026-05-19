# Gemini CLI Prompt — LinkedIn Games Score Tracker

Paste this entire prompt into Gemini CLI to scaffold the project.

---

Build a full-stack web app called **"Game On"** — a two-player daily score tracker for LinkedIn games (Tango, Zip, Queens, Patches). The app is for exactly two friends who compete daily. The critical rule: **a player cannot see their friend's score for a given game until the friend has also submitted their score.** This prevents info advantages.

## Tech Stack
- **Frontend**: Single HTML file with embedded CSS and JS (no framework, no build step)
- **Backend**: Cloudflare Workers (TypeScript)
- **Database**: Cloudflare D1 (SQLite)
- **Auth**: Username + bcrypt-hashed password stored in D1. On login, issue a signed JWT (using the `jose` library or Cloudflare's `crypto.subtle`) stored in localStorage. All API routes except `/api/login` and `/api/register` require a valid `Authorization: Bearer <token>` header.

## File Structure
```
/
├── worker/
│   ├── src/
│   │   └── index.ts        # All Worker logic
│   ├── wrangler.toml
│   └── package.json
└── frontend/
    └── index.html          # Complete frontend (HTML + CSS + JS in one file)
```

## Database Schema (D1)

```sql
CREATE TABLE IF NOT EXISTS invite_codes (
  code TEXT PRIMARY KEY,
  used_by_user_id INTEGER,
  FOREIGN KEY(used_by_user_id) REFERENCES users(id)
);

-- Seed exactly two invite codes at setup time (replace with your own secret values):
INSERT OR IGNORE INTO invite_codes (code) VALUES ('INVITE_CODE_PLAYER_1'), ('INVITE_CODE_PLAYER_2');

CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS scores (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  game TEXT NOT NULL CHECK(game IN ('tango', 'zip', 'queens', 'patches')),
  score_date TEXT NOT NULL,         -- format: YYYY-MM-DD
  result TEXT NOT NULL,             -- free text: e.g. "1:23", "47 moves", "Failed"
  submitted_at TEXT DEFAULT (datetime('now')),
  UNIQUE(user_id, game, score_date),
  FOREIGN KEY(user_id) REFERENCES users(id)
);
```

## API Routes (Cloudflare Worker)

### POST /api/register
- Body: `{ username, password, inviteCode }`
- Look up `inviteCode` in the `invite_codes` table
- Reject with 400 if the code doesn't exist or `used_by_user_id` is already set (code already claimed)
- Hash password with bcrypt (use `bcryptjs` npm package)
- Insert into `users` table
- Mark the invite code as used: `UPDATE invite_codes SET used_by_user_id = ? WHERE code = ?`
- Return `{ success: true }`
- **There is no fallback user-count check** — the invite code system is the sole registration gate. Once both codes are claimed, registration is permanently closed with no workaround.

### POST /api/login
- Body: `{ username, password }`
- Verify password hash
- Return a signed JWT with payload `{ userId, username }`, expiry 30 days
- Return `{ token, username }`

### POST /api/scores (auth required)
- Body: `{ game, result, score_date }`
- Insert into `scores` table (reject duplicate: same user + game + date)
- Return `{ success: true }`

### GET /api/scores?date=YYYY-MM-DD (auth required)
- Return scores for both users for that date
- **Critical reveal logic**: For each game, include the friend's result ONLY IF the friend has also submitted a score for that game+date. Otherwise return `{ submitted: false }` for the friend.
- Response shape:
```json
{
  "tango": {
    "mine": { "result": "1:23", "submitted": true } | null,
    "theirs": { "result": "0:58", "submitted": true } | { "submitted": false } | { "submitted": false, "notYet": true }
  },
  "zip": { ... },
  "queens": { ... },
  "patches": { ... }
}
```

### GET /api/history (auth required)
- Return last 14 days of scores, both players, all games
- Apply same reveal logic: only show opponent score if both submitted
- Group by date

## Frontend (single index.html)

Design aesthetic: **clean and sporty** — think a scorecard app. Use dark navy background (#0f172a), bright accent color (#22d3ee cyan), white text. Use the Google Font "Outfit" for a modern feel. Card-based layout, smooth CSS transitions.

### Views (rendered via JS, no page reloads):

**1. Auth Screen** (shown if no token in localStorage)
- Toggle between Login and Register forms
- Login form: username + password fields
- Register form: username + password + invite code fields (the invite code field should be clearly labeled "Invite Code" with placeholder "Enter your invite code")
- On success, store JWT and username in localStorage, show Dashboard

**2. Dashboard** (default view after login)
- Header: "Game On ⚡" logo left, username + logout button right
- Today's date displayed
- 4 game cards in a 2x2 grid: Tango, Zip, Queens, Patches
- Each card shows:
  - Game name + icon (use emoji: 🟡 Tango, 🔗 Zip, 👑 Queens, 🧩 Patches)
  - **Your score**: if submitted, show result in a green badge. If not, show a "Submit Score" button.
  - **Friend's score**: if both submitted, show their result. If they haven't submitted yet, show a lock icon 🔒 and "Waiting...". If you haven't submitted yet either, show "Submit yours first".
- A "History" link at the bottom

**3. Submit Score Modal**
- Triggered by "Submit Score" button on a card
- Shows game name
- Text input: "Your result" (placeholder: e.g. "1:23 ✅" or "Failed ❌")
- Submit button → calls POST /api/scores → refreshes dashboard

**4. History View**
- Back button to dashboard
- List of past 14 days grouped by date (most recent first)
- Each date expands to show a mini scorecard for all 4 games: your result vs friend's result side by side
- Show "🏆" next to the winner of each game (lower time = better for Tango/Zip/Queens; lower moves = better for Patches — but since results are free text, just display both and let users judge visually)

## wrangler.toml
```toml
name = "game-on-worker"
main = "src/index.ts"
compatibility_date = "2024-01-01"

[[d1_databases]]
binding = "DB"
database_name = "game-on-db"
database_id = "YOUR_D1_DATABASE_ID"
```

## Important Implementation Notes
1. The Worker should serve the `index.html` frontend on `GET /` by reading it as a static asset (use `wrangler.toml` `[site]` config or inline the HTML as a string in the worker for simplicity).
2. CORS headers: allow requests from same origin.
3. All D1 queries use `env.DB.prepare(...).bind(...).run()` / `.first()` / `.all()` patterns.
4. JWT secret should be stored as a Cloudflare Worker secret (`wrangler secret put JWT_SECRET`).
5. The two invite codes must be seeded into D1 before either player registers. The deployer (Player 1) controls both codes and shares only one with their friend. Once both are used, the `invite_codes` table acts as a permanent lock — no new registrations are possible under any circumstance.
6. The frontend should handle token expiry gracefully (401 response → clear localStorage → show auth screen).

Generate the complete, working code for all files. Do not leave placeholders — write the full implementation.