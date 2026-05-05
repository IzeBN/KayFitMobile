// Kayfit screens — Journal, Chat, and main shell

// ─────────────────────────────────────────────────────────────
// Journal screen — variants differ in summary style + density
// ─────────────────────────────────────────────────────────────
function JournalScreen({ t, meals, summaryStyle = 'ring', dense = false, onMealTap, onAccount, calendarExpanded, setCalendarExpanded, selectedDate, setSelectedDate, groupBy = 'type' }) {
  const totalKcal = meals.reduce((s, m) => s + m.kcal, 0);
  const macros = {
    p: meals.reduce((s, m) => s + m.p, 0),
    f: meals.reduce((s, m) => s + m.f, 0),
    c: meals.reduce((s, m) => s + m.c, 0),
  };

  const grouped = {};
  if (groupBy === 'type') {
    for (const m of meals) {
      (grouped[m.type] ||= []).push(m);
    }
  } else {
    grouped['all'] = meals;
  }
  const order = ['breakfast', 'lunch', 'snack', 'dinner', 'all'];

  let SummaryComp;
  if (summaryStyle === 'apple') SummaryComp = <SummaryAppleRings kcal={totalKcal} goal={DAILY_GOAL} t={t} macros={macros} big/>;
  else if (summaryStyle === 'ring') SummaryComp = <SummaryRing kcal={totalKcal} goal={DAILY_GOAL} t={t} big/>;
  else if (summaryStyle === 'bar') SummaryComp = <SummaryBar kcal={totalKcal} goal={DAILY_GOAL} t={t}/>;
  else if (summaryStyle === 'hero') SummaryComp = <SummaryHero kcal={totalKcal} goal={DAILY_GOAL} t={t}/>;
  else if (summaryStyle === 'numeric') SummaryComp = <SummaryNumeric kcal={totalKcal} goal={DAILY_GOAL} t={t} macros={macros}/>;

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: t.bg, color: t.fg, fontFamily: KAYFIT_FONTS.sans }}>
      <TopBar t={t} title="journal" onAccount={onAccount}/>
      <CalendarStrip t={t} expanded={calendarExpanded} onToggle={() => setCalendarExpanded(!calendarExpanded)} selected={selectedDate} onSelect={setSelectedDate}/>
      <div style={{ flex: 1, overflow: 'auto', minHeight: 0 }}>
        <div style={{ padding: '14px 20px 12px', borderBottom: `1px solid ${t.hairline}` }}>
          {SummaryComp}
        </div>
        {meals.length === 0 ? (
          <div style={{ padding: 40, textAlign: 'center' }}>
            <div style={{ fontSize: 13, color: t.fgDim, fontFamily: KAYFIT_FONTS.mono }}>nothing logged yet</div>
            <div style={{ fontSize: 11, color: t.fgMute, marginTop: 6 }}>tap + to add a meal</div>
          </div>
        ) : (
          order.filter(k => grouped[k]).map(k => (
            <div key={k}>
              {groupBy === 'type' && (
                <div style={{
                  padding: '14px 16px 6px', display: 'flex', alignItems: 'baseline', justifyContent: 'space-between',
                }}>
                  <div style={{ fontSize: 10, color: t.fgMute, textTransform: 'uppercase', letterSpacing: 1.2 }}>{k}</div>
                  <div style={{ fontSize: 10, color: t.fgMute, fontFamily: KAYFIT_FONTS.mono }}>
                    {grouped[k].reduce((s, m) => s + m.kcal, 0)} kcal
                  </div>
                </div>
              )}
              {grouped[k].map(m => <MealRow key={m.id} meal={m} t={t} onClick={() => onMealTap(m)} dense={dense}/>)}
            </div>
          ))
        )}
        <div style={{ height: 24 }}/>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Chat screen — AI nutritionist + inline input methods
