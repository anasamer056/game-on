PRAGMA defer_foreign_keys=TRUE;
CREATE TABLE users (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  username TEXT UNIQUE NOT NULL,
  password_hash TEXT NOT NULL,
  created_at TEXT DEFAULT (datetime('now'))
);
INSERT INTO "users" ("id","username","password_hash","created_at") VALUES(1,'Anas','$2b$10$rZLE.destpV9TKVYZXTPmedrOEnZSc6/THhhLoWMZUIpJOXKJcIMW','2026-05-19 19:37:10');
INSERT INTO "users" ("id","username","password_hash","created_at") VALUES(2,'El7ra2','$2b$10$/G8qsQAl6VnLVeckLiBHJuPt5aaaG51fa0E2hGfcadVqkyd5srDSO','2026-05-20 05:34:28');
CREATE TABLE invite_codes (
  code TEXT PRIMARY KEY,
  used_by_user_id INTEGER,
  FOREIGN KEY(used_by_user_id) REFERENCES users(id)
);
INSERT INTO "invite_codes" ("code","used_by_user_id") VALUES('INVITE_CODE_PLAYER_1',1);
INSERT INTO "invite_codes" ("code","used_by_user_id") VALUES('INVITE_CODE_PLAYER_2',2);
CREATE TABLE scores (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  user_id INTEGER NOT NULL,
  game TEXT NOT NULL CHECK(game IN ('tango', 'zip', 'queens', 'patches')),
  score_date TEXT NOT NULL,         -- format: YYYY-MM-DD
  result TEXT NOT NULL,             -- free text: e.g. "1:23", "47 moves", "Failed"
  submitted_at TEXT DEFAULT (datetime('now')),
  UNIQUE(user_id, game, score_date),
  FOREIGN KEY(user_id) REFERENCES users(id)
);
INSERT INTO "scores" ("id","user_id","game","score_date","result","submitted_at") VALUES(1,1,'zip','2026-05-19',replace('Zip #428 | 0:15  🏁\nWith 1 backtrack 🛑\n🏅 I’m in the Top 75% of all players today!\nlnkd.in/zip.','\n',char(10)),'2026-05-19 19:40:45');
INSERT INTO "scores" ("id","user_id","game","score_date","result","submitted_at") VALUES(2,1,'tango','2026-05-19',replace('Tango #589 | 0:26 and flawless\nFirst 5 placements:\n3️⃣4️⃣🟨🟨🟨🟨\n2️⃣🟨🟨1️⃣🟨🟨\n5️⃣🟨🟨🟨🟨🟨\n🟨🟨🟨🟨🟨🟨\n🟨🟨🟨🟨🟨🟨\n🟨🟨🟨🟨🟨🟨\n🏅 I’m in the Top 10% of all players today!\nlnkd.in/tango.','\n',char(10)),'2026-05-19 19:40:54');
INSERT INTO "scores" ("id","user_id","game","score_date","result","submitted_at") VALUES(3,1,'queens','2026-05-19',replace('Queens #749 | 0:09 \nFirst 👑s: 🟨 🟦 🟩\n🏅 I’m in the Top 5% of all players today!\nlnkd.in/queens.','\n',char(10)),'2026-05-19 19:41:04');
INSERT INTO "scores" ("id","user_id","game","score_date","result","submitted_at") VALUES(4,1,'patches','2026-05-19',replace('Patches #63 | 0:16 🧶\nWith no hints & 2 redraws\n🏅 I’m in the Top 50% of all players today!\nlnkd.in/patches.','\n',char(10)),'2026-05-19 19:41:11');
INSERT INTO "scores" ("id","user_id","game","score_date","result","submitted_at") VALUES(5,2,'tango','2026-05-19',replace('Tango #589 | 0:18 and flawless\nFirst 5 placements:\n🟨🟨🟨🟨🟨🟨\n4️⃣🟨🟨3️⃣🟨🟨\n🟨🟨🟨2️⃣🟨🟨\n🟨5️⃣🟨🟨🟨🟨\n🟨🟨🟨🟨🟨🟨\n🟨🟨🟨1️⃣🟨🟨\n🏅 I’m in the Top 1% of all players today!\nlnkd.in/tango.','\n',char(10)),'2026-05-20 05:35:35');
INSERT INTO "scores" ("id","user_id","game","score_date","result","submitted_at") VALUES(6,2,'zip','2026-05-19',replace('Zip #428\n0:12 🏁\n🏅 I’m in the Top 25% of all players today!\nlnkd.in/zip.','\n',char(10)),'2026-05-20 05:36:18');
INSERT INTO "scores" ("id","user_id","game","score_date","result","submitted_at") VALUES(7,2,'patches','2026-05-19',replace('Patches #63 | 0:17 🧶\nWith no hints & 2 redraws\n🏅 I’m in the Top 50% of all players today!\nlnkd.in/patches.','\n',char(10)),'2026-05-20 05:37:38');
INSERT INTO "scores" ("id","user_id","game","score_date","result","submitted_at") VALUES(8,2,'queens','2026-05-19',replace('Queens #749 | 0:07 \nFirst 👑s: 🟨 🟦 🟩\n🏅 I’m in the Top 1% of all players today!\nlnkd.in/queens.','\n',char(10)),'2026-05-20 05:38:55');
INSERT INTO "scores" ("id","user_id","game","score_date","result","submitted_at") VALUES(9,1,'tango','2026-05-20',replace('Tango #590 | 0:27 and flawless\nFirst 5 placements:\n🟨🟨5️⃣4️⃣3️⃣🟨\n🟨2️⃣🟨🟨1️⃣🟨\n🟨🟨🟨🟨🟨🟨\n🟨🟨🟨🟨🟨🟨\n🟨🟨🟨🟨🟨🟨\n🟨🟨🟨🟨🟨🟨\n🏅 I’m in the Top 5% of all players today!\nlnkd.in/tango.','\n',char(10)),'2026-05-20 07:32:32');
INSERT INTO "scores" ("id","user_id","game","score_date","result","submitted_at") VALUES(10,1,'queens','2026-05-20',replace('Queens #750 | 0:32 \nFirst 👑s: 🟩 🟪 🟧\n🏅 I’m in the Top 50% of all players today!\nlnkd.in/queens.','\n',char(10)),'2026-05-20 07:33:46');
INSERT INTO "scores" ("id","user_id","game","score_date","result","submitted_at") VALUES(11,1,'zip','2026-05-20',replace('Zip #429 | 0:50  🏁\nWith 12 backtracks 🛑\n🏅 I’m on a 183-day win streak!\nlnkd.in/zip.','\n',char(10)),'2026-05-20 07:35:09');
INSERT INTO "scores" ("id","user_id","game","score_date","result","submitted_at") VALUES(12,1,'patches','2026-05-20',replace('Patches #64 | 0:10 🧶\nWith no hints & no redraws\n🏅 I’m in the Top 5% of all players today!\nlnkd.in/patches.','\n',char(10)),'2026-05-20 07:35:38');
INSERT INTO "scores" ("id","user_id","game","score_date","result","submitted_at") VALUES(13,2,'tango','2026-05-20',replace('Tango #590 | 0:20 and flawless\nFirst 5 placements:\n🟨🟨🟨🟨🟨🟨\n🟨🟨🟨🟨🟨🟨\n🟨🟨🟨🟨🟨🟨\n🟨🟨🟨🟨🟨🟨\n🟨1️⃣🟨🟨2️⃣🟨\n🟨🟨5️⃣4️⃣3️⃣🟨\n🏅 I’m in the Top 5% of all players today!\nlnkd.in/tango.','\n',char(10)),'2026-05-20 16:50:59');
INSERT INTO "scores" ("id","user_id","game","score_date","result","submitted_at") VALUES(14,2,'zip','2026-05-20',replace('Zip #429 | 0:31  🏁\nWith 5 backtracks 🛑\n🏅 I’m in the Top 75% of all players today!\nlnkd.in/zip.','\n',char(10)),'2026-05-20 16:52:05');
INSERT INTO "scores" ("id","user_id","game","score_date","result","submitted_at") VALUES(15,2,'queens','2026-05-20',replace('Queens #750 | 0:16 \nFirst 👑s: 🟪 🟧 🟩\n🏅 I’m in the Top 5% of all players today!\nlnkd.in/queens.','\n',char(10)),'2026-05-20 16:52:54');
INSERT INTO "scores" ("id","user_id","game","score_date","result","submitted_at") VALUES(16,2,'patches','2026-05-20',replace('Patches #64 | 0:09 🧶\nWith no hints & no redraws\n🏅 I’m in the Top 10% of all players today!\nlnkd.in/patches.','\n',char(10)),'2026-05-20 16:53:34');
DELETE FROM sqlite_sequence;
INSERT INTO "sqlite_sequence" ("name","seq") VALUES('users',2);
INSERT INTO "sqlite_sequence" ("name","seq") VALUES('scores',16);
