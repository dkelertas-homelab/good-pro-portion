const fs = require('fs');
const path = require('path');
const { figures } = require('./figures');

const SRC = __dirname;
const css = fs.readFileSync(path.join(SRC, 'shared.css'), 'utf8');

const DARK_CSS = `
:root {
  --bg: #0F1218;
  --surface: #1A1F2A;
  --surface-2: #252B38;
  --text: #F3F4F6;
  --text-2: #A0A8B5;
  --text-3: #6B7280;
  --accent: #FF6B4A;
  --accent-soft: #3A221C;
  --accent-dark: #FF8A70;
  --ad: #1F2530;
  --ad-border: #3A4250;
  --danger: #FB7185;
}
.nav-pill { background: #F3F4F6; opacity: 0.4; }
.card { border-color: rgba(255,255,255,0.04); box-shadow: 0 2px 8px rgba(0,0,0,0.25); }
.btn.secondary { background: var(--surface-2); color: var(--text); }
.btn.ghost { border-color: #4A2E28; color: var(--accent); }
.example-tag { background: #3A2E14; color: #FBBF24; }
`;

function page(body, extraCss = '') {
  return `<!DOCTYPE html>
<html><head><meta charset="utf-8"/>
<style>${css}${extraCss}</style>
</head><body>${body}</body></html>`;
}

function statusBar(time = '6:30') {
  return `<div class="status-bar"><span>${time}</span><span class="status-icons">▮▮▮  LTE  🔋</span></div>`;
}
function nav() { return `<div class="nav-bar"><div class="nav-pill"></div></div>`; }
function example() { return `<div class="example-tag">EXAMPLE MOCKUP</div>`; }
function ad(label = 'Ad · placeholder') {
  return `<div class="ad-banner">${label}</div>`;
}