// ─────────────────────────────────────────────────────────────
function ChatScreen({ t, messages, onSend, onAccount, onAttach, thinking }) {
  const [draft, setDraft] = React.useState('');
  const scrollRef = React.useRef(null);

  React.useEffect(() => {
    if (scrollRef.current) scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
  }, [messages, thinking]);

  return (
    <div style={{ height: '100%', display: 'flex', flexDirection: 'column', background: t.bg, color: t.fg, fontFamily: KAYFIT_FONTS.sans }}>
      <TopBar t={t} title="chat" onAccount={onAccount}/>
      <div style={{ padding: '0 16px 12px', borderBottom: `1px solid ${t.hairline}`, display: 'flex', alignItems: 'center', gap: 8 }}>
        <div style={{ width: 8, height: 8, borderRadius: '50%', background: t.fg }}/>
        <div style={{ fontSize: 11, color: t.fgDim, textTransform: 'uppercase', letterSpacing: 0.8 }}>ai nutritionist</div>
        <div style={{ flex: 1 }}/>
        <div style={{ fontSize: 10, color: t.fgMute, fontFamily: KAYFIT_FONTS.mono }}>online</div>
      </div>

      <div ref={scrollRef} style={{ flex: 1, overflow: 'auto', padding: '16px' }}>
        {messages.map((m, i) => (
          <div key={m.id} style={{
            display: 'flex', justifyContent: m.from === 'user' ? 'flex-end' : 'flex-start',
            marginBottom: 10,
          }}>
            <div style={{
              maxWidth: '78%',
              padding: '10px 14px',
              border: `1px solid ${t.border}`,
              borderRadius: 14,
              borderBottomRightRadius: m.from === 'user' ? 4 : 14,
              borderBottomLeftRadius: m.from === 'ai' ? 4 : 14,
              background: m.from === 'user' ? t.fg : t.surface,
              color: m.from === 'user' ? t.accentFg : t.fg,
              fontSize: 14, lineHeight: 1.45,
            }}>
              {m.text}
              {m.attachment && (
                <div style={{
                  marginTop: 8, padding: 10, borderRadius: 8,
                  border: `1px solid ${m.from === 'user' ? 'rgba(255,255,255,0.2)' : t.hairline}`,
                  display: 'flex', alignItems: 'center', gap: 10,
                }}>
                  <Icon name={m.attachment.icon} size={16} color={m.from === 'user' ? t.accentFg : t.fgDim}/>
                  <div style={{ fontSize: 12, fontFamily: KAYFIT_FONTS.mono, opacity: 0.9 }}>
                    {m.attachment.label}
                  </div>
                </div>
              )}
            </div>
          </div>
        ))}

        {thinking && (
          <div style={{ display: 'flex', justifyContent: 'flex-start', marginBottom: 10, animation: 'kfFade 0.2s ease' }}>
            <div style={{
              maxWidth: '78%',
              padding: '10px 14px',
              border: `1px solid ${t.border}`,
              borderRadius: 14, borderBottomLeftRadius: 4,
              background: t.surface, color: t.fgDim,
              fontSize: 13, lineHeight: 1.45,
              display: 'flex', flexDirection: 'column', gap: 6,
            }}>
              {thinking.steps.map((s, i) => (
                <div key={i} style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                  {i === thinking.steps.length - 1 && !thinking.done ? (
                    <span style={{
                      width: 10, height: 10, borderRadius: '50%',
                      border: `1.5px solid ${t.fgDim}`, borderTopColor: 'transparent',
                      display: 'inline-block',
                      animation: 'kfSpin 0.8s linear infinite',
                    }}/>
                  ) : (
                    <Icon name="check" size={11} strokeWidth={2.5} color={t.fgDim}/>
                  )}
                  <span style={{ fontFamily: KAYFIT_FONTS.mono, fontSize: 11, color: t.fgDim }}>{s}</span>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>

      <div style={{ borderTop: `1px solid ${t.hairline}`, padding: '8px 12px 12px' }}>
        <div style={{ display: 'flex', gap: 6, marginBottom: 8, paddingLeft: 4 }}>
          {[
            { k: 'photo', icon: 'camera' },
            { k: 'voice', icon: 'mic' },
            { k: 'barcode', icon: 'barcode' },
          ].map(b => (
            <button key={b.k} onClick={() => onAttach(b.k)}
              style={{
                width: 34, height: 34, borderRadius: '50%', border: `1px solid ${t.border}`,
                background: 'transparent', color: t.fg, cursor: 'pointer',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
              }}>
              <Icon name={b.icon} size={15}/>
            </button>
          ))}
        </div>
        <div style={{
          display: 'flex', alignItems: 'center', gap: 8,
          border: `1px solid ${t.border}`, borderRadius: 22, padding: '4px 4px 4px 14px',
          background: t.surface,
        }}>
          <input
            value={draft}
            onChange={e => setDraft(e.target.value)}
            onKeyDown={e => {
              if (e.key === 'Enter' && draft.trim()) {
                onSend(draft.trim()); setDraft('');
              }
            }}
            placeholder="ask or describe what you ate"
            style={{
              flex: 1, border: 'none', outline: 'none', background: 'transparent',
              fontFamily: 'inherit', fontSize: 14, color: t.fg, padding: '8px 0',
            }}/>
          <button onClick={() => { if (draft.trim()) { onSend(draft.trim()); setDraft(''); } }}
            style={{
              width: 32, height: 32, borderRadius: '50%',
              background: draft.trim() ? t.fg : t.border, color: t.accentFg, border: 'none',
              cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center',
            }}>
            <Icon name="send" size={14} color={draft.trim() ? t.accentFg : t.fgDim} strokeWidth={2}/>
          </button>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Main Kayfit shell — wires everything together
// Variants control: theme (light/dark), summary style, addLayout, journal density
// ─────────────────────────────────────────────────────────────
function KayfitApp({
  variant = 'v1',
  dark = false,
  summaryStyle = 'ring',
  addLayout = 'grid', // grid | list
  defaultCalendarExpanded = false,
  startTab = 'journal',
  initialMeals,
}) {
  const t = getTheme(dark);
  const [tab, setTab] = React.useState(startTab);
  const [meals, setMeals] = React.useState(initialMeals || SEED_TODAY);
  const [chat, setChat] = React.useState(SEED_CHAT);
  const [thinking, setThinking] = React.useState(null);
  const [overlay, setOverlay] = React.useState(null); // 'add' | 'account' | { recognize: 'photo'|... }
  const [calendarExpanded, setCalendarExpanded] = React.useState(defaultCalendarExpanded);
  const [selectedDate, setSelectedDate] = React.useState('today');
  const [mealDetail, setMealDetail] = React.useState(null);

  const handleSave = (m) => {
    setMeals([...meals, {
      id: 'm' + Date.now(),
      time: new Date().toTimeString().slice(0,5),
      ...m,
    }]);
    setOverlay(null);
  };

  const handleSend = (text) => {
    const newMsgs = [...chat, { id: 'u' + Date.now(), from: 'user', text }];
    setChat(newMsgs);
    const steps = [
      'parsing your message',
      'searching nutrition database',
      'estimating portion size',
      'composing reply',
    ];
    let i = 0;
    setThinking({ steps: [steps[0]], done: false });
    const tick = setInterval(() => {
      i++;
      if (i < steps.length) {
        setThinking(prev => prev ? { ...prev, steps: [...prev.steps, steps[i]] } : prev);
      } else {
        clearInterval(tick);
        setThinking(prev => prev ? { ...prev, done: true } : prev);
        setTimeout(() => {
          setThinking(null);
          setChat([...newMsgs, {
            id: 'a' + Date.now(), from: 'ai',
            text: 'Got it. Want me to add this to your journal?'
          }]);
        }, 280);
      }
    }, 550);
  };

  const handleChatAttach = (method) => {
    setOverlay({ recognize: method, fromChat: true });
  };

  return (
    <div style={{ position: 'relative', height: '100%', overflow: 'hidden', background: t.bg, display: 'flex', flexDirection: 'column' }}>
      <div style={{ flex: 1, minHeight: 0, position: 'relative', overflow: 'hidden' }}>
      {tab === 'journal' && (
        <JournalScreen
          t={t} meals={meals}
          summaryStyle={summaryStyle}
          onMealTap={setMealDetail}
          onAccount={() => setOverlay('account')}
          calendarExpanded={calendarExpanded}
          setCalendarExpanded={setCalendarExpanded}
          selectedDate={selectedDate}
          setSelectedDate={setSelectedDate}
          groupBy="type"
        />
      )}
      {tab === 'chat' && (
        <ChatScreen
          t={t} messages={chat}
          thinking={thinking}
          onSend={handleSend}
          onAccount={() => setOverlay('account')}
          onAttach={handleChatAttach}
        />
      )}
      </div>

      {/* Bottom tab bar — hidden when fullscreen overlay is showing */}
      {!(overlay && overlay.recognize) && (
        <TabBar t={t} active={tab} onTab={setTab} onAdd={() => setTab('chat')}/>
      )}

      {/* Add sheet */}
      {overlay === 'add' && (
        <Backdrop onClose={() => setOverlay(null)}>
          <AddSheet t={t} layout={addLayout}
            onPick={k => setOverlay({ recognize: k })}
            onClose={() => setOverlay(null)}/>
        </Backdrop>
      )}

      {/* Account sheet */}
      {overlay === 'account' && (
        <Backdrop onClose={() => setOverlay(null)}>
          <AccountSheet t={t} onClose={() => setOverlay(null)}/>
        </Backdrop>
      )}

      {/* Recognition fullscreen */}
      {overlay && overlay.recognize && (
        <div style={{ position: 'absolute', inset: 0, background: t.bg, zIndex: 50 }}>
          <RecognitionScreen
            t={t} method={overlay.recognize}
            onCancel={() => setOverlay(null)}
            onSave={(m) => {
              if (overlay.fromChat) {
                setChat([...chat,
                  { id: 'u' + Date.now(), from: 'user', text: `logged ${m.name}`, attachment: { icon: overlay.recognize === 'photo' ? 'camera' : overlay.recognize === 'voice' ? 'mic' : 'barcode', label: `${m.kcal} kcal` } },
                  { id: 'a' + Date.now()+1, from: 'ai', text: `Added — ${m.kcal} kcal, ${m.p}g protein.` },
                ]);
              }
              handleSave(m);
            }}/>
        </div>
      )}

      {/* Meal detail */}
      {mealDetail && (
        <Backdrop onClose={() => setMealDetail(null)}>
          <MealDetailSheet t={t} meal={mealDetail} onClose={() => setMealDetail(null)} onDelete={() => {
            setMeals(meals.filter(m => m.id !== mealDetail.id));
            setMealDetail(null);
          }}/>
        </Backdrop>
      )}
    </div>
  );
}

function Backdrop({ children, onClose }) {
  return (
    <div onClick={onClose} style={{
      position: 'absolute', inset: 0, background: 'rgba(0,0,0,0.4)', zIndex: 40,
      display: 'flex', flexDirection: 'column', justifyContent: 'flex-end',
    }}>
      <div onClick={e => e.stopPropagation()}>{children}</div>
    </div>
  );
}

function MealDetailSheet({ t, meal, onClose, onDelete }) {
  return (
    <div style={{ background: t.surface, borderTopLeftRadius: 24, borderTopRightRadius: 24, overflow: 'hidden' }}>
      <div style={{ padding: '12px 16px 0', display: 'flex', justifyContent: 'center' }}>
        <div style={{ width: 36, height: 4, background: t.border, borderRadius: 2 }}/>
      </div>
      <div style={{ padding: '16px 20px 8px', display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
        <div style={{ fontSize: 11, color: t.fgDim, textTransform: 'uppercase', letterSpacing: 1 }}>{meal.type} · {meal.time}</div>
        <button onClick={onClose} style={{ background: 'transparent', border: 'none', cursor: 'pointer', color: t.fgDim, padding: 4 }}>
          <Icon name="close" size={18}/>
        </button>
      </div>
      <div style={{ padding: '4px 20px 20px' }}>
        <div style={{ fontSize: 17, color: t.fg, fontWeight: 500, lineHeight: 1.3, marginBottom: 16 }}>{meal.name}</div>
        <div style={{ display: 'flex', alignItems: 'baseline', gap: 8, marginBottom: 16 }}>
          <div style={{ fontFamily: KAYFIT_FONTS.mono, fontSize: 44, fontWeight: 500, color: t.fg, letterSpacing: -1.5, lineHeight: 1 }}>{meal.kcal}</div>
          <div style={{ fontSize: 12, color: t.fgDim, textTransform: 'uppercase' }}>kcal</div>
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr 1fr', gap: 0, borderTop: `1px solid ${t.hairline}`, borderBottom: `1px solid ${t.hairline}`, padding: '12px 0' }}>
          {[['Protein', meal.p], ['Fat', meal.f], ['Carbs', meal.c]].map(([l, v]) => (
            <div key={l}>
              <div style={{ fontSize: 10, color: t.fgMute, textTransform: 'uppercase', letterSpacing: 1 }}>{l}</div>
              <div style={{ fontFamily: KAYFIT_FONTS.mono, fontSize: 18, color: t.fg, marginTop: 2 }}>{v}<span style={{ fontSize: 11, color: t.fgMute }}>g</span></div>
            </div>
          ))}
        </div>
        <div style={{ display: 'flex', gap: 8, marginTop: 16 }}>
          <button style={{
            flex: 1, padding: '12px', border: `1px solid ${t.border}`, borderRadius: 8,
            background: 'transparent', color: t.fg, fontFamily: 'inherit', fontSize: 13, cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
          }}>
            <Icon name="edit" size={14}/> edit
          </button>
          <button onClick={onDelete} style={{
            flex: 1, padding: '12px', border: `1px solid ${t.border}`, borderRadius: 8,
            background: 'transparent', color: t.fg, fontFamily: 'inherit', fontSize: 13, cursor: 'pointer',
            display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
          }}>
            <Icon name="trash" size={14}/> delete
          </button>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { JournalScreen, ChatScreen, KayfitApp, MealDetailSheet, Backdrop });
