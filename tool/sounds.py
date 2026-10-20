"""Generates the app's sounds from plain sine waves (no third-party audio).

Run from the repo root: python3 tool/sounds.py
Writes 16-bit mono WAVs to assets/sounds/:
  blip.wav        soft countdown blip (last 3 seconds of a move or rest)
  move_start.wav  rising two-note chime when a move starts
  rest_start.wav  falling two-note chime when a rest starts
  music_loop.wav  gentle 8-bar loop for the optional background music
"""
import math, os, struct, wave

RATE = 22050


def env(i, n, attack=0.01, release=0.08):
    t = i / RATE
    a = min(1.0, t / attack) if attack else 1.0
    r = min(1.0, (n - i) / (release * RATE)) if release else 1.0
    return a * max(r, 0.0)


def tone(freq, secs, amp=0.5, attack=0.01, release=0.08, harmonics=((1, 1.0),)):
    n = int(secs * RATE)
    out = []
    for i in range(n):
        v = sum(w * math.sin(2 * math.pi * freq * h * i / RATE) for h, w in harmonics)
        out.append(v * amp * env(i, n, attack, release))
    return out


def silence(secs):
    return [0.0] * int(secs * RATE)


def mix_into(buf, samples, at):
    start = int(at * RATE)
    for i, v in enumerate(samples):
        j = (start + i) % len(buf)  # wrap so the loop stays seamless
        buf[j] += v


def write(path, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    k = min(1.0, 0.9 / peak)
    with wave.open(path, 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, s * k)) * 32767)) for s in samples))


BELL = ((1, 1.0), (2, 0.25), (3, 0.08))


def main():
    os.makedirs('assets/sounds', exist_ok=True)
    write('assets/sounds/blip.wav', tone(880, 0.09, 0.35, 0.004, 0.05))
    write('assets/sounds/move_start.wav',
          tone(659.25, 0.14, 0.5, 0.005, 0.06, BELL) + tone(987.77, 0.26, 0.5, 0.005, 0.2, BELL))
    write('assets/sounds/rest_start.wav',
          tone(659.25, 0.16, 0.4, 0.01, 0.08, BELL) + tone(440.0, 0.32, 0.4, 0.01, 0.25, BELL))

    # Music: 8 bars at 96 bpm, I-vi-IV-V in C, soft pad plus a quiet pulse.
    beat = 60 / 96
    bars = [(261.63, 329.63, 392.00), (220.00, 261.63, 329.63),
            (174.61, 220.00, 261.63), (196.00, 246.94, 293.66)] * 2
    length = len(bars) * 4 * beat
    buf = [0.0] * int(length * RATE)
    for b, chord in enumerate(bars):
        t0 = b * 4 * beat
        for f in chord:
            mix_into(buf, tone(f, 4 * beat, 0.10, 0.4, 0.6, ((1, 1.0), (2, 0.15))), t0)
        for q in range(4):
            mix_into(buf, tone(chord[0] / 2, beat * 0.5, 0.12 if q % 2 == 0 else 0.07, 0.01, 0.2), t0 + q * beat)
    write('assets/sounds/music_loop.wav', buf)


if __name__ == '__main__':
    main()
