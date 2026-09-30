# Day A feedback mockups (30 Sep 2026)

Mockups only, no app changes yet. Rendered from `src/*.html` with headless Chrome (412x915 @2.625x).

Round 3: large text for reading from standing with the phone on the floor. Workout screens have a ~46sp name, ~28sp cue and a huge countdown; nothing is below ~16sp. Decorative lines are gone and cues are cut to one short line.

- `png/a-dayA-list.png`: Day A list. Warm-up collapsed to one row; lunges split right/left with Plank between (40s each)
- `png/b-exercise-cue.png`: exercise screen with big name, one-line cue, big countdown, coral NEXT UP chip
- `png/c-rest-next.png`: rest screen with the rest countdown and a large coral NEXT UP card ("in 12s")
- `png/e-warmup-next-preview.png`: last 25% of a warm-up move; countdown keeps running, next move previewed
- `png/d-first-workout-card.png`: "Before you start" card with "Don't show this again"
- `png/rest-last-3s.gif`: final 3s of a rest; the NEXT UP card blinks grey each second
- `png/overview.png`: all five side by side

Round 4: all figures wear the coral headband with two tied tails at the back, so you can see which way the head faces (faded on next-up previews). The reverse lunge figure is redrawn side-on with clear knees: front knee about 90° over the front foot, back knee dropping to the floor. "Right" faces right with the right (near) leg back; "left" is the mirror image.
Proposal (marked on screen): the lunge's working/back leg is tinted coral so right vs left is obvious.

Naming: "Reverse lunge (right)" = right leg goes back. "Lunge (right)" (forward) = right leg goes forward. Right side first.

`src/fig/` holds mockup-only copies of the figure SVGs with the headband added; the app's `assets/figures` are untouched.

## GUIDE.md note (not changed yet)

Card (d) is an exception to "Nothing on first install / first launch". It appears when the
user taps Start, not on app launch, and keeps appearing until they tick the box. Proposed wording:

> - **Nothing on first install / first launch.** The user goes straight into their first workout.
>   One exception: a short, warm "before you start" note may appear when a workout is started,
>   until the user chooses "Don't show this again". It must never block starting, and it is never
>   shown during a workout or rest timer.
