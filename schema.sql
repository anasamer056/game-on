CREATE TABLE IF NOT EXISTS users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now'))
);

CREATE TABLE IF NOT EXISTS invite_codes (
  code TEXT PRIMARY KEY,
  used_by_user_id INTEGER,
  FOREIGN KEY(used_by_user_id) REFERENCES users(id)
);

-- Seed exactly two invite codes at setup time (replace with your own secret values):
INSERT OR IGNORE INTO invite_codes (code) VALUES ('INVITE_CODE_PLAYER_1'), ('INVITE_CODE_PLAYER_2');

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