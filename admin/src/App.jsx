import { useCallback, useEffect, useMemo, useState } from 'react';
import { onAuthStateChanged, signInWithPopup, signOut } from 'firebase/auth';
import {
  collection, documentId, getCountFromServer, getDocs, query, where,
} from 'firebase/firestore';
import {
  Area, AreaChart, Bar, BarChart, CartesianGrid, Legend, ResponsiveContainer,
  Tooltip, XAxis, YAxis,
} from 'recharts';
import { ADMIN_EMAIL, auth, db, googleProvider } from './firebase.js';

// ── Dates (UTC, same keys the game writes: yyyy-MM-dd) ─────────────────────
const dayKey = (d) => d.toISOString().slice(0, 10);
const addDays = (key, n) => {
  const d = new Date(`${key}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + n);
  return dayKey(d);
};
const TODAY = () => dayKey(new Date());
const prettyDay = (key) =>
  new Date(`${key}T00:00:00Z`).toLocaleDateString(undefined, {
    month: 'short', day: 'numeric', timeZone: 'UTC',
  });

const FIELDS = [
  ['activePlayers', 'Active players'],
  ['newPlayers', 'New players'],
  ['matchesStarted', 'Matches started'],
  ['matchesCompleted', 'Completed'],
  ['matchesForfeited', 'Forfeited'],
  ['soloRounds', 'Solo rounds'],
];

const RANGES = [
  ['today', 'Today'],
  ['yesterday', 'Yesterday'],
  ['7d', 'Last 7 days'],
  ['30d', 'Last 30 days'],
];

/** Reads stats_daily docs from [start] to [end] (inclusive). Missing days = 0. */
async function loadDays(start, end) {
  const snap = await getDocs(
    query(
      collection(db, 'stats_daily'),
      where(documentId(), '>=', start),
      where(documentId(), '<=', end),
    ),
  );
  const byDay = {};
  snap.forEach((d) => { byDay[d.id] = d.data(); });
  const days = [];
  for (let k = start; k <= end; k = addDays(k, 1)) {
    const row = { day: k, label: prettyDay(k) };
    for (const [f] of FIELDS) row[f] = Number(byDay[k]?.[f] ?? 0);
    row.returningPlayers = Math.max(0, row.activePlayers - row.newPlayers);
    days.push(row);
  }
  return days;
}

const sum = (rows, f) => rows.reduce((a, r) => a + r[f], 0);

// ── Small building blocks ──────────────────────────────────────────────────
function Card({ title, children, right, className = '' }) {
  return (
    <section className={`card ${className}`}>
      {(title || right) && (
        <header className="card-head">
          {title && <h3>{title}</h3>}
          {right}
        </header>
      )}
      {children}
    </section>
  );
}

function CardError({ message, onRetry }) {
  return (
    <div className="card-error">
      <p>{message}</p>
      <button className="btn" onClick={onRetry}>Retry</button>
    </div>
  );
}

function Delta({ now, before, label }) {
  const diff = now - before;
  if (before === 0 && now === 0) return <span className="delta flat">No change {label}</span>;
  const cls = diff > 0 ? 'up' : diff < 0 ? 'down' : 'flat';
  const sign = diff > 0 ? '+' : '';
  return <span className={`delta ${cls}`}>{sign}{diff} {label}</span>;
}

function useCountUp(target) {
  const [v, setV] = useState(0);
  useEffect(() => {
    let raf;
    const start = performance.now();
    const from = 0;
    const step = (t) => {
      const p = Math.min(1, (t - start) / 600);
      const eased = 1 - Math.pow(1 - p, 3);
      setV(Math.round(from + (target - from) * eased));
      if (p < 1) raf = requestAnimationFrame(step);
    };
    raf = requestAnimationFrame(step);
    return () => cancelAnimationFrame(raf);
  }, [target]);
  return v;
}

function StatTile({ label, value, prev, compareLabel, loading }) {
  const shown = useCountUp(loading ? 0 : value);
  return (
    <div className="tile">
      <span className="tile-label">{label}</span>
      {loading ? <span className="skeleton big" /> : <span className="tile-value">{shown}</span>}
      {!loading && <Delta now={value} before={prev} label={compareLabel} />}
    </div>
  );
}

const C = {
  sky: '#38BDF8', cyan: '#00FFCC', amber: '#F59E0B', red: '#EF4444',
  grid: 'rgba(148,163,184,0.12)', text: '#94A3B8',
};

const tooltipStyle = {
  contentStyle: {
    background: '#0F172A', border: '1px solid #1E2638', borderRadius: 12,
    color: '#fff', fontSize: 12,
  },
  labelStyle: { color: '#94A3B8' },
  cursor: { fill: 'rgba(56,189,248,0.06)' },
};

// ── Live counts (refresh every 60 s) ───────────────────────────────────────
function LiveNow() {
  const [state, setState] = useState({ loading: true });
  const load = useCallback(async () => {
    try {
      const m = collection(db, 'matches');
      const [players, waiting, active] = await Promise.all([
        getCountFromServer(collection(db, 'users')),
        getCountFromServer(query(m, where('status', '==', 'waitingForOpponent'))),
        getCountFromServer(query(m, where('status', '==', 'active'))),
      ]);
      setState({
        loading: false,
        players: players.data().count,
        waiting: waiting.data().count,
        active: active.data().count,
        at: new Date(),
      });
    } catch (e) {
      setState({ loading: false, error: e.message });
    }
  }, []);
  useEffect(() => {
    load();
    const id = setInterval(load, 60000);
    return () => clearInterval(id);
  }, [load]);

  return (
    <Card
      title="Right now"
      right={state.at && <span className="muted">Updated {state.at.toLocaleTimeString()}</span>}
    >
      {state.error ? (
        <CardError message={state.error} onRetry={load} />
      ) : (
        <div className="live">
          {[
            ['Total players', state.players],
            ['Open waiting rooms', state.waiting],
            ['Active matches', state.active],
          ].map(([l, v]) => (
            <div key={l} className="live-item">
              <span className="tile-label">{l}</span>
              {state.loading ? <span className="skeleton" /> : <span className="live-value">{v}</span>}
            </div>
          ))}
        </div>
      )}
    </Card>
  );
}

// ── Dashboard ──────────────────────────────────────────────────────────────
function Dashboard({ user }) {
  const [range, setRange] = useState('today');
  const [picked, setPicked] = useState(TODAY());
  const [data, setData] = useState({ loading: true });

  // Selected period + the equal period right before it, plus 30 days for charts.
  const period = useMemo(() => {
    const today = TODAY();
    if (range === 'today') return { start: today, end: today, len: 1, cmp: 'vs yesterday' };
    if (range === 'yesterday') {
      const y = addDays(today, -1);
      return { start: y, end: y, len: 1, cmp: 'vs day before' };
    }
    if (range === '7d') return { start: addDays(today, -6), end: today, len: 7, cmp: 'vs prev 7 days' };
    if (range === '30d') return { start: addDays(today, -29), end: today, len: 30, cmp: 'vs prev 30 days' };
    return { start: picked, end: picked, len: 1, cmp: 'vs day before' };
  }, [range, picked]);

  const load = useCallback(async () => {
    setData((d) => ({ ...d, loading: true, error: null }));
    try {
      const today = TODAY();
      const chartStart = addDays(today, -29);
      const prevStart = addDays(period.start, -period.len);
      const from = prevStart < chartStart ? prevStart : chartStart;
      const to = period.end > today ? period.end : today;
      const days = await loadDays(from, to);
      const inRange = (a, b) => days.filter((r) => r.day >= a && r.day <= b);
      setData({
        loading: false,
        current: inRange(period.start, period.end),
        previous: inRange(prevStart, addDays(period.start, -1)),
        chart: inRange(chartStart, today),
      });
    } catch (e) {
      setData({ loading: false, error: e.message });
    }
  }, [period]);

  useEffect(() => { load(); }, [load]);

  const periodTitle =
    period.len === 1 ? prettyDay(period.start) : `${prettyDay(period.start)} – ${prettyDay(period.end)}`;

  return (
    <div className="shell">
      <aside className="sidebar">
        <div className="brand"><span className="dot" />DunkVerse</div>
        <nav>
          <a className="active">Overview</a>
          <a className="soon" title="Coming later">Matches</a>
          <a className="soon" title="Coming later">Cleanup</a>
        </nav>
        <div className="me">
          <span className="muted small">{user.email}</span>
          <button className="btn ghost" onClick={() => signOut(auth)}>Sign out</button>
        </div>
      </aside>

      <main className="main">
        <header className="topbar">
          <div>
            <h1>Overview</h1>
            <p className="muted">{periodTitle} · UTC</p>
          </div>
          <div className="controls">
            <div className="segmented">
              {RANGES.map(([k, l]) => (
                <button key={k} className={range === k ? 'on' : ''} onClick={() => setRange(k)}>{l}</button>
              ))}
            </div>
            <input
              type="date"
              className="date"
              value={picked}
              max={TODAY()}
              onChange={(e) => { setPicked(e.target.value); setRange('pick'); }}
            />
          </div>
        </header>

        {data.error ? (
          <Card><CardError message={data.error} onRetry={load} /></Card>
        ) : (
          <div className="tiles">
            {FIELDS.map(([f, label]) => (
              <StatTile
                key={f}
                label={label}
                loading={data.loading}
                value={data.current ? sum(data.current, f) : 0}
                prev={data.previous ? sum(data.previous, f) : 0}
                compareLabel={period.cmp}
              />
            ))}
          </div>
        )}

        <div className="grid">
          <Card title="Daily active players" right={<span className="muted">Last 30 days</span>} className="wide">
            {data.loading ? <div className="skeleton chart" /> : !data.error && (
              <ResponsiveContainer width="100%" height={260}>
                <AreaChart data={data.chart} margin={{ left: -20, right: 8, top: 8 }}>
                  <defs>
                    <linearGradient id="dau" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="0%" stopColor={C.sky} stopOpacity={0.45} />
                      <stop offset="100%" stopColor={C.sky} stopOpacity={0} />
                    </linearGradient>
                  </defs>
                  <CartesianGrid stroke={C.grid} vertical={false} />
                  <XAxis dataKey="label" tick={{ fill: C.text, fontSize: 11 }} axisLine={false} tickLine={false} minTickGap={24} />
                  <YAxis allowDecimals={false} tick={{ fill: C.text, fontSize: 11 }} axisLine={false} tickLine={false} />
                  <Tooltip {...tooltipStyle} />
                  <Area type="monotone" dataKey="activePlayers" name="Active players" stroke={C.sky} strokeWidth={2.5} fill="url(#dau)" />
                </AreaChart>
              </ResponsiveContainer>
            )}
          </Card>

          <LiveNow />

          <Card title="Matches per day" right={<span className="muted">Last 30 days</span>}>
            {data.loading ? <div className="skeleton chart" /> : !data.error && (
              <ResponsiveContainer width="100%" height={240}>
                <BarChart data={data.chart} margin={{ left: -20, right: 8, top: 8 }}>
                  <CartesianGrid stroke={C.grid} vertical={false} />
                  <XAxis dataKey="label" tick={{ fill: C.text, fontSize: 11 }} axisLine={false} tickLine={false} minTickGap={24} />
                  <YAxis allowDecimals={false} tick={{ fill: C.text, fontSize: 11 }} axisLine={false} tickLine={false} />
                  <Tooltip {...tooltipStyle} />
                  <Legend wrapperStyle={{ fontSize: 12, color: C.text }} />
                  <Bar dataKey="matchesCompleted" name="Completed" stackId="m" fill={C.cyan} radius={[0, 0, 0, 0]} />
                  <Bar dataKey="matchesForfeited" name="Forfeited" stackId="m" fill={C.amber} radius={[6, 6, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            )}
          </Card>

          <Card title="New vs returning players" right={<span className="muted">Last 30 days</span>}>
            {data.loading ? <div className="skeleton chart" /> : !data.error && (
              <ResponsiveContainer width="100%" height={240}>
                <BarChart data={data.chart} margin={{ left: -20, right: 8, top: 8 }}>
                  <CartesianGrid stroke={C.grid} vertical={false} />
                  <XAxis dataKey="label" tick={{ fill: C.text, fontSize: 11 }} axisLine={false} tickLine={false} minTickGap={24} />
                  <YAxis allowDecimals={false} tick={{ fill: C.text, fontSize: 11 }} axisLine={false} tickLine={false} />
                  <Tooltip {...tooltipStyle} />
                  <Legend wrapperStyle={{ fontSize: 12, color: C.text }} />
                  <Bar dataKey="returningPlayers" name="Returning" stackId="p" fill={C.sky} />
                  <Bar dataKey="newPlayers" name="New" stackId="p" fill={C.cyan} radius={[6, 6, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            )}
          </Card>
        </div>
        <p className="muted small foot">Counting started when daily stats shipped; earlier days show 0.</p>
      </main>
    </div>
  );
}

// ── Sign-in gate ───────────────────────────────────────────────────────────
export default function App() {
  const [user, setUser] = useState(undefined);
  const [err, setErr] = useState(null);
  useEffect(() => onAuthStateChanged(auth, setUser), []);

  if (user === undefined) return <div className="center"><span className="skeleton" /></div>;

  if (!user || user.isAnonymous) {
    return (
      <div className="center">
        <div className="card login">
          <div className="brand"><span className="dot" />DunkVerse Admin</div>
          <p className="muted">Sign in with the admin Google account.</p>
          {err && <p className="err">{err}</p>}
          <button
            className="btn primary"
            onClick={() => signInWithPopup(auth, googleProvider).catch((e) => setErr(e.message))}
          >
            Sign in with Google
          </button>
        </div>
      </div>
    );
  }

  if (user.email !== ADMIN_EMAIL) {
    return (
      <div className="center">
        <div className="card login">
          <h3>Not authorized</h3>
          <p className="muted">{user.email} isn’t the admin account.</p>
          <button className="btn" onClick={() => signOut(auth)}>Sign out</button>
        </div>
      </div>
    );
  }

  return <Dashboard user={user} />;
}
