import bcrypt from 'bcryptjs';
import * as jose from 'jose';

export interface Env {
	DB: D1Database;
	JWT_SECRET: string;
}

interface User {
	id: number;
	username: string;
	password_hash: string;
}

interface Score {
	user_id: number;
	game: string;
	score_date: string;
	result: string;
	submitted_at: string;
}

const GAMES = ['tango', 'zip', 'queens', 'patches'];

async function getUserIdFromToken(request: Request, env: Env): Promise<{ userId: number; username: string } | null> {
	const authHeader = request.headers.get('Authorization');
	if (!authHeader || !authHeader.startsWith('Bearer ')) {
		return null;
	}
	const token = authHeader.substring(7);
	try {
		const secret = new TextEncoder().encode(env.JWT_SECRET || 'default_secret_change_me');
		const { payload } = await jose.jwtVerify(token, secret);
		return { userId: payload.userId as number, username: payload.username as string };
	} catch (e) {
		return null;
	}
}

export default {
	async fetch(request: Request, env: Env): Promise<Response> {
		const url = new URL(request.url);
		const path = url.pathname;
		const method = request.method;

		// CORS
		if (method === 'OPTIONS') {
			return new Response(null, {
				headers: {
					'Access-Control-Allow-Origin': '*',
					'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
					'Access-Control-Allow-Headers': 'Content-Type, Authorization',
				},
			});
		}

		// API Routes
		if (path === '/api/register' && method === 'POST') {
			const { username, password, inviteCode } = await request.json() as any;
			if (!username || !password || !inviteCode) {
				return new Response(JSON.stringify({ error: 'Missing fields' }), { status: 400 });
			}

			// Check invite code
			const invite = await env.DB.prepare('SELECT * FROM invite_codes WHERE code = ?').bind(inviteCode).first() as any;
			if (!invite) {
				return new Response(JSON.stringify({ error: 'Invalid invite code' }), { status: 400 });
			}
			if (invite.used_by_user_id) {
				return new Response(JSON.stringify({ error: 'Invite code already used' }), { status: 400 });
			}

			// Hash password
			const passwordHash = await bcrypt.hash(password, 10);

			try {
				const result = await env.DB.prepare('INSERT INTO users (username, password_hash) VALUES (?, ?)')
					.bind(username, passwordHash)
					.run();
				const userId = result.meta.last_row_id;

				await env.DB.prepare('UPDATE invite_codes SET used_by_user_id = ? WHERE code = ?')
					.bind(userId, inviteCode)
					.run();

				return new Response(JSON.stringify({ success: true }), { status: 201 });
			} catch (e: any) {
				if (e.message.includes('UNIQUE constraint failed')) {
					return new Response(JSON.stringify({ error: 'Username already taken' }), { status: 400 });
				}
				return new Response(JSON.stringify({ error: 'Internal Server Error' }), { status: 500 });
			}
		}

		if (path === '/api/login' && method === 'POST') {
			const { username, password } = await request.json() as any;
			const user = await env.DB.prepare('SELECT * FROM users WHERE username = ?').bind(username).first<User>();
			if (!user) {
				return new Response(JSON.stringify({ error: 'Invalid credentials' }), { status: 401 });
			}

			const isValid = await bcrypt.compare(password, user.password_hash);
			if (!isValid) {
				return new Response(JSON.stringify({ error: 'Invalid credentials' }), { status: 401 });
			}

			const secret = new TextEncoder().encode(env.JWT_SECRET || 'default_secret_change_me');
			const token = await new jose.SignJWT({ userId: user.id, username: user.username })
				.setProtectedHeader({ alg: 'HS256' })
				.setIssuedAt()
				.setExpirationTime('30d')
				.sign(secret);

			return new Response(JSON.stringify({ token, username: user.username }), { status: 200 });
		}

		// Auth Required Routes
		const auth = await getUserIdFromToken(request, env);
		if (!auth) {
			return new Response(JSON.stringify({ error: 'Unauthorized' }), { status: 401 });
		}

		if (path === '/api/scores' && method === 'POST') {
			const { game, result, score_date } = await request.json() as any;
			if (!GAMES.includes(game)) {
				return new Response(JSON.stringify({ error: 'Invalid game' }), { status: 400 });
			}

			if (!score_date || !/^\d{4}-\d{2}-\d{2}$/.test(score_date)) {
				return new Response(JSON.stringify({ error: 'Invalid date format. Use YYYY-MM-DD' }), { status: 400 });
			}

			try {
				// Use INSERT OR REPLACE to allow editing existing scores
				await env.DB.prepare('INSERT OR REPLACE INTO scores (user_id, game, score_date, result, submitted_at) VALUES (?, ?, ?, ?, datetime(\'now\'))')
					.bind(auth.userId, game, score_date, result)
					.run();
				return new Response(JSON.stringify({ success: true }), { status: 201 });
			} catch (e: any) {
				return new Response(JSON.stringify({ error: 'Internal Server Error' }), { status: 500 });
			}
		}

		if (path === '/api/scores' && method === 'GET') {
			const date = url.searchParams.get('date');
			if (!date) return new Response(JSON.stringify({ error: 'Missing date' }), { status: 400 });

			const scores = await env.DB.prepare('SELECT * FROM scores WHERE score_date = ?').bind(date).all<Score>();
			const users = await env.DB.prepare('SELECT id, username FROM users').all<{ id: number; username: string }>();
			
			const response: any = {
				scores: {},
				users: users.results.map(u => ({ 
					id: u.id, 
					username: u.username, 
					isMe: u.id === auth.userId 
				}))
			};

			for (const game of GAMES) {
				const myScore = scores.results.find(s => s.user_id === auth.userId && s.game === game);
				const friendScore = scores.results.find(s => s.user_id !== auth.userId && s.game === game);

				response.scores[game] = {
					mine: myScore ? { result: myScore.result, submitted: true } : null,
					theirs: friendScore 
						? (myScore ? { result: friendScore.result, submitted: true } : { submitted: false, notYet: true })
						: { submitted: false }
				};
			}

			return new Response(JSON.stringify(response), { status: 200 });
		}

		if (path === '/api/history' && method === 'GET') {
			// Last 14 days
			const scores = await env.DB.prepare('SELECT * FROM scores WHERE score_date >= date(\'now\', \'-14 days\') ORDER BY score_date DESC, submitted_at DESC').all<Score>();
			const users = await env.DB.prepare('SELECT id, username FROM users').all<{ id: number; username: string }>();

			// Group by date
			const history: any = {
				days: {},
				users: users.results.map(u => ({ 
					id: u.id, 
					username: u.username, 
					isMe: u.id === auth.userId 
				}))
			};
			const dates = [...new Set(scores.results.map(s => s.score_date))];

			for (const date of dates) {
				history.days[date] = {};
				for (const game of GAMES) {
					const myScore = scores.results.find(s => s.user_id === auth.userId && s.game === game && s.score_date === date);
					const friendScore = scores.results.find(s => s.user_id !== auth.userId && s.game === game && s.score_date === date);

					history.days[date][game] = {
						mine: myScore ? { result: myScore.result, submitted: true } : null,
						theirs: friendScore 
							? (myScore ? { result: friendScore.result, submitted: true } : { submitted: false, notYet: true })
							: { submitted: false }
					};
				}
			}

			return new Response(JSON.stringify(history), { status: 200 });
		}

		return new Response('Not Found', { status: 404 });
	},
};