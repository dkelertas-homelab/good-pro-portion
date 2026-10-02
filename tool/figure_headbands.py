"""Adds the coral headband with two tied tails to every figure in assets/figures,
and (re)draws the side-on reverse lunge and the dead bug. Safe to re-run: figures that already
have a headband are skipped. Run from the repo root: python3 tool/figure_headbands.py

Light figures are teal with a coral band. Dark figures are already coral, so
their band (and the lunge's back leg) use light teal instead."""
import glob, re

LIGHT = dict(fig='#0F766E', band='#FF6F61')
DARK = dict(fig='#FF6B4A', band='#5EEAD4')
MARK = '<!--headband-->'


def band(cx, cy, r, tail, c):
    """tail: +1 tails trail right, -1 left, 0 front-facing (tails peek out low-left)."""
    y = cy - r * 0.37; h = r * 0.5
    s = (f'{MARK}<clipPath id="hb"><circle cx="{cx}" cy="{cy}" r="{r}"/></clipPath>'
         f'<rect x="{cx-r-1}" y="{y-h/2}" width="{2*r+2}" height="{h}" fill="{c}" clip-path="url(#hb)"/>')
    d = tail if tail else -1; kx = cx + d * (r - 1); w = r * 0.34
    ends = ([(kx + d*r*1.25, y - r*0.55), (kx + d*r*1.1, y + r*0.5)] if tail
            else [(kx + d*r*0.85, y + r*0.75), (kx + d*r*0.45, y + r*1.0)])
    for x2, y2 in ends:
        s += (f'<path d="M{kx:.1f},{y:.1f} Q{(kx+x2)/2:.1f},{y2-(3 if tail else 0):.1f} {x2:.1f},{y2:.1f}" '
              f'stroke="{c}" stroke-width="{w:.1f}" stroke-linecap="round" fill="none"/>')
    return s + f'<circle cx="{kx:.1f}" cy="{y:.1f}" r="{r*0.26:.1f}" fill="{c}"/>'


def L(x1, y1, x2, y2, c, w=16):
    return f'<line x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}" stroke="{c}" stroke-width="{w}" stroke-linecap="round"/>'


def J(x, y, c, r=9):
    return f'<circle cx="{x}" cy="{y}" r="{r}" fill="{c}"/>'


def reverse_lunge(p):
    """Side-on, facing right. The near (right) leg is the back leg, tinted. The
    left side is the same drawing mirrored in the app."""
    T, C = p['fig'], p['band']
    hip = (102, 112); fk = (146, 112); ff = (148, 172); bk = (84, 168); bf = (42, 170)
    s = '<svg viewBox="0 0 200 200" width="200" height="200" xmlns="http://www.w3.org/2000/svg">'
    s += f'<ellipse cx="100" cy="182" rx="68" ry="6" fill="{T}" opacity="0.18"/>'
    s += L(112, 58, 146, 80, T, 13) + L(146, 80, 116, 104, T, 13) + J(146, 80, T, 7)       # far arm, elbow out front
    s += L(*hip, *fk, T) + L(*fk, *ff, T) + L(148, 176, 166, 176, T, 10) + J(*fk, T, 10)    # front leg, knee ~90°
    s += f'<rect x="92" y="46" width="26" height="70" rx="13" fill="{T}" transform="rotate(4 105 80)"/>' + J(108, 28, T, 16)
    s += L(*hip, *bk, C) + L(*bk, *bf, C, 15) + J(*bk, C, 10) + J(38, 172, C, 7)            # back leg, knee to floor
    s += L(98, 58, 62, 82, T, 13) + L(62, 82, 94, 104, T, 13) + J(62, 82, T, 7) + J(94, 104, T, 6)  # hand on hip
    s += J(*hip, T, 9) + band(108, 28, 16, -1, C) + '</svg>'
    return s


def dead_bug(p):
    """Lying on the back, head left, face up. One arm points straight up and
    the knee on the other side stays bent at 90 over the hip; the opposite arm
    reaches back overhead and the opposite leg extends low (both tinted)."""
    T, C = p['fig'], p['band']
    sh = (66, 136); hip = (124, 136)
    s = '<svg viewBox="0 0 200 200" width="200" height="200" xmlns="http://www.w3.org/2000/svg">'
    s += f'<ellipse cx="100" cy="156" rx="78" ry="6" fill="{T}" opacity="0.18"/>'
    s += L(*sh, 70, 78, T, 13) + J(70, 78, T, 6)                                # arm straight up
    s += L(*hip, 126, 92, T) + L(126, 92, 164, 92, T) + J(126, 92, T, 9) + J(164, 92, T, 7)  # tabletop leg
    s += L(*sh, *hip, T, 26)                                                    # torso on the floor
    s += J(36, 122, T, 16)                                                      # head, clear of the torso
    s += L(*sh, 34, 72, C, 13) + J(34, 72, C, 6)                               # opposite arm, reaching back overhead
    s += L(*hip, 186, 124, C) + J(154, 130, C, 8) + J(186, 124, C, 7)           # opposite leg, extended low
    s += J(*hip, T, 10) + band(36, 122, 16, -1, C) + '</svg>'
    return s


for path in sorted(glob.glob('assets/figures/*.svg')):
    p = DARK if path.endswith('_dark.svg') else LIGHT
    if re.search(r'/reverseLunge(_dark)?\.svg$', path):
        open(path, 'w').write(reverse_lunge(p)); print(path, 'redrawn'); continue
    if re.search(r'/deadBug(_dark)?\.svg$', path):
        open(path, 'w').write(dead_bug(p)); print(path, 'redrawn'); continue
    s = open(path).read()
    if MARK in s:
        continue
    cs = [(float(m[2]), float(m[0]), float(m[1]))
          for m in re.findall(r'<circle cx="([\d.]+)" cy="([\d.]+)" r="([\d.]+)" fill="#', s)]
    r, cx, cy = max(cs)  # head = largest filled circle
    xs = [float(v) for v in re.findall(r' (?:x1|x2|cx)="([\d.]+)"', s)]
    dx = sum(xs) / len(xs) - cx
    tail = 0 if abs(dx) < 8 else (1 if dx > 0 else -1)  # tails trail toward the body
    open(path, 'w').write(s.replace('</svg>', band(cx, cy, r, tail, p['band']) + '</svg>'))
    print(path, 'tail', tail)
