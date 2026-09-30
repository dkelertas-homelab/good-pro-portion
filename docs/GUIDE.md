# Nice Pro Portions — product & coding guide

Every new feature should fit this guide. Keep it short, friendly, and easy to follow.

## Principles

- **Simple and free.** Short home bodyweight sessions. No accounts, no subscriptions, no quiz funnels.
- **Offline-first.** Everything works without a network. User data stays on the phone.
- **No guilt.** No streak shaming, no calorie counting, no before/after or "goal" bodies.
- **Body shapes are neutral.** Slim / average / larger are user-picked and treated the same — just different parameters, never judgment.
- **Stick figures by default.** Drawn in code, parameterised so one animation works for every body shape. About five key poses per move, blended smoothly so the move is easy to recognise mid-set.

## Tips and prompts

This is the main rule for anything that wants the user's attention.

- **Nothing on first install / first launch.** The user goes straight into their first workout.
  One exception: a short, warm "before you start" note may appear when a workout is started,
  until the user chooses "Don't show this again". It must never block starting, and it is never
  shown during a workout or rest timer. It can be switched back on in Settings → Tips.
- **At most one tip or prompt per app session.**
- **Never during a workout or rest timer.**
- **Each tip is shown once.** Dismissing means never again (unless they replay it).
- **All tips are replayable** from a Tips list in Settings.
- Prefer **inline, dismissible hints** over modal pop-ups. Use system dialogs only where Android requires them (e.g. pin shortcut, notification permission).
- Track progress with a simple local counter of completed workouts and app opens.

### Starting schedule

Easy to adjust later. New features that need a tip slot into this table — do not add a first-launch pop-up.

| When | Tip |
|------|-----|
| After workout 1 completes | Offer a home-screen "Start today's workout" shortcut (Android's own pin dialog) |
| After workout 2 | Offer an exercise-time reminder; only then ask for notification permission (Android 13+). Never at launch |
| App open 3 | Inline hint that long-pressing the app icon gives quick options (Start Quiet morning A, 3-minute mode) |
| Around workout 5, or first full week | Offer the weekly-dots home-screen widget |
| Return after a few days away | Hint about 3-minute mode — framed as welcome back, never as a missed-days reminder |
| Occasional (not every workout) | One-tap "how did that feel?" rating on the done screen |

## Tone of copy

Short, warm, encouraging. Never nagging or guilt-tripping.

| Good | Bad |
|------|-----|
| "Nice one — Quiet morning A done." | "You broke your streak!" |
| "Welcome back. Fancy the 3-minute version?" | "You've been away for 4 days." |
| "How did that feel?" | "Did you give it your all?" |
| "Pin Start today's workout to your home screen?" | "Don't forget to work out every day!" |

## Ads and purchase

- Ads never during a workout or timer, and never block starting one.
- "Remove ads" is a **one-off** purchase. No subscriptions, no dark patterns, no fake urgency.

## Accessibility

- Screen-reader labels on everything interactive.
- Big tap targets.
- Respect reduce-motion (skip or simplify pose blends).
- Readable contrast in both themes: light teal (light) and dark with coral (dark).

## Code and repo workflow

- Small feature branches into `dev` with **regular merge commits** (not squash).
- `dev` → `main` as a squash release when shipping.
- Human-sounding commits: plain and specific.
- Keep the repo public-safe: no personal info, no secrets, no links to private repos.
- Test on a real device before calling something done. Never force-push.

## Adding a feature checklist

- [ ] Fits the principles (simple, free, offline, no guilt)
- [ ] Any tip is slotted into the schedule above — not a first-launch pop-up
- [ ] Works offline; data stays on the phone
- [ ] Accessible (labels, tap targets, reduce-motion, contrast)
- [ ] Works for all body shapes (parameterised stick figures)
- [ ] Copy is warm, never guilt-tripping
- [ ] Tested on a real device