function buildAll(theme /* 'teal' | 'coral' */) {
  const F = (name, size) => figures[name](size, theme);
  const isDark = theme === 'coral';
  const extra = isDark ? DARK_CSS : '';
  const chipLabel = isDark ? 'Good Pro Portion · dark' : 'Good Pro Portion';
  const ringAccent = isDark ? '#FF6B4A' : '#0D9488';
  const ringTrack = isDark ? '#252B38' : '#E5E7EB';
  const ringText = isDark ? '#F3F4F6' : '#1A1D23';
  const ringSub = isDark ? '#A0A8B5' : '#5C6570';
  const restRing = isDark ? '#FF8A70' : '#F59E0B';
  const restFigBg = isDark ? '#3A221C' : '#FEF3C7';
  const mistakeBg = isDark ? '#3A1A22' : '#FEF2F2';
  const mistakeBorder = isDark ? '#7F1D1D' : '#FECACA';
  const mistakeTitle = isDark ? '#FDA4AF' : '#B91C1C';
  const mistakeText = isDark ? '#FECDD3' : '#7F1D1D';

  const screens = {};

  screens['01-home'] = page(`
<div class="phone">
  ${statusBar()}
  ${example()}
  <div class="content" style="gap:18px;">
    <div>
      <div class="chip">${chipLabel}</div>
      <h1 style="margin-top:10px;">G'day — ready for a quick one?</h1>
      <p class="sub" style="margin-top:6px;">Short home sessions. No gear. No fuss.</p>
    </div>
    <div class="section-label">Pick a routine</div>
    <div class="card" style="display:flex;gap:14px;align-items:center;">
      <div class="thumb">${F('squat', 40)}</div>
      <div class="spacer">
        <h3>Day A · Quiet morning</h3>
        <p class="muted">~9 min · legs, push, core</p>
      </div>
      <span style="color:var(--accent);font-size:22px;">›</span>
    </div>
    <div class="card" style="display:flex;gap:14px;align-items:center;">
      <div class="thumb">${F('splitSquat', 40)}</div>
      <div class="spacer">
        <h3>Day B · Quiet morning</h3>
        <p class="muted">~9 min · single-leg, back, core</p>
      </div>
      <span style="color:var(--accent);font-size:22px;">›</span>
    </div>
    <div class="card disabled" style="display:flex;gap:14px;align-items:center;">
      <div class="thumb">${F('birdDog', 40)}</div>
      <div class="spacer">
        <h3>More routines</h3>
        <p class="muted">Coming soon — example placeholder</p>
      </div>
      <span class="badge">Soon</span>
    </div>
    <div class="spacer"></div>
    <div style="display:flex;gap:12px;">
      <div class="card" style="flex:1;text-align:center;padding:14px;">
        <div style="font-size:22px;font-weight:800;color:var(--accent);">3</div>
        <div class="muted">day streak</div>
      </div>
      <div class="card" style="flex:1;text-align:center;padding:14px;">
        <div style="font-size:22px;font-weight:800;color:var(--accent);">12</div>
        <div class="muted">sessions</div>
      </div>
    </div>
  </div>
  ${ad()}
  ${nav()}
</div>`, extra);

  screens['02-routine'] = page(`
<div class="phone">
  ${statusBar()}
  ${example()}
  <div class="content" style="gap:6px;padding-bottom:0;flex:1;overflow:hidden;">
    <div class="row">
      <span style="font-size:22px;color:var(--text-2);">‹</span>
      <div class="spacer">
        <h2>Day A</h2>
        <p class="muted">Quiet morning · ~9 min · example</p>
      </div>
      <span class="chip">No cool-down</span>
    </div>
    <div class="card" style="padding:8px 12px;background:var(--accent-soft);border:none;box-shadow:none;">
      <div class="row"><strong style="color:var(--accent-dark);font-size:13px;">Warm-up · 2 min</strong><span class="spacer"></span><span class="muted">30s each</span></div>
    </div>
    ${[
      ['march','March on the spot'],
      ['armCircles','Arm circles (text only)'],
      ['goodMorning','Good mornings'],
      ['squat','Slow squats'],
    ].map(([k,n]) => `
      <div class="list-item" style="padding:3px 0;border:none;">
        <div class="thumb" style="width:36px;height:36px;border-radius:10px;">${F(k, 30)}</div>
        <div class="spacer"><h3 style="font-size:13px;">${n}</h3></div>
        <span class="muted">30s</span>
      </div>`).join('')}
    <div class="card" style="padding:8px 12px;background:var(--accent-soft);border:none;box-shadow:none;margin-top:2px;">
      <div class="row"><strong style="color:var(--accent-dark);font-size:13px;">Work · 7 moves</strong><span class="spacer"></span><span class="muted">40s / 20s</span></div>
    </div>
    ${[
      ['squat','Squats'],
      ['pushup','Push-ups'],
      ['reverseLunge','Reverse lunges'],
      ['plank','Plank'],
      ['squat','Squats'],
      ['pushup','Push-ups'],
      ['gluteBridge','Glute bridges'],
    ].map(([k,n],i) => `
      <div class="list-item" style="padding:2px 0;border:none;">
        <div class="thumb" style="width:34px;height:34px;border-radius:10px;">${F(k, 28)}</div>
        <div class="spacer"><h3 style="font-size:13px;">${i+1}. ${n}</h3></div>
        <span class="muted">40s</span>
      </div>`).join('')}
  </div>
  <div style="padding:10px 20px 4px;flex-shrink:0;background:var(--bg);">
    <button class="btn">Start · ~9 min</button>
  </div>
  ${nav()}
</div>`, extra + `\n.list-item { border-bottom: none !important; }\n`);

  screens['03-exercise'] = page(`
<div class="phone">
  ${statusBar()}
  ${example()}
  <div class="content" style="gap:12px;">
    <div class="row">
      <span style="font-size:22px;color:var(--text-2);">‹</span>
      <div class="spacer"><h2>Squat</h2></div>
      <span class="chip">Move 1/7</span>
    </div>
    <div class="figure-wrap" style="height:240px;">${F('squat', 200)}</div>
    <div>
      <div class="section-label">How to</div>
      <p class="sub">Feet about shoulder-width. Sit your hips back like you're sitting on a stool. Knees track over toes. Stand up tall.</p>
    </div>
    <div class="card" style="background:${mistakeBg};border-color:${mistakeBorder};">
      <div class="section-label" style="color:${mistakeTitle};">Common mistakes</div>
      <p class="sub" style="color:${mistakeText};">Knees caving in · rounding the lower back · heels lifting off the floor</p>
    </div>
    <div style="display:flex;gap:10px;">
      <div class="card" style="flex:1;padding:12px;">
        <div class="badge">Easier</div>
        <p class="sub" style="margin-top:6px;font-size:13px;">Shallower squat, or hold a chair</p>
      </div>
      <div class="card" style="flex:1;padding:12px;">
        <div class="badge">Harder</div>
        <p class="sub" style="margin-top:6px;font-size:13px;">Go lower, pause at the bottom</p>
      </div>
    </div>
  </div>
  ${nav()}
</div>`, extra);

  screens['04-timer-work'] = page(`
<div class="phone">
  ${statusBar('6:32')}
  ${example()}
  <div class="content" style="gap:10px;align-items:center;">
    <div class="row" style="width:100%;">
      <span class="chip">Work</span>
      <span class="spacer"></span>
      <span class="muted">Move 1 of 7</span>
    </div>
    <h2 style="align-self:flex-start;">Squats</h2>
    <div class="figure-wrap" style="width:100%;height:220px;">${F('squat', 180)}</div>
    <div class="ring-wrap">
      <svg width="180" height="180" viewBox="0 0 180 180">
        <circle cx="90" cy="90" r="78" fill="none" stroke="${ringTrack}" stroke-width="12"/>
        <circle cx="90" cy="90" r="78" fill="none" stroke="${ringAccent}" stroke-width="12"
          stroke-linecap="round" stroke-dasharray="490" stroke-dashoffset="120"
          transform="rotate(-90 90 90)"/>
        <text x="90" y="82" text-anchor="middle" font-size="48" font-weight="800" fill="${ringText}" font-family="Inter,sans-serif">28</text>
        <text x="90" y="110" text-anchor="middle" font-size="14" font-weight="600" fill="${ringSub}" font-family="Inter,sans-serif">seconds</text>
      </svg>
    </div>
    <div class="card" style="width:100%;padding:12px 14px;">
      <div class="row">
        <div class="thumb" style="width:40px;height:40px;">${F('pushup', 32)}</div>
        <div><div class="muted">Next up</div><strong>Push-ups</strong></div>
      </div>
    </div>
    <div class="row" style="width:100%;gap:12px;">
      <button class="btn secondary" style="flex:1;height:48px;font-size:15px;">Pause</button>
      <button class="btn ghost" style="flex:1;height:48px;font-size:15px;">Skip ›</button>
    </div>
    <p class="muted" style="text-align:center;">No ads during the timer</p>
  </div>
  ${nav()}
</div>`, extra);

  // Rest: show NEXT move (push-up) start pose clearly
  screens['05-timer-rest'] = page(`
<div class="phone">
  ${statusBar('6:33')}
  ${example()}
  <div class="content" style="gap:10px;align-items:center;">
    <div class="row" style="width:100%;">
      <span class="chip" style="background:${isDark ? '#3A2E14' : '#FEF3C7'};color:${isDark ? '#FBBF24' : '#92400E'};">Rest</span>
      <span class="spacer"></span>
      <span class="muted">Between moves</span>
    </div>
    <h2 style="align-self:flex-start;">Catch your breath</h2>
    <div class="figure-wrap" style="width:100%;height:200px;background:${restFigBg};">
      ${F('pushup', 170)}
    </div>
    <div class="ring-wrap">
      <svg width="170" height="170" viewBox="0 0 180 180">
        <circle cx="90" cy="90" r="78" fill="none" stroke="${ringTrack}" stroke-width="12"/>
        <circle cx="90" cy="90" r="78" fill="none" stroke="${restRing}" stroke-width="12"
          stroke-linecap="round" stroke-dasharray="490" stroke-dashoffset="245"
          transform="rotate(-90 90 90)"/>
        <text x="90" y="82" text-anchor="middle" font-size="48" font-weight="800" fill="${ringText}" font-family="Inter,sans-serif">12</text>
        <text x="90" y="110" text-anchor="middle" font-size="14" font-weight="600" fill="${ringSub}" font-family="Inter,sans-serif">rest</text>
      </svg>
    </div>
    <div class="card" style="width:100%;padding:14px;text-align:center;background:var(--accent-soft);border:none;">
      <div class="muted">Next</div>
      <h2 style="color:var(--accent-dark);margin-top:2px;">Push-ups</h2>
      <p class="muted" style="margin-top:4px;">Get ready in the start position</p>
    </div>
    <div class="row" style="width:100%;gap:12px;">
      <button class="btn secondary" style="flex:1;height:48px;font-size:15px;">Pause</button>
      <button class="btn ghost" style="flex:1;height:48px;font-size:15px;">Skip ›</button>
    </div>
  </div>
  ${nav()}
</div>`, extra);

  screens['06-done'] = page(`
<div class="phone">
  ${statusBar('6:40')}
  ${example()}
  <div class="content" style="gap:14px;">
    <div style="text-align:center;padding-top:8px;">
      <div style="font-size:48px;color:var(--accent);">✓</div>
      <h1 style="margin-top:4px;">Nice one!</h1>
      <p class="sub">Day A sorted. Example session done.</p>
    </div>
    <div style="display:flex;gap:10px;">
      <div class="card" style="flex:1;text-align:center;">
        <div style="font-size:24px;font-weight:800;color:var(--accent);">8:52</div>
        <div class="muted">time</div>
      </div>
      <div class="card" style="flex:1;text-align:center;">
        <div style="font-size:24px;font-weight:800;color:var(--accent);">🔥 4</div>
        <div class="muted">day streak</div>
      </div>
    </div>
    <div class="section-label">Meal idea · eat simple</div>
    <div class="card" style="padding:14px;">
      <div class="row" style="align-items:flex-start;">
        <div style="font-size:32px;line-height:1;">🥗</div>
        <div class="spacer">
          <h3>Woolies premade salad + ¼ roast chook</h3>
          <p class="sub" style="margin-top:4px;">Grab-and-go lunch. Example only — not a diet plan.</p>
          <div style="margin-top:10px;padding:10px;background:var(--surface-2);border-radius:10px;">
            <div class="section-label" style="margin-bottom:6px;">Portion guide</div>
            <div style="display:grid;grid-template-columns:1fr 1fr;gap:6px;font-size:12px;color:var(--text-2);">
              <div>✋ palm protein</div>
              <div>✊ fist of veg</div>
              <div>🤲 cupped carbs</div>
              <div>👍 thumb of fat</div>
            </div>
            <p class="muted" style="margin-top:6px;">Quarter chicken, not the whole bird · half the plate veg</p>
          </div>
        </div>
      </div>
    </div>
    <button class="btn secondary" style="height:48px;font-size:15px;">More meal ideas</button>
  </div>
  ${ad('Ad · placeholder (post-workout)')}
  ${nav()}
</div>`, extra);

  screens['07-meals'] = page(`
<div class="phone">
  ${statusBar()}
  ${example()}
  <div class="content" style="gap:12px;">
    <div class="row">
      <span style="font-size:22px;color:var(--text-2);">‹</span>
      <div class="spacer">
        <h2>Meal ideas</h2>
        <p class="muted">Eat simple · portion control · not a diet</p>
      </div>
    </div>
    <div class="card" style="background:var(--accent-soft);border:none;box-shadow:none;padding:12px;">
      <p class="sub" style="color:var(--accent-dark);font-size:13px;">No calorie counting. Just sensible hand portions. Examples only.</p>
    </div>
    ${[
      ['🐟','Steamed fish + 3 veg','Palm of fish · fist ×3 veg · thumb oil'],
      ['🍳','Eggs on toast','2 eggs (palm) · 1–2 toast · fist greens'],
      ['🥗','Salad + roast chicken','Woolies salad + ¼–½ chook'],
      ['🍚','Rice bowl + leftovers','Cupped rice · palm protein · fist veg'],
      ['🥣','Greek yoghurt + fruit','Cupped yoghurt · fist berries · thumb nuts'],
    ].map(([emoji,title,guide]) => `
      <div class="card" style="padding:12px 14px;">
        <div class="row" style="align-items:flex-start;">
          <div style="font-size:26px;">${emoji}</div>
          <div class="spacer">
            <h3>${title}</h3>
            <p class="muted" style="margin-top:4px;">${guide}</p>
          </div>
        </div>
      </div>`).join('')}
  </div>
  ${nav()}
</div>`, extra);

  const toggleOn = `<div style="width:44px;height:26px;background:var(--accent);border-radius:13px;position:relative;flex-shrink:0;">
          <div style="width:22px;height:22px;background:white;border-radius:50%;position:absolute;right:2px;top:2px;"></div>
        </div>`;

  screens['08-settings'] = page(`
<div class="phone">
  ${statusBar()}
  ${example()}
  <div class="content" style="gap:10px;">
    <h1>Settings</h1>
    <div class="section-label">Timer</div>
    <div class="card" style="padding:0;">
      <div class="list-item" style="padding:12px 14px;">
        <div class="spacer"><h3>Work length</h3><p class="muted">Example default</p></div>
        <strong style="color:var(--accent);">40s</strong>
      </div>
      <div class="list-item" style="padding:12px 14px;">
        <div class="spacer"><h3>Rest length</h3></div>
        <strong style="color:var(--accent);">20s</strong>
      </div>
    </div>
    <div class="section-label">Reminders</div>
    <div class="card" style="padding:0;">
      <div class="list-item" style="padding:12px 14px;">
        <div class="spacer"><h3>Workout reminders</h3><p class="muted">Mon–Fri · 6:30am · example</p></div>
        ${toggleOn}
      </div>
      <div class="list-item" style="padding:12px 14px;">
        <div class="spacer"><h3>Days & time</h3><p class="muted">Change schedule</p></div>
        <span style="color:var(--text-3);">›</span>
      </div>
      <div class="list-item" style="padding:12px 14px;">
        <div class="spacer">
          <h3>Also add to my Clock app</h3>
          <p class="muted">Opens Clock with an alarm pre-filled (example)</p>
        </div>
        <span style="color:var(--accent);font-size:18px;">🕐</span>
      </div>
    </div>
    <div class="section-label">Feedback</div>
    <div class="card" style="padding:0;">
      <div class="list-item" style="padding:12px 14px;">
        <div class="spacer"><h3>Sound</h3></div>
        ${toggleOn}
      </div>
      <div class="list-item" style="padding:12px 14px;">
        <div class="spacer"><h3>Vibration</h3></div>
        ${toggleOn}
      </div>
    </div>
    <div class="section-label">Upgrade</div>
    <div class="card" style="padding:12px 14px;display:flex;align-items:center;gap:12px;">
      <div style="font-size:22px;">✨</div>
      <div class="spacer">
        <h3>Remove ads</h3>
        <p class="muted">One-off · no subscription</p>
      </div>
      <strong style="color:var(--accent);">A$X.XX</strong>
    </div>
    <div class="section-label">Legal</div>
    <div class="card" style="padding:0;">
      <div class="list-item" style="padding:12px 14px;">
        <div class="spacer"><h3>Privacy policy</h3></div>
        <span style="color:var(--text-3);">›</span>
      </div>
      <div class="list-item" style="padding:12px 14px;">
        <div class="spacer">
          <h3>Health disclaimer</h3>
          <p class="muted" style="margin-top:2px;">Check with a doctor. Stop if pain. Example.</p>
        </div>
      </div>
    </div>
  </div>
  ${nav()}
</div>`, extra);

  screens['09-remove-ads'] = page(`
<div class="phone" style="background:${isDark ? 'rgba(0,0,0,0.55)' : 'rgba(26,29,35,0.45)'};">
  ${statusBar()}
  <div style="flex:1;display:flex;align-items:flex-end;">
    <div style="background:var(--surface);border-radius:24px 24px 0 0;padding:24px 20px 16px;width:100%;">
      <div style="width:40px;height:4px;background:${isDark ? '#3A4250' : '#D1D5DB'};border-radius:2px;margin:0 auto 18px;"></div>
      <div class="example-tag" style="position:static;display:inline-block;margin-bottom:12px;">EXAMPLE MOCKUP</div>
      <h1 style="font-size:24px;">Remove ads</h1>
      <p class="sub" style="margin-top:8px;">One-off purchase. No subscription. No weekly tricks.</p>
      <div class="card" style="margin:18px 0;padding:18px;background:var(--accent-soft);border:none;box-shadow:none;">
        <div class="row">
          <div>
            <h3 style="color:var(--accent-dark);">Good Pro Portion · Ad-free</h3>
            <p class="muted" style="margin-top:4px;">Unlock once, keep forever on this Google account</p>
          </div>
        </div>
        <div style="margin-top:14px;font-size:32px;font-weight:800;color:var(--accent-dark);">A$X.XX</div>
        <p class="muted">placeholder price · one-off</p>
      </div>
      <ul style="list-style:none;display:flex;flex-direction:column;gap:10px;margin-bottom:20px;">
        <li class="row"><span style="color:var(--accent);font-weight:700;">✓</span><span class="sub">No banner ads</span></li>
        <li class="row"><span style="color:var(--accent);font-weight:700;">✓</span><span class="sub">No post-workout ad slot</span></li>
        <li class="row"><span style="color:var(--accent);font-weight:700;">✓</span><span class="sub">Same workouts, same meal ideas</span></li>
      </ul>
      <button class="btn">Buy once · A$X.XX</button>
      <button class="btn ghost" style="margin-top:10px;height:48px;font-size:15px;">Restore purchase</button>
      <p class="muted" style="text-align:center;margin-top:12px;margin-bottom:8px;">Pay once. No subscription, ever.</p>
    </div>
  </div>
  ${nav()}
</div>`, extra);

  // Day chips helper
  const days = ['M','T','W','T','F','S','S'];
  const dayChips = days.map((d,i) => {
    const on = i < 5; // Mon-Fri selected
    return `<div style="width:36px;height:36px;border-radius:18px;display:flex;align-items:center;justify-content:center;font-size:13px;font-weight:700;
      background:${on ? 'var(--accent)' : 'var(--surface-2)'};color:${on ? '#fff' : 'var(--text-2)'};">${d}</div>`;
  }).join('');

  screens['10-reminders-setup'] = page(`
<div class="phone">
  ${statusBar()}
  ${example()}
  <div class="content" style="gap:14px;">
    <div>
      <div class="chip">Optional</div>
      <h1 style="margin-top:10px;font-size:24px;">When suits you for a quick session?</h1>
      <p class="sub" style="margin-top:6px;">Totally optional — skip anytime. Not a quiz.</p>
    </div>
    <div class="section-label">Days</div>
    <div class="row" style="justify-content:space-between;">${dayChips}</div>
    <div class="section-label">Time</div>
    <div class="card" style="padding:14px;display:flex;align-items:center;gap:12px;">
      <div style="font-size:28px;font-weight:800;color:var(--accent);">6:30</div>
      <div class="spacer">
        <h3>am</h3>
        <p class="muted">Example slot</p>
      </div>
      <span class="badge">Edit</span>
    </div>
    <div class="section-label">Presets</div>
    <div style="display:flex;gap:8px;flex-wrap:wrap;">
      <span class="chip">Early morning</span>
      <span class="chip" style="background:var(--surface-2);color:var(--text-2);">Lunch</span>
      <span class="chip" style="background:var(--surface-2);color:var(--text-2);">Evening</span>
    </div>
    <div class="card" style="background:var(--accent-soft);border:none;box-shadow:none;padding:12px;">
      <p class="sub" style="color:var(--accent-dark);font-size:13px;">Your phone will ask permission for notifications. You can change this later in Settings.</p>
    </div>
    <div class="spacer"></div>
    <button class="btn">Set reminders</button>
    <button class="btn ghost" style="height:48px;font-size:15px;">Skip for now</button>
  </div>
  ${nav()}
</div>`, extra);

  // Notification / lock screen mock
  const notifBg = isDark ? '#0A0C10' : '#1A1D23';
  const notifCard = isDark ? '#1A1F2A' : '#2A2F3A';
  screens['11-reminder-notification'] = page(`
<div class="phone" style="background:${notifBg};">
  <div style="padding:48px 24px 0;color:#fff;text-align:center;">
    <div style="font-size:14px;opacity:0.7;letter-spacing:1px;">THURSDAY 24 SEP</div>
    <div style="font-size:72px;font-weight:200;letter-spacing:-2px;line-height:1.1;margin-top:4px;">6:30</div>
  </div>
  <div class="example-tag" style="position:absolute;top:12px;right:16px;">EXAMPLE MOCKUP</div>
  <div style="padding:28px 16px 0;">
    <div style="background:${notifCard};border-radius:20px;padding:14px 16px;color:#F3F4F6;box-shadow:0 8px 24px rgba(0,0,0,0.35);">
      <div class="row" style="gap:10px;margin-bottom:8px;">
        <div style="width:28px;height:28px;border-radius:8px;background:var(--accent);display:flex;align-items:center;justify-content:center;font-size:14px;">💪</div>
        <div class="spacer">
          <div style="font-size:12px;font-weight:700;opacity:0.85;letter-spacing:0.3px;">GOOD PRO PORTION</div>
          <div style="font-size:11px;opacity:0.5;">now</div>
        </div>
      </div>
      <div style="font-size:16px;font-weight:700;line-height:1.3;">Day B is up. 9 minutes, no gear.</div>
      <div style="font-size:13px;opacity:0.65;margin-top:4px;">Quiet morning · sleeping-kid friendly</div>
      <div style="display:flex;gap:8px;margin-top:14px;">
        <div style="flex:1;text-align:center;padding:10px;border-radius:12px;background:rgba(255,255,255,0.08);font-size:13px;font-weight:700;">Snooze 15 min</div>
        <div style="flex:1;text-align:center;padding:10px;border-radius:12px;background:var(--accent);color:#fff;font-size:13px;font-weight:700;">Start</div>
      </div>
    </div>
  </div>
  <div style="flex:1;"></div>
  <div style="padding:20px;text-align:center;color:rgba(255,255,255,0.35);font-size:12px;">Lock screen · example notification</div>
  ${nav()}
</div>`, extra + `
.phone { background: ${notifBg} !important; }
.nav-pill { background: #fff; opacity: 0.35; }
`);


  return screens;
}

// Write light (teal) as 01-… and dark (coral) as dark-01-…
const light = buildAll('teal');
const dark = buildAll('coral');
const names = Object.keys(light);
for (const name of names) {
  fs.writeFileSync(path.join(SRC, `${name}.html`), light[name]);
  fs.writeFileSync(path.join(SRC, `dark-${name}.html`), dark[name]);
  console.log('wrote', name, '+ dark-' + name);
}
// Keep alt-style aliases pointing at dark home/timer for backwards compat
fs.writeFileSync(path.join(SRC, 'alt-style-home.html'), dark['01-home']);
fs.writeFileSync(path.join(SRC, 'alt-style-timer.html'), dark['04-timer-work']);
fs.writeFileSync(path.join(SRC, 'screens.json'), JSON.stringify({
  light: names,
  dark: names.map(n => 'dark-' + n),
}, null, 2));
console.log('done', names.length, '×2 themes');
