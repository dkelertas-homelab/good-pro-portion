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

Round 5: the lunge figure has hands on hips with elbows clearly out (both sides). New screens:

- `png/f-workout-done.png`: finished Quiet morning A, with a warm well-done message and a "Got more time? Why not start Quiet morning B?" card (Start B, or "Done for today"). Finishing B suggests A.
- `png/g-home-picker.png`: home picker with 6 routines grouped by time of day (names, duration and tags only).

`src/build_figs.py` regenerates the mockup figure copies in `src/fig/`.

## Draft routines (not in the app yet)

Built only from moves already in `assets/content.json`. Every routine uses the usual 2 min warm-up
(March on the spot, Arm circles, Good morning, Slow squats; 30s each, no rests).
One-sided moves are split right then left, with a different move in between.

**Lunch A** (~10 min, standing only, low sweat, work clothes friendly). 40s work, 20s rest
1. Squat
2. Incline push-up (desk or bench)
3. Reverse lunge (right)
4. Wall sit
5. Reverse lunge (left)
6. Good morning
7. Incline push-up
8. Squat

**Lunch B** (~10 min, standing only, low sweat, work clothes friendly). 40s work, 20s rest
1. Split squat (right)
2. Incline push-up
3. Split squat (left)
4. Wall sit
5. Good morning
6. Squat
7. Incline push-up
8. March on the spot (easy finish)

**After work A** (~15 min, more energetic, proper sweat). 40s work, 20s rest
1. Squat
2. Push-up
3. Reverse lunge (right)
4. Shoulder tap
5. Reverse lunge (left)
6. Plank
7. Split squat (right)
8. Glute bridge
9. Split squat (left)
10. Push-up
11. Dead bug
12. Squat

**After work B** (~15 min, more energetic, proper sweat). 40s work, 20s rest
1. Squat
2. Side plank (right)
3. Push-up
4. Side plank (left)
5. Reverse lunge (right)
6. Superman
7. Reverse lunge (left)
8. Shoulder tap
9. Wall sit
10. Bird dog
11. Squat
12. Plank

Timing: Lunch is 2 min warm-up + 8 x 40s + 7 x 20s, about 10 min. After work is 2 min + 12 x 40s + 11 x 20s, about 14 min.

## GUIDE.md note (not changed yet)

Card (d) is an exception to "Nothing on first install / first launch". It appears when the
user taps Start, not on app launch, and keeps appearing until they tick the box. Proposed wording:

> - **Nothing on first install / first launch.** The user goes straight into their first workout.
>   One exception: a short, warm "before you start" note may appear when a workout is started,
>   until the user chooses "Don't show this again". It must never block starting, and it is never
>   shown during a workout or rest timer.
