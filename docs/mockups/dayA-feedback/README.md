# Day A feedback mockups (30 Sep 2026)

Mockups only, no app changes yet. Rendered from `src/*.html` with headless Chrome (412x915 @2.625x).

- `png/a-dayA-list.png`: Day A overview. Reverse lunge is split into right (right leg steps back) and left, 40s each, with Plank in between for variety (8 work moves)
- `png/b-exercise-cue.png`: exercise screen with a short cue under the name, plus a coral dashed "NEXT UP" chip
- `png/c-rest-next.png`: rest screen with a coral "NEXT UP · GET READY" card (ghosted figure, name, how-to); the ring is the rest time left
- `png/e-warmup-next-preview.png`: warm-up has no rests, so for the last 25% of each move the countdown keeps running and the screen previews the next move
- `png/d-first-workout-card.png`: "Before you start" card with a "Don't show this again" checkbox
- `png/overview.png`: all five side by side

Naming: "Reverse lunge (right)" = right leg goes back. "Lunge (right)" (forward) = right leg goes forward. Right side first.

## GUIDE.md note (not changed yet)

Card (d) is an exception to "Nothing on first install / first launch". It appears when the
user taps Start, not on app launch, and keeps appearing until they tick the box. Proposed wording:

> - **Nothing on first install / first launch.** The user goes straight into their first workout.
>   One exception: a short, warm "before you start" note may appear when a workout is started,
>   until the user chooses "Don't show this again". It must never block starting, and it is never
>   shown during a workout or rest timer.
