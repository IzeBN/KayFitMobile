// Kayfit 2.0 — radically minimal calorie tracker
// Two screens: Journal + Chat. One unified add-meal flow.
// Monochrome, sans + mono for numbers.

const KAYFIT_FONTS = {
  sans: "'Geist', 'Söhne', -apple-system, BlinkMacSystemFont, system-ui, sans-serif",
  mono: "'JetBrains Mono', 'Geist Mono', 'SF Mono', ui-monospace, Menlo, monospace",
};

// ─────────────────────────────────────────────────────────────
// Seed data
// ─────────────────────────────────────────────────────────────
const SEED_TODAY = [
  {
    id: 'm1', time: '08:24', type: 'breakfast', name: 'oatmeal with berries',
    kcal: 320, p: 12, f: 6, c: 54, source: 'photo', photoSeed: 1,
  },
  {
    id: 'm2', time: '13:10', type: 'lunch', name: 'chicken bowl, rice, broccoli',
    kcal: 540, p: 42, f: 14, c: 58, source: 'voice',
  },
  {
    id: 'm3', time: '16:30', type: 'snack', name: 'greek yogurt, almonds',
    kcal: 210, p: 18, f: 11, c: 9, source: 'text',
  },
  {
    id: 'm4', time: '11:05', type: 'snack', name: 'cappuccino + croissant',
    kcal: 380, p: 8, f: 19, c: 42, source: 'photo', photoSeed: 2,
  },
];

const SEED_CHAT = [
  { id: 'c1', from: 'ai', text: 'Hi. Send a photo, voice note, or just type what you ate.' },
  { id: 'c2', from: 'user', text: 'logged the chicken bowl from lunch' },
  { id: 'c3', from: 'ai', text: 'Got it — 540 kcal, 42g protein. You\'re at 1070 / 2100 kcal for today.' },
];

const DAILY_GOAL = 2100;

// ─────────────────────────────────────────────────────────────
// Icon set — single-stroke, monochrome
// ─────────────────────────────────────────────────────────────
const Icon = ({ name, size = 20, color = 'currentColor', strokeWidth = 1.5 }) => {
  const paths = {
    plus: <><path d="M12 5v14M5 12h14"/></>,
    close: <><path d="M18 6L6 18M6 6l12 12"/></>,
    chevronLeft: <><path d="M15 6l-6 6 6 6"/></>,
    chevronRight: <><path d="M9 6l6 6-6 6"/></>,
    chevronDown: <><path d="M6 9l6 6 6-6"/></>,
    chevronUp: <><path d="M6 15l6-6 6 6"/></>,
    camera: <><rect x="3" y="6" width="18" height="14" rx="1.5"/><circle cx="12" cy="13" r="4"/><path d="M9 6l1.5-2h3L15 6"/></>,
    mic: <><rect x="9" y="3" width="6" height="12" rx="3"/><path d="M5 11a7 7 0 0014 0M12 18v3"/></>,
    text: <><path d="M4 7h16M7 7v12M17 7v12M9 19h6"/></>,
    barcode: <><path d="M3 5v14M6 5v14M9 5v14M12 5v14M15 5v14M18 5v14M21 5v14"/></>,
    chat: <><path d="M21 12a8 8 0 01-11.5 7.2L4 21l1.8-5.5A8 8 0 1121 12z"/></>,
    journal: <><path d="M5 4h11a3 3 0 013 3v13a1 1 0 01-1 1H8a3 3 0 01-3-3V4zM5 17h14"/></>,
    user: <><circle cx="12" cy="8" r="4"/><path d="M4 21c0-4.4 3.6-8 8-8s8 3.6 8 8"/></>,
    calendar: <><rect x="3" y="5" width="18" height="16" rx="1.5"/><path d="M3 9h18M8 3v4M16 3v4"/></>,
    send: <><path d="M22 2L11 13M22 2l-7 20-4-9-9-4 20-7z"/></>,
    trash: <><path d="M3 6h18M8 6V4a1 1 0 011-1h6a1 1 0 011 1v2M19 6l-1 14a2 2 0 01-2 2H8a2 2 0 01-2-2L5 6"/></>,
    edit: <><path d="M12 20h9M16.5 3.5a2.1 2.1 0 013 3L7 19l-4 1 1-4 12.5-12.5z"/></>,
    check: <><path d="M5 13l4 4L19 7"/></>,
    sparkle: <><path d="M12 2v6M12 16v6M2 12h6M16 12h6M5 5l4 4M15 15l4 4M19 5l-4 4M9 15l-4 4"/></>,
    dot: <><circle cx="12" cy="12" r="3" fill={color}/></>,
    paperclip: <><path d="M21 11l-9 9a5 5 0 01-7-7l9-9a3.5 3.5 0 015 5l-9 9a2 2 0 01-3-3l8-8"/></>,
  };
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none"
      stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round"
      style={{ flexShrink: 0 }}>
      {paths[name]}
    </svg>
  );
};

// ─────────────────────────────────────────────────────────────
// Theme helpers
// ─────────────────────────────────────────────────────────────
const getTheme = (dark) => dark ? {
  bg: '#0A0A0A', surface: '#0A0A0A', card: '#141414',
  fg: '#FAFAFA', fgDim: '#888', fgMute: '#555',
  border: '#1F1F1F', borderStrong: '#2A2A2A',
  accent: '#FAFAFA', accentFg: '#000',
  hairline: '#1A1A1A',
} : {
  bg: '#FAFAFA', surface: '#FFFFFF', card: '#FFFFFF',
  fg: '#0A0A0A', fgDim: '#737373', fgMute: '#A3A3A3',
  border: '#E5E5E5', borderStrong: '#D4D4D4',
  accent: '#0A0A0A', accentFg: '#FFFFFF',
  hairline: '#EFEFEF',
};

// ─────────────────────────────────────────────────────────────
// Hairline divider
// ─────────────────────────────────────────────────────────────
const HR = ({ t }) => <div style={{ height: 1, background: t.hairline }} />;

// ─────────────────────────────────────────────────────────────
// SUMMARY VARIANTS — different ways to show calories
// ─────────────────────────────────────────────────────────────
// Apple Activity-style three concentric rings — kcal (red/pink Move), protein (green Exercise), carbs (cyan Stand)
// Uses Apple's signature gradient on each ring (lighter → bolder going clockwise from start).
function SummaryAppleRings({ kcal, goal, t, macros, big = false }) {
  const goalP = 130, goalF = 70, goalC = 250;
  const pcts = [
    Math.min(1, kcal / goal),
    Math.min(1, macros.p / goalP),
    Math.min(1, macros.c / goalC),
    Math.min(1, macros.f / goalF),
  ];
  // Apple Activity colors: Move (red→pink), Exercise (green→lime), Stand (cyan→blue), + Fat (orange/yellow)
  const RING_COLORS = [
    { from: '#FF2D55', to: '#FF375F', track: 'rgba(255,55,95,0.18)' }, // kcal
    { from: '#A6FF00', to: '#76E60E', track: 'rgba(166,255,0,0.18)' }, // protein
    { from: '#1ECEDA', to: '#3FE9FF', track: 'rgba(30,206,218,0.18)' }, // carbs
    { from: '#FF9500', to: '#FFCC00', track: 'rgba(255,149,0,0.18)' }, // fat
  ];
  const isDark = t.bg === '#0A0A0A';
  const tracks = isDark
    ? RING_COLORS.map(c => c.track)
    : ['rgba(255,55,95,0.12)', 'rgba(118,230,14,0.14)', 'rgba(30,206,218,0.14)', 'rgba(255,149,0,0.14)'];

  const cx = 70, cy = 70;
  const radii = [60, 48, 36, 24];
  const sw = 10;
  const uid = React.useId ? React.useId() : 'ar';
  const ring = (i) => {
    const r = radii[i];
    const cir = 2 * Math.PI * r;
    const gradId = `${uid}-grad-${i}`;
    return (
      <g key={i}>
        <defs>
          <linearGradient id={gradId} x1="0" y1="0" x2="1" y2="1">
            <stop offset="0%" stopColor={RING_COLORS[i].from}/>
            <stop offset="100%" stopColor={RING_COLORS[i].to}/>
          </linearGradient>
        </defs>
        <circle cx={cx} cy={cy} r={r} fill="none" stroke={tracks[i]} strokeWidth={sw}/>
        <circle cx={cx} cy={cy} r={r} fill="none" stroke={`url(#${gradId})`} strokeWidth={sw}
          strokeDasharray={`${cir * pcts[i]} ${cir}`}
          strokeLinecap="round"
          transform={`rotate(-90 ${cx} ${cy})`}/>
      </g>
    );
  };
  const labels = [
    { key: 'kcal', label: 'kcal', val: kcal, goalV: goal, color: RING_COLORS[0].to },
    { key: 'protein', label: 'protein', val: macros.p, goalV: goalP, color: RING_COLORS[1].to, unit: 'g' },
    { key: 'carbs', label: 'carbs', val: macros.c, goalV: goalC, color: RING_COLORS[2].to, unit: 'g' },
    { key: 'fat', label: 'fat', val: macros.f, goalV: goalF, color: RING_COLORS[3].to, unit: 'g' },
  ];
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 18 }}>
      <svg width={140} height={140} style={{ flexShrink: 0 }}>
        {[0,1,2,3].map(ring)}
      </svg>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 7, flex: 1 }}>
        {labels.map(l => (
          <div key={l.key} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <div style={{ width: 8, height: 8, borderRadius: '50%', background: l.color, flexShrink: 0 }}/>
            <div style={{ fontSize: 10, color: t.fgDim, textTransform: 'uppercase', letterSpacing: 0.8, minWidth: 50 }}>{l.label}</div>
            <div style={{ fontFamily: KAYFIT_FONTS.mono, fontSize: 13, color: t.fg, marginLeft: 'auto' }}>
              {l.val}{l.unit || ''}<span style={{ color: t.fgMute, fontSize: 11 }}>/{l.goalV}{l.unit || ''}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function SummaryRing({ kcal, goal, t, big = false }) {
  const pct = Math.min(1, kcal / goal);
  const r = big ? 56 : 40;
  const cir = 2 * Math.PI * r;
  const size = (r + 8) * 2;
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: big ? 20 : 16 }}>
      <div style={{ position: 'relative', width: size, height: size }}>
        <svg width={size} height={size}>
          <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={t.border} strokeWidth={2}/>
          <circle cx={size/2} cy={size/2} r={r} fill="none" stroke={t.fg} strokeWidth={2}
            strokeDasharray={`${cir * pct} ${cir}`}
            strokeLinecap="round"
            transform={`rotate(-90 ${size/2} ${size/2})`}/>
        </svg>
        <div style={{
          position: 'absolute', inset: 0, display: 'flex', alignItems: 'center', justifyContent: 'center',
          flexDirection: 'column',
        }}>
          <div style={{ fontFamily: KAYFIT_FONTS.mono, fontSize: big ? 22 : 16, fontWeight: 600, color: t.fg, letterSpacing: -0.5 }}>{kcal}</div>
          <div style={{ fontSize: 9, color: t.fgDim, textTransform: 'uppercase', letterSpacing: 0.6, marginTop: -2 }}>kcal</div>
        </div>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
        <div style={{ fontSize: 11, color: t.fgDim, textTransform: 'uppercase', letterSpacing: 0.8 }}>remaining</div>
        <div style={{ fontFamily: KAYFIT_FONTS.mono, fontSize: big ? 24 : 18, fontWeight: 500, color: t.fg, letterSpacing: -0.4 }}>{goal - kcal}</div>
        <div style={{ fontSize: 11, color: t.fgMute, fontFamily: KAYFIT_FONTS.mono }}>of {goal}</div>
      </div>
    </div>
  );
}

function SummaryBar({ kcal, goal, t }) {
  const pct = Math.min(1, kcal / goal);
  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'baseline', justifyContent: 'space-between', marginBottom: 10 }}>
        <div>
          <span style={{ fontFamily: KAYFIT_FONTS.mono, fontSize: 32, fontWeight: 600, color: t.fg, letterSpacing: -1.2 }}>{kcal}</span>
          <span style={{ fontFamily: KAYFIT_FONTS.mono, fontSize: 14, color: t.fgDim, marginLeft: 6 }}>/ {goal}</span>
        </div>
        <div style={{ fontSize: 11, color: t.fgDim, textTransform: 'uppercase', letterSpacing: 0.8 }}>kcal today</div>
      </div>
      <div style={{ height: 2, background: t.border, position: 'relative' }}>
        <div style={{ height: '100%', width: `${pct*100}%`, background: t.fg, transition: 'width .4s ease' }}/>
      </div>
    </div>
  );
}

function SummaryHero({ kcal, goal, t }) {
  return (
    <div>
      <div style={{ fontSize: 11, color: t.fgDim, textTransform: 'uppercase', letterSpacing: 1 }}>today</div>
      <div style={{ fontFamily: KAYFIT_FONTS.mono, fontSize: 88, fontWeight: 500, color: t.fg, letterSpacing: -3.5, lineHeight: 0.9, marginTop: 4 }}>
        {kcal}
      </div>
      <div style={{ fontFamily: KAYFIT_FONTS.mono, fontSize: 13, color: t.fgDim, marginTop: 8 }}>
        {goal - kcal} kcal remaining of {goal}
      </div>
    </div>
  );
}

function SummaryNumeric({ kcal, goal, t, macros }) {
  const pct = Math.round((kcal / goal) * 100);
  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', marginBottom: 14 }}>
        <div style={{ fontFamily: KAYFIT_FONTS.mono, fontSize: 44, fontWeight: 500, color: t.fg, letterSpacing: -1.5, lineHeight: 1 }}>
          {kcal}
          <span style={{ fontSize: 16, color: t.fgDim, marginLeft: 4 }}>/{goal}</span>
        </div>
        <div style={{ fontFamily: KAYFIT_FONTS.mono, fontSize: 13, color: t.fgDim }}>{pct}%</div>
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 0, borderTop: `1px solid ${t.hairline}`, paddingTop: 10 }}>
        {[['P', macros.p, 130], ['F', macros.f, 70], ['C', macros.c, 250]].map(([l, v, g]) => (
          <div key={l} style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            <div style={{ fontSize: 10, color: t.fgMute, textTransform: 'uppercase', letterSpacing: 1 }}>{l}</div>
            <div style={{ fontFamily: KAYFIT_FONTS.mono, fontSize: 15, color: t.fg }}>{v}<span style={{ color: t.fgMute, fontSize: 11 }}>/{g}</span></div>
          </div>
        ))}
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Calendar strip — collapsible
// ─────────────────────────────────────────────────────────────
function CalendarStrip({ t, expanded, onToggle, selected, onSelect }) {
  const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  const today = new Date();

  // Deterministic per-day status — in real app comes from journal data.
  // green = within goal, red = over, null = empty/no entries.
  // We seed with day-of-month for stable demo data.
  const statusFor = (d) => {
    const dom = d.getDate();
    const isFuture = d > today;
    if (isFuture) return null;
    // Use modulo pattern for variety: most days green, some red, some empty
    const r = (dom * 7 + d.getMonth() * 13) % 10;
    if (r < 6) return 'good';
    if (r < 8) return 'over';
    return null;
  };

  const STATUS_COLORS = {
    good: { ring: '#34C759', track: 'rgba(52,199,89,0.18)' },
    over: { ring: '#FF3B30', track: 'rgba(255,59,48,0.18)' },
  };

  const nums = [];
  for (let i = 6; i >= 0; i--) {
    const d = new Date(today); d.setDate(today.getDate() - i);
    nums.push({ day: days[(d.getDay()+6)%7], n: d.getDate(), iso: d.toISOString().slice(0,10), isToday: i === 0, status: i === 0 ? 'good' : statusFor(d) });
  }

  // build full month grid
  const monthDays = [];
  const first = new Date(today.getFullYear(), today.getMonth(), 1);
  const startDay = (first.getDay() + 6) % 7;
  const daysInMonth = new Date(today.getFullYear(), today.getMonth()+1, 0).getDate();
  for (let i = 0; i < startDay; i++) monthDays.push(null);
  for (let i = 1; i <= daysInMonth; i++) {
    const d = new Date(today.getFullYear(), today.getMonth(), i);
    monthDays.push({ n: i, status: i === today.getDate() ? 'good' : statusFor(d) });
  }

  return (
    <div style={{ borderBottom: `1px solid ${t.hairline}`, background: t.bg }}>
      {/* compact week strip */}
      <div style={{ display: 'flex', padding: '8px 16px 12px', gap: 4 }}>
        {nums.map((d, i) => {
          const isSel = selected === d.iso || (selected === 'today' && d.isToday);
          const stColor = d.status ? STATUS_COLORS[d.status] : null;
          const ringSize = 36;
          return (
            <button key={i} onClick={() => onSelect(d.isToday ? 'today' : d.iso)}
              style={{
                flex: 1, padding: '6px 0', border: 'none', background: 'transparent',
                cursor: 'pointer', fontFamily: 'inherit',
                display: 'flex', flexDirection: 'column', gap: 4, alignItems: 'center',
                borderRadius: 0,
              }}>
              <div style={{ fontSize: 10, color: t.fgDim, textTransform: 'uppercase', letterSpacing: 0.5 }}>{d.day}</div>
              <div style={{
                position: 'relative',
                width: ringSize, height: ringSize,
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
                {/* Apple-style closed ring around the date */}
                {stColor && (
                  <svg width={ringSize} height={ringSize} style={{ position: 'absolute', inset: 0 }}>
                    <circle cx={ringSize/2} cy={ringSize/2} r={ringSize/2 - 2}
                      fill="none" stroke={stColor.track} strokeWidth={2.5}/>
                    <circle cx={ringSize/2} cy={ringSize/2} r={ringSize/2 - 2}
                      fill="none" stroke={stColor.ring} strokeWidth={2.5}
                      strokeLinecap="round"
                      strokeDasharray={`${2 * Math.PI * (ringSize/2 - 2)} ${2 * Math.PI * (ringSize/2 - 2)}`}
                      transform={`rotate(-90 ${ringSize/2} ${ringSize/2})`}/>
                  </svg>
                )}
                {isSel && (
                  <div style={{
                    position: 'absolute', inset: 0,
                    borderRadius: '50%',
                    background: '#007AFF',
                  }}/>
                )}
                <div style={{
                  fontFamily: KAYFIT_FONTS.mono, fontSize: 14, fontWeight: 500,
                  color: isSel ? '#fff' : t.fg,
                  position: 'relative', zIndex: 1,
                }}>{d.n}</div>
              </div>
            </button>
          );
        })}
        <button onClick={onToggle}
          style={{
            border: 'none', background: 'transparent', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            width: 32, color: t.fgDim,
          }}>
          <Icon name={expanded ? 'chevronUp' : 'chevronDown'} size={16}/>
        </button>
      </div>
      {/* expanded month */}
      {expanded && (
        <div style={{ padding: '4px 16px 16px' }}>
          <div style={{ fontSize: 11, color: t.fgDim, textTransform: 'uppercase', letterSpacing: 1, marginBottom: 8 }}>
            {today.toLocaleDateString('en-US', { month: 'long', year: 'numeric' }).toLowerCase()}
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7, 1fr)', gap: 2 }}>
            {['M','T','W','T','F','S','S'].map((d, i) => (
              <div key={i} style={{ fontSize: 10, color: t.fgMute, textTransform: 'uppercase', textAlign: 'center', padding: '4px 0' }}>{d}</div>
            ))}
            {monthDays.map((m, i) => {
              if (!m) return <div key={i}/>;
              const n = m.n;
              const isToday = n === today.getDate();
              const stColor = m.status ? STATUS_COLORS[m.status] : null;
              return (
                <button key={i} onClick={() => onSelect(isToday ? 'today' : `d${n}`)}
                  style={{
                    aspectRatio: '1', border: 'none', background: 'transparent', cursor: 'pointer',
                    padding: 2,
                    display: 'flex', alignItems: 'center', justifyContent: 'center',
                    position: 'relative',
                  }}>
                  {stColor && (
                    <svg viewBox="0 0 100 100" style={{ position: 'absolute', inset: 4 }}>
                      <circle cx="50" cy="50" r="46" fill="none" stroke={stColor.track} strokeWidth="6"/>
                      <circle cx="50" cy="50" r="46" fill="none" stroke={stColor.ring} strokeWidth="6"
                        strokeLinecap="round" strokeDasharray="289 289" transform="rotate(-90 50 50)"/>
                    </svg>
                  )}
                  {isToday && (
                    <div style={{ position: 'absolute', inset: 4, borderRadius: '50%', background: '#007AFF' }}/>
                  )}
                  <div style={{
                    fontFamily: KAYFIT_FONTS.mono, fontSize: 13,
                    color: isToday ? '#fff' : t.fg, position: 'relative', zIndex: 1,
                  }}>{n}</div>
                </button>
              );
            })}
          </div>
          {/* legend — Apple-style */}
          <div style={{ display: 'flex', gap: 14, padding: '14px 4px 4px', fontSize: 11, color: t.fgDim, fontFamily: KAYFIT_FONTS.mono }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <svg width="14" height="14"><circle cx="7" cy="7" r="5.5" fill="none" stroke="#34C759" strokeWidth="2.5"/></svg>
              on track
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <svg width="14" height="14"><circle cx="7" cy="7" r="5.5" fill="none" stroke="#FF3B30" strokeWidth="2.5"/></svg>
              over goal
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
              <svg width="14" height="14"><circle cx="7" cy="7" r="5.5" fill="none" stroke={t.border} strokeWidth="2.5"/></svg>
              empty
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Meal row
// ─────────────────────────────────────────────────────────────
const sourceLabel = { photo: 'photo', voice: 'voice', text: 'typed', barcode: 'scan' };

// Photo placeholder — striped greyscale tile representing a food photo
function MealPhoto({ seed = 1, t, size = 56 }) {
  // deterministic hue rotation for visual variety in placeholders
  const stripes = seed % 3 === 0
    ? `repeating-linear-gradient(135deg, #4a4a4a, #4a4a4a 6px, #5e5e5e 6px, #5e5e5e 12px)`
    : seed % 3 === 1
    ? `repeating-linear-gradient(45deg, #6b6258, #6b6258 6px, #7d7368 6px, #7d7368 12px)`
    : `repeating-linear-gradient(90deg, #5a5550, #5a5550 6px, #6b655e 6px, #6b655e 12px)`;
  return (
    <div style={{
      width: size, height: size, borderRadius: 6, flexShrink: 0,
      background: stripes, position: 'relative', overflow: 'hidden',
      border: `1px solid ${t.border}`,
    }}>
      <div style={{
        position: 'absolute', inset: 0,
        display: 'flex', alignItems: 'center', justifyContent: 'center',
      }}>
        <Icon name="camera" size={14} color="rgba(255,255,255,0.5)" strokeWidth={1.5}/>
      </div>
    </div>
  );
}

function MealRow({ meal, t, onClick, onDelete, dense = false }) {
  const hasPhoto = meal.source === 'photo' && meal.photoSeed != null;
  return (
    <div onClick={onClick}
      style={{
        display: 'flex', alignItems: 'flex-start', gap: 12,
        padding: dense ? '12px 16px' : '14px 16px',
        borderBottom: `1px solid ${t.hairline}`, cursor: 'pointer',
      }}>
      {hasPhoto ? (
        <MealPhoto seed={meal.photoSeed} t={t} size={56}/>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', minWidth: 36 }}>
          <div style={{ fontFamily: KAYFIT_FONTS.mono, fontSize: 11, color: t.fgDim }}>{meal.time}</div>
          <div style={{ fontSize: 9, color: t.fgMute, textTransform: 'uppercase', letterSpacing: 0.6, marginTop: 2 }}>{sourceLabel[meal.source]}</div>
        </div>
      )}
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 6, marginBottom: 2 }}>
          <div style={{ fontSize: 10, color: t.fgMute, textTransform: 'uppercase', letterSpacing: 1 }}>{meal.type}</div>
          {hasPhoto && (
            <div style={{ fontFamily: KAYFIT_FONTS.mono, fontSize: 10, color: t.fgMute }}>· {meal.time}</div>
          )}
        </div>
        <div style={{ fontSize: 14, color: t.fg, lineHeight: 1.3 }}>{meal.name}</div>
        <div style={{ fontFamily: KAYFIT_FONTS.mono, fontSize: 11, color: t.fgDim, marginTop: 4 }}>
          P {meal.p}<span style={{ opacity: 0.4, margin: '0 5px' }}>·</span>
          F {meal.f}<span style={{ opacity: 0.4, margin: '0 5px' }}>·</span>
          C {meal.c}
        </div>
      </div>
      <div style={{ textAlign: 'right' }}>
        <div style={{ fontFamily: KAYFIT_FONTS.mono, fontSize: 18, fontWeight: 500, color: t.fg, letterSpacing: -0.4 }}>{meal.kcal}</div>
        <div style={{ fontSize: 9, color: t.fgMute, textTransform: 'uppercase', letterSpacing: 0.8, marginTop: -2 }}>kcal</div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Bottom navigation — 2 tabs + center add button
// ─────────────────────────────────────────────────────────────
function TabBar({ t, active, onTab, onAdd, navStyle = 'split' }) {
  const isDark = t.bg === '#0A0A0A';
  // Apple-style accent — vibrant blue (system blue) tinted to match app
  const ACCENT = '#007AFF';
  const tabBtn = (key, label, icon) => (
    <button onClick={() => onTab(key)}
      style={{
        flex: 1, padding: '8px 0 6px', border: 'none', background: 'transparent', cursor: 'pointer',
        display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
        fontFamily: 'inherit',
        color: active === key ? ACCENT : '#8E8E93',
      }}>
      <Icon name={icon} size={24} strokeWidth={active === key ? 2 : 1.5} color={active === key ? ACCENT : '#8E8E93'}/>
      <div style={{ fontSize: 10, fontWeight: 500, letterSpacing: 0.1 }}>{label}</div>
    </button>
  );

  return (
    <div style={{
      display: 'flex', alignItems: 'flex-end',
      borderTop: `0.5px solid ${isDark ? 'rgba(255,255,255,0.12)' : 'rgba(0,0,0,0.1)'}`,
      background: isDark ? 'rgba(20,20,22,0.92)' : 'rgba(255,255,255,0.92)',
      backdropFilter: 'saturate(180%) blur(20px)',
      WebkitBackdropFilter: 'saturate(180%) blur(20px)',
      paddingBottom: 6,
      paddingTop: 4,
      minHeight: 64,
    }}>
      {tabBtn('journal', 'Journal', 'journal')}
      <button onClick={onAdd}
        style={{
          width: 88, padding: '6px 0 6px',
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
          background: 'transparent', border: 'none', cursor: 'pointer', fontFamily: 'inherit',
        }}>
        <div style={{
          width: 44, height: 44, borderRadius: '50%',
          background: `linear-gradient(135deg, #5AC8FA 0%, ${ACCENT} 100%)`,
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: `0 4px 14px rgba(0,122,255,0.42), 0 1px 3px rgba(0,0,0,0.10)`,
        }}>
          <Icon name="plus" size={22} strokeWidth={2.6} color="#fff"/>
        </div>
        <div style={{ fontSize: 10, fontWeight: 600, color: ACCENT, letterSpacing: 0.1 }}>Add</div>
      </button>
      {tabBtn('chat', 'Chat', 'chat')}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Top bar — title + account
// ─────────────────────────────────────────────────────────────
function TopBar({ t, title, onAccount, large = true, right }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: large ? '16px 16px 12px' : '12px 16px',
      background: t.bg,
    }}>
      <div style={{
        fontSize: large ? 22 : 17, fontWeight: 600, color: t.fg, letterSpacing: -0.5,
      }}>{title}</div>
      <div style={{ display: 'flex', gap: 8 }}>
        {right}
        <button onClick={onAccount}
          style={{
            width: 32, height: 32, borderRadius: '50%',
            background: 'transparent', border: `1px solid ${t.border}`,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            cursor: 'pointer', color: t.fg,
          }}>
          <Icon name="user" size={14}/>
        </button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Add-meal sheet — 4 input methods on one screen
// ─────────────────────────────────────────────────────────────
function AddSheet({ t, onPick, onClose, layout = 'grid' }) {
  const isDark = t.bg === '#0A0A0A';
  const ACCENT = '#007AFF';
  const surfaceBg = isDark ? '#1C1C1E' : '#FFFFFF';
  const cardBg = isDark ? '#2C2C2E' : '#F2F2F7';
  const labelColor = t.fg;
  const subColor = '#8E8E93';
  const methods = [
    { key: 'photo', label: 'Photo', sub: 'Snap your plate', icon: 'camera', tint: '#FF9500' },
    { key: 'voice', label: 'Voice', sub: 'Say what you ate', icon: 'mic', tint: '#FF3B30' },
    { key: 'barcode', label: 'Scan', sub: 'Barcode lookup', icon: 'barcode', tint: '#34C759' },
    { key: 'text', label: 'Text', sub: 'Type it out', icon: 'text', tint: ACCENT },
  ];
  return (
    <div style={{
      background: surfaceBg, borderTopLeftRadius: 14, borderTopRightRadius: 14, overflow: 'hidden',
      boxShadow: '0 -4px 24px rgba(0,0,0,0.16)',
    }}>
      <div style={{ padding: '8px 16px 4px', display: 'flex', justifyContent: 'center' }}>
        <div style={{ width: 36, height: 5, background: isDark ? '#3A3A3C' : '#D1D1D6', borderRadius: 3 }}/>
      </div>
      <div style={{ padding: '16px 20px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
        <div>
          <div style={{ fontSize: 22, fontWeight: 700, color: t.fg, letterSpacing: -0.4 }}>Add a meal</div>
          <div style={{ fontSize: 13, color: subColor, marginTop: 2 }}>Choose how to log</div>
        </div>
        <button onClick={onClose}
          style={{
            width: 30, height: 30, borderRadius: '50%',
            background: cardBg, border: 'none', cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            color: subColor,
          }}>
          <Icon name="close" size={14} color={subColor} strokeWidth={2.4}/>
        </button>
      </div>
      <div style={{ padding: '12px 16px 20px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
        {methods.map(m => (
          <button key={m.key} onClick={() => onPick(m.key)}
            style={{
              padding: '20px 16px', border: 'none', borderRadius: 14,
              background: cardBg, cursor: 'pointer', fontFamily: 'inherit',
              display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: 12,
              minHeight: 130, color: labelColor, textAlign: 'left',
              transition: 'transform 0.15s',
            }}>
            <div style={{
              width: 38, height: 38, borderRadius: 10,
              background: m.tint, display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: `0 2px 6px ${m.tint}55`,
            }}>
              <Icon name={m.icon} size={20} color="#fff" strokeWidth={2}/>
            </div>
            <div style={{ marginTop: 'auto' }}>
              <div style={{ fontSize: 15, fontWeight: 600, color: labelColor, letterSpacing: -0.2 }}>{m.label}</div>
              <div style={{ fontSize: 12, color: subColor, marginTop: 2 }}>{m.sub}</div>
            </div>
          </button>
        ))}
      </div>
    </div>
  );
}


// ─────────────────────────────────────────────────────────────
// Recognition / preview screen
// ─────────────────────────────────────────────────────────────
function RecognitionScreen({ t, method, onSave, onCancel }) {
  const [step, setStep] = React.useState('capture'); // capture, recognizing, preview
  const [aiCorrectOpen, setAiCorrectOpen] = React.useState(false);
  const [aiCorrectText, setAiCorrectText] = React.useState('');
  const [aiCorrecting, setAiCorrecting] = React.useState(false);
  const [expandedItem, setExpandedItem] = React.useState(null);
  const [items, setItems] = React.useState([
    { id: 'i1', name: 'grilled chicken breast', grams: 150, kcal: 247, p: 46, f: 5, c: 0 },
    { id: 'i2', name: 'jasmine rice', grams: 180, kcal: 234, p: 4, f: 0, c: 52 },
    { id: 'i3', name: 'steamed broccoli', grams: 90, kcal: 31, p: 3, f: 0, c: 6 },
  ]);
  const [mealType, setMealType] = React.useState('lunch');

  React.useEffect(() => {
    if (method === 'text') { setStep('preview'); return; }
    setStep('capture');
    const t1 = setTimeout(() => setStep('recognizing'), 800);
    const t2 = setTimeout(() => setStep('preview'), 2200);
    return () => { clearTimeout(t1); clearTimeout(t2); };
  }, [method]);

  const total = items.reduce((s, i) => s + i.kcal, 0);
  const totalP = items.reduce((s, i) => s + i.p, 0);
  const totalF = items.reduce((s, i) => s + i.f, 0);
  const totalC = items.reduce((s, i) => s + i.c, 0);

  const captureLabel = {
    photo: 'aim at your plate', voice: 'tell me what you ate',
    text: '', barcode: 'point at the barcode',
  }[method];

  if (step === 'capture' || step === 'recognizing') {
    return (
      <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: t.bg }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', padding: '12px 16px' }}>
          <button onClick={onCancel} style={{ background: 'transparent', border: 'none', cursor: 'pointer', color: t.fg, padding: 4 }}>
            <Icon name="close" size={20}/>
          </button>
          <div style={{ fontSize: 13, color: t.fgDim, textTransform: 'uppercase', letterSpacing: 1 }}>{method}</div>
          <div style={{ width: 28 }}/>
        </div>
        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', justifyContent: 'center', padding: 24, gap: 24 }}>
          {method === 'photo' && (
            <div style={{
              width: 240, height: 240, border: `2px dashed ${t.border}`, borderRadius: 16,
              display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative',
              background: `repeating-linear-gradient(45deg, ${t.bg}, ${t.bg} 8px, ${t.hairline} 8px, ${t.hairline} 9px)`,
            }}>
              <Icon name="camera" size={32} color={t.fgDim}/>
            </div>
          )}
          {method === 'voice' && (
            <div style={{
              width: 200, height: 200, borderRadius: '50%', border: `2px solid ${t.fg}`,
              display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative',
            }}>
              <Icon name="mic" size={48} color={t.fg}/>
              {step === 'recognizing' && (
                <div style={{ position: 'absolute', inset: -8, borderRadius: '50%', border: `2px solid ${t.fg}`, opacity: 0.3, animation: 'kfPulse 1.5s ease-out infinite' }}/>
              )}
            </div>
          )}
          {method === 'barcode' && (
            <div style={{
              width: 240, height: 140, border: `2px solid ${t.fg}`, borderRadius: 4,
              display: 'flex', alignItems: 'center', justifyContent: 'center', position: 'relative',
            }}>
              <Icon name="barcode" size={48} color={t.fg}/>
              <div style={{
                position: 'absolute', left: 0, right: 0, top: '50%', height: 2, background: t.fg,
                animation: 'kfScan 1.6s ease-in-out infinite',
              }}/>
            </div>
          )}
          <div style={{ textAlign: 'center' }}>
            <div style={{ fontSize: 15, color: t.fg, marginBottom: 4 }}>
              {step === 'recognizing' ? 'analyzing…' : captureLabel}
            </div>
            <div style={{ fontSize: 12, color: t.fgDim, fontFamily: KAYFIT_FONTS.mono }}>
              {step === 'recognizing' ? 'AI is identifying items' : 'tap to capture'}
            </div>
          </div>
          {step === 'capture' && (
            <button onClick={() => setStep('recognizing')}
              style={{
                width: 64, height: 64, borderRadius: '50%', border: `2px solid ${t.fg}`,
                background: t.fg, cursor: 'pointer', marginTop: 20,
              }}>
              <div style={{ width: 48, height: 48, borderRadius: '50%', background: t.fg, border: `2px solid ${t.bg}`, margin: 'auto' }}/>
            </button>
          )}
        </div>
        <style>{`
          @keyframes kfPulse { 0%{transform:scale(1);opacity:.4} 100%{transform:scale(1.4);opacity:0} }
          @keyframes kfScan { 0%,100%{top:10%}50%{top:90%} }
          @keyframes kfSpin { to { transform: rotate(360deg); } }
        `}</style>
      </div>
    );
  }

  // preview / edit
  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: t.bg }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '12px 16px' }}>
        <button onClick={onCancel} style={{ background: 'transparent', border: 'none', cursor: 'pointer', color: t.fg, padding: 4 }}>
          <Icon name="close" size={20}/>
        </button>
        <div style={{ fontSize: 13, color: t.fgDim, textTransform: 'uppercase', letterSpacing: 1 }}>review</div>
        <div style={{ width: 28 }}/>
      </div>

      <div style={{ flex: 1, overflow: 'auto' }}>
        <div style={{ padding: '8px 20px 24px' }}>
          <div style={{ fontSize: 11, color: t.fgDim, textTransform: 'uppercase', letterSpacing: 1 }}>total</div>
          <div style={{ fontFamily: KAYFIT_FONTS.mono, fontSize: 56, fontWeight: 500, color: t.fg, letterSpacing: -2, lineHeight: 1, marginTop: 4 }}>
            {total}<span style={{ fontSize: 18, color: t.fgDim, marginLeft: 6 }}>kcal</span>
          </div>
          <div style={{ fontFamily: KAYFIT_FONTS.mono, fontSize: 12, color: t.fgDim, marginTop: 8 }}>
            P {totalP}g <span style={{ opacity: 0.4 }}>·</span> F {totalF}g <span style={{ opacity: 0.4 }}>·</span> C {totalC}g
          </div>
        </div>

        <div style={{ borderTop: `1px solid ${t.hairline}` }}>
          <div style={{ padding: '12px 20px 6px', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <div style={{ fontSize: 10, color: t.fgMute, textTransform: 'uppercase', letterSpacing: 1 }}>items</div>
            <div style={{ fontSize: 10, color: t.fgMute, fontFamily: KAYFIT_FONTS.mono }}>tap pencil to edit macros</div>
          </div>
          {items.map((it, i) => (
            <div key={it.id} style={{ borderTop: `1px solid ${t.hairline}` }}>
              <div style={{ padding: '12px 20px' }}>
                <div style={{ display: 'flex', alignItems: 'baseline', gap: 12 }}>
                  <div style={{ flex: 1, fontSize: 14, color: t.fg }}>{it.name}</div>
                  <div style={{ fontFamily: KAYFIT_FONTS.mono, fontSize: 14, color: t.fg }}>{it.kcal}</div>
                  <div style={{ fontSize: 10, color: t.fgMute, fontFamily: KAYFIT_FONTS.mono }}>kcal</div>
                </div>
                <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 8 }}>
                  <input type="number" value={it.grams} onChange={e => {
                    const v = parseInt(e.target.value) || 0;
                    const ratio = v / (it.grams || 1);
                    setItems(items.map(x => x.id === it.id ? {
                      ...x, grams: v,
                      kcal: Math.round(x.kcal * ratio),
                      p: Math.round(x.p * ratio * 10) / 10,
                      f: Math.round(x.f * ratio * 10) / 10,
                      c: Math.round(x.c * ratio * 10) / 10,
                    } : x));
                  }}
                    style={{
                      width: 60, padding: '4px 6px', border: `1px solid ${t.border}`, borderRadius: 4,
                      fontFamily: KAYFIT_FONTS.mono, fontSize: 12, color: t.fg, background: t.bg,
                      outline: 'none',
                    }}/>
                  <span style={{ fontSize: 11, color: t.fgDim, fontFamily: KAYFIT_FONTS.mono }}>g</span>
                  <span style={{ fontSize: 11, color: t.fgMute, fontFamily: KAYFIT_FONTS.mono, marginLeft: 8, flex: 1 }}>
                    P {it.p} · F {it.f} · C {it.c}
                  </span>
                  {/* pencil — toggle macro editor */}
                  <button onClick={() => setExpandedItem(expandedItem === it.id ? null : it.id)}
                    style={{
                      width: 30, height: 30, borderRadius: 8,
                      border: `1px solid ${expandedItem === it.id ? '#007AFF' : t.border}`,
                      background: expandedItem === it.id ? 'rgba(0,122,255,0.08)' : 'transparent',
                      color: expandedItem === it.id ? '#007AFF' : t.fgDim,
                      cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}>
                    <Icon name="edit" size={13} color={expandedItem === it.id ? '#007AFF' : t.fgDim}/>
                  </button>
                  {/* X — remove */}
                  <button onClick={() => setItems(items.filter(x => x.id !== it.id))}
                    style={{
                      width: 30, height: 30, borderRadius: 8,
                      border: `1px solid ${t.border}`,
                      background: 'transparent',
                      color: '#FF3B30',
                      cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
                    }}>
                    <Icon name="close" size={14} color="#FF3B30" strokeWidth={2}/>
                  </button>
                </div>
              </div>
              {expandedItem === it.id && (
                <div style={{ padding: '12px 20px 16px', background: t.surface, borderTop: `1px solid ${t.hairline}` }}>
                  <div style={{ fontSize: 10, color: t.fgMute, textTransform: 'uppercase', letterSpacing: 1, marginBottom: 10, display: 'flex', alignItems: 'center', gap: 6 }}>
                    <Icon name="edit" size={11}/>
                    edit macros (kcal recalculates)
                  </div>
                  <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 8 }}>
                    {[['p', 'protein', '#A6FF00'], ['f', 'fat', '#FF9500'], ['c', 'carbs', '#1ECEDA']].map(([k, label, color]) => (
                      <div key={k}>
                        <div style={{ fontSize: 9, color: t.fgMute, textTransform: 'uppercase', letterSpacing: 0.6, marginBottom: 4, display: 'flex', alignItems: 'center', gap: 4 }}>
                          <div style={{ width: 6, height: 6, borderRadius: '50%', background: color }}/>
                          {label}
                        </div>
                        <div style={{ display: 'flex', alignItems: 'center', gap: 4, border: `1px solid ${t.border}`, borderRadius: 6, padding: '4px 8px', background: t.bg }}>
                          <input type="number" step="0.1" value={it[k]}
                            onChange={e => {
                              const v = parseFloat(e.target.value) || 0;
                              setItems(items.map(x => {
                                if (x.id !== it.id) return x;
                                const upd = { ...x, [k]: v };
                                upd.kcal = Math.round(upd.p * 4 + upd.f * 9 + upd.c * 4);
                                return upd;
                              }));
                            }}
                            style={{
                              flex: 1, width: '100%', padding: 0, border: 'none',
                              fontFamily: KAYFIT_FONTS.mono, fontSize: 14, color: t.fg, background: 'transparent',
                              outline: 'none',
                            }}/>
                          <span style={{ fontSize: 10, color: t.fgMute, fontFamily: KAYFIT_FONTS.mono }}>g</span>
                        </div>
                      </div>
                    ))}
                  </div>
                  <div style={{ marginTop: 10, fontSize: 11, color: t.fgDim, fontFamily: KAYFIT_FONTS.mono, display: 'flex', justifyContent: 'space-between' }}>
                    <span>final kcal</span>
                    <span style={{ color: t.fg }}>{Math.round(it.p * 4 + it.f * 9 + it.c * 4)}</span>
                  </div>
                </div>
              )}
            </div>
          ))}
          {/* + add item button — Apple style filled */}
          <button onClick={() => {
            const id = 'i' + Date.now();
            const newItem = { id, name: 'new item', grams: 100, kcal: 0, p: 0, f: 0, c: 0 };
            setItems([...items, newItem]);
            setExpandedItem(id);
          }}
            style={{
              display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8, width: '100%',
              padding: '14px 20px', border: 'none', borderTop: `1px solid ${t.hairline}`,
              background: 'transparent', cursor: 'pointer', fontFamily: 'inherit',
              color: '#007AFF', fontSize: 14, fontWeight: 500,
            }}>
            <div style={{
              width: 22, height: 22, borderRadius: '50%', background: '#007AFF',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
              <Icon name="plus" size={14} color="#fff" strokeWidth={2.6}/>
            </div>
            add item
          </button>
        </div>

        {/* AI correct — natural-language fix */}
        <div style={{ borderTop: `1px solid ${t.hairline}`, padding: '14px 20px' }}>
          {!aiCorrectOpen ? (
            <button onClick={() => setAiCorrectOpen(true)}
              style={{
                display: 'flex', alignItems: 'center', gap: 8, width: '100%',
                padding: '10px 12px', border: `1px dashed ${t.border}`, borderRadius: 6,
                background: 'transparent', cursor: 'pointer', fontFamily: 'inherit',
                color: t.fgDim, fontSize: 12,
              }}>
              <Icon name="sparkle" size={14}/>
              <span>tell AI to correct &mdash; "no rice, add quinoa"</span>
            </button>
          ) : (
            <div style={{ border: `1px solid ${t.border}`, borderRadius: 6, padding: 10 }}>
              <div style={{ fontSize: 10, color: t.fgMute, textTransform: 'uppercase', letterSpacing: 1, marginBottom: 6 }}>describe the correction</div>
              <textarea
                autoFocus
                value={aiCorrectText}
                onChange={e => setAiCorrectText(e.target.value)}
                placeholder="that&rsquo;s actually quinoa, not rice. and the chicken was closer to 200g"
                style={{
                  width: '100%', minHeight: 60, resize: 'none',
                  border: 'none', outline: 'none', background: 'transparent',
                  fontFamily: 'inherit', fontSize: 13, color: t.fg,
                  lineHeight: 1.4,
                }}/>
              <div style={{ display: 'flex', gap: 8, marginTop: 8, justifyContent: 'flex-end' }}>
                <button onClick={() => { setAiCorrectOpen(false); setAiCorrectText(''); }}
                  style={{
                    padding: '6px 12px', border: `1px solid ${t.border}`, borderRadius: 4,
                    background: 'transparent', color: t.fgDim, cursor: 'pointer',
                    fontFamily: 'inherit', fontSize: 12,
                  }}>cancel</button>
                <button
                  disabled={!aiCorrectText.trim() || aiCorrecting}
                  onClick={() => {
                    setAiCorrecting(true);
                    setTimeout(() => {
                      // demo: tweak first item to show the AI "applied" the change
                      setItems(prev => prev.map((x, i) => i === 0 ? {
                        ...x, name: aiCorrectText.toLowerCase().includes('quinoa') ? 'quinoa bowl' : x.name,
                        grams: Math.round(x.grams * 1.1),
                        kcal: Math.round(x.kcal * 1.1),
                      } : x));
                      setAiCorrecting(false);
                      setAiCorrectOpen(false);
                      setAiCorrectText('');
                    }, 1200);
                  }}
                  style={{
                    padding: '6px 12px', border: 'none', borderRadius: 4,
                    background: t.fg, color: t.accentFg, cursor: aiCorrectText.trim() ? 'pointer' : 'not-allowed',
                    opacity: aiCorrectText.trim() ? 1 : 0.4,
                    fontFamily: 'inherit', fontSize: 12, fontWeight: 600,
                    display: 'flex', alignItems: 'center', gap: 6,
                  }}>
                  {aiCorrecting ? (
                    <>
                      <span style={{
                        width: 10, height: 10, borderRadius: '50%',
                        border: `1.5px solid ${t.accentFg}`, borderTopColor: 'transparent',
                        animation: 'kfSpin 0.8s linear infinite',
                      }}/>
                      applying
                    </>
                  ) : <>apply</>}
                </button>
              </div>
            </div>
          )}
        </div>

        <div style={{ padding: '20px', borderTop: `1px solid ${t.hairline}` }}>
          <div style={{ fontSize: 10, color: t.fgMute, textTransform: 'uppercase', letterSpacing: 1, marginBottom: 8 }}>meal</div>
          <div style={{ display: 'flex', gap: 6 }}>
            {['breakfast', 'lunch', 'dinner', 'snack'].map(mt => (
              <button key={mt} onClick={() => setMealType(mt)}
                style={{
                  flex: 1, padding: '8px 4px', border: `1px solid ${mealType === mt ? t.fg : t.border}`,
                  borderRadius: 4, background: mealType === mt ? t.fg : 'transparent',
                  color: mealType === mt ? t.accentFg : t.fg,
                  fontFamily: 'inherit', fontSize: 11, textTransform: 'lowercase', cursor: 'pointer',
                }}>{mt}</button>
            ))}
          </div>
        </div>
      </div>

      <div style={{ padding: '12px 16px 16px', borderTop: `1px solid ${t.hairline}` }}>
        <button onClick={() => onSave({
          name: items.map(i => i.name).join(', ').slice(0, 60),
          kcal: total, p: totalP, f: totalF, c: totalC,
          type: mealType, source: method,
        })}
          style={{
            width: '100%', padding: '14px', border: 'none', borderRadius: 8,
            background: t.fg, color: t.accentFg, fontFamily: 'inherit',
            fontSize: 14, fontWeight: 600, cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 8,
            textTransform: 'lowercase', letterSpacing: 0.3,
          }}>
          <Icon name="check" size={16} color={t.accentFg} strokeWidth={2.5}/> save to journal
        </button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Account sheet — minimal
// ─────────────────────────────────────────────────────────────
function AccountSheet({ t, onClose }) {
  return (
    <div style={{ background: t.surface, borderTopLeftRadius: 24, borderTopRightRadius: 24, overflow: 'hidden' }}>
      <div style={{ padding: '12px 16px 0', display: 'flex', justifyContent: 'center' }}>
        <div style={{ width: 36, height: 4, background: t.border, borderRadius: 2 }}/>
      </div>
      <div style={{ padding: '20px 20px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
        <div style={{ fontSize: 18, fontWeight: 600, color: t.fg }}>account</div>
        <button onClick={onClose} style={{ background: 'transparent', border: 'none', cursor: 'pointer', color: t.fgDim, padding: 4 }}>
          <Icon name="close" size={18}/>
        </button>
      </div>
      <div style={{ padding: '8px 20px 20px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 12, padding: '12px 0', borderBottom: `1px solid ${t.hairline}` }}>
          <div style={{ width: 44, height: 44, borderRadius: '50%', background: t.fg, color: t.accentFg, display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 16, fontWeight: 600 }}>K</div>
          <div>
            <div style={{ fontSize: 14, color: t.fg, fontWeight: 500 }}>kayfit user</div>
            <div style={{ fontSize: 12, color: t.fgDim, fontFamily: KAYFIT_FONTS.mono }}>goal · 2100 kcal/day</div>
          </div>
        </div>
        {['goal & macros', 'preferences', 'export data', 'sign out'].map((s, i) => (
          <button key={s} style={{
            display: 'flex', alignItems: 'center', justifyContent: 'space-between', width: '100%',
            padding: '14px 0', border: 'none', borderBottom: `1px solid ${t.hairline}`,
            background: 'transparent', cursor: 'pointer', fontFamily: 'inherit',
            color: t.fg, fontSize: 14,
          }}>
            <span>{s}</span>
            <Icon name="chevronRight" size={14} color={t.fgMute}/>
          </button>
        ))}
      </div>
    </div>
  );
}

Object.assign(window, {
  KAYFIT_FONTS, getTheme, Icon, HR,
  SummaryRing, SummaryBar, SummaryHero, SummaryNumeric, SummaryAppleRings,
  CalendarStrip, MealRow, MealPhoto, TabBar, TopBar, AddSheet, RecognitionScreen, AccountSheet,
  SEED_TODAY, SEED_CHAT, DAILY_GOAL, sourceLabel,
});
