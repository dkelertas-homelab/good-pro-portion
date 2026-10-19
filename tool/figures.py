"""Draws every exercise figure as a few key poses, side-on where that reads best.

Writes, from the repo root (python3 tool/figures.py):
  assets/figures/<key>.svg + <key>_dark.svg          still used in lists and cards
  assets/figures/frames/<key>_<n>.svg (+ _dark)      animation frames
  lib/widgets/figure_frames.dart                     frame order and timing

Conventions
- 200x200 viewBox, floor shadow at y=182, side-on figures face right.
- Each move is start, middle, end (the end pose is held, then it loops back
  to the start). No return frames. Holds are 2 frames; arm circles 4.
- One-sided moves are drawn for the right side only. The app tells the user
  to swap sides; it never mirrors the figure.
- Facing right, the near limbs are the figure's RIGHT limbs. Far limbs are a
  softer shade so the two legs never blur together.
- One-sided moves tint the working right leg (reverse lunge, split squat: the
  right leg is the one that steps back). Alternating moves show the right arm
  (and the left leg where it pairs) and tint the moving limbs.
- Coral headband with two tied tails at the back of the head, so you can always
  tell which way the head faces.
- Holds (plank, side plank, wall sit) alternate the pose with a guide line.
"""
import math, os

LIGHT = dict(fig='#0F766E', band='#FF6F61', bg='#CCFBF1', prop='#5EC9BA')
DARK = dict(fig='#FF6B4A', band='#5EEAD4', bg='#3A221C', prop='#8A4A3A')

THIGH, SHIN, TORSO, NECK, HEAD_R = 40, 40, 48, 24, 16
UPPER, FORE, FOOT = 28, 28, 15
LEG_W, ARM_W, BODY_W = 16, 13, 26
ANKLE_Y = 172  # ankle height when standing flat
MUTE_FAR = [True]


def mix(a, b, t):
    ca = [int(a[i:i + 2], 16) for i in (1, 3, 5)]
    cb = [int(b[i:i + 2], 16) for i in (1, 3, 5)]
    return '#' + ''.join(f'{round(x + (y - x) * t):02X}' for x, y in zip(ca, cb))


# ---------- geometry ----------

def add(a, b, k=1.0):
    return (a[0] + b[0] * k, a[1] + b[1] * k)


def sub(a, b):
    return (a[0] - b[0], a[1] - b[1])


def norm(v):
    d = math.hypot(*v) or 1.0
    return (v[0] / d, v[1] / d)


def dirdeg(a):
    """Unit vector at angle a degrees: 0 = straight down, 90 = forward (+x), 180 = up."""
    r = math.radians(a)
    return (math.sin(r), math.cos(r))


def ik(root, target, l1, l2, hint):
    """Middle joint of a two-bone limb from root to target, on the side of hint."""
    d = math.dist(root, target)
    d = max(abs(l1 - l2) + 0.01, min(d, l1 + l2 - 0.01))
    u = norm(sub(target, root))
    a = (l1 * l1 - l2 * l2 + d * d) / (2 * d)
    h = math.sqrt(max(l1 * l1 - a * a, 0))
    p = (-u[1], u[0])
    c1 = add(add(root, u, a), p, h)
    c2 = add(add(root, u, a), p, -h)
    j = c1 if math.dist(c1, hint) < math.dist(c2, hint) else c2
    end = add(j, norm(sub(target, j)), l2)
    if math.dist(end, target) > 1.5:
        print(f'  note: limb short by {math.dist(end, target):.1f}px')
    return j, end


def fk(root, a1, a2, l1, l2):
    j = add(root, dirdeg(a1), l1)
    return j, add(j, dirdeg(a2), l2)


# ---------- pose ----------

class Pose:
    """Joints for one frame. Limbs: list of (side, kind, points, tint)."""

    def __init__(self):
        self.limbs = []      # (layer, kind, [p0, p1, p2], tint, foot)
        self.torso = None    # (hip, sh)
        self.head = None     # (centre, up_vector, face_vector or None for front-on)
        self.props = []      # ('rect', x, y, w, h) or ('wall', ...)
        self.guides = []     # list of point lists (dashed accent line)

    def leg(self, layer, hip, ankle, hint, toe=None, tint=False):
        k, a = ik(hip, ankle, THIGH, SHIN, hint)
        self.limbs.append((layer, 'leg', [hip, k, a], tint, toe))
        return k, a

    def leg_fk(self, layer, hip, a1, a2, toe=None, tint=False):
        k, a = fk(hip, a1, a2, THIGH, SHIN)
        self.limbs.append((layer, 'leg', [hip, k, a], tint, toe))
        return k, a

    def arm(self, layer, sh, hand, hint, tint=False):
        e, h = ik(sh, hand, UPPER, FORE, hint)
        self.limbs.append((layer, 'arm', [sh, e, h], tint, None))
        return e, h

    def arm_fk(self, layer, sh, a1, a2, tint=False):
        e, h = fk(sh, a1, a2, UPPER, FORE)
        self.limbs.append((layer, 'arm', [sh, e, h], tint, None))
        return e, h

    def body(self, hip, sh, head_tilt=0.0, face=None):
        """Torso from hip to shoulder; head beyond the shoulder, tilted back by head_tilt degrees."""
        self.torso = (hip, sh)
        up = norm(sub(sh, hip))
        r = math.radians(-head_tilt)  # positive = tip the head back (look up)
        up = (up[0] * math.cos(r) - up[1] * math.sin(r), up[0] * math.sin(r) + up[1] * math.cos(r))
        c = add(sh, up, NECK)
        if face is None:  # face points 90 degrees clockwise from up (facing right when upright)
            face = (-up[1], up[0])
        self.head = (c, up, face)
        return c


def standing_torso(hip, lean, head_lean=None):
    """Shoulder for a torso leaning forward by lean degrees."""
    return add(hip, dirdeg(180 - lean), TORSO)


# ---------- svg ----------

def L(p, q, c, w):
    return (f'<line x1="{p[0]:.1f}" y1="{p[1]:.1f}" x2="{q[0]:.1f}" y2="{q[1]:.1f}" '
            f'stroke="{c}" stroke-width="{w}" stroke-linecap="round"/>')


def J(p, c, r):
    return f'<circle cx="{p[0]:.1f}" cy="{p[1]:.1f}" r="{r}" fill="{c}"/>'


def band(head, c):
    (cx, cy), up, face = head
    r = HEAD_R
    front = face == 'front'
    ang = math.degrees(math.atan2(up[0], -up[1]))  # rotation from upright
    y = -r * 0.37
    h = r * 0.5
    s = (f'<clipPath id="hb"><circle cx="{cx:.1f}" cy="{cy:.1f}" r="{r}"/></clipPath>'
         f'<g clip-path="url(#hb)"><rect x="{cx - r - 1:.1f}" y="{cy + y - h / 2:.1f}" width="{2 * r + 2}" '
         f'height="{h}" fill="{c}" transform="rotate({ang:.1f} {cx:.1f} {cy:.1f})"/></g>')
    w = r * 0.34
    if front:
        # Facing the viewer: knot hidden behind the head, tails peek out low-left.
        k = (cx - (r - 1), cy + y)
        ends = [(k[0] - r * 0.85, k[1] + r * 0.75), (k[0] - r * 0.45, k[1] + r * 1.0)]
        for e in ends:
            m = ((k[0] + e[0]) / 2, e[1])
            s += (f'<path d="M{k[0]:.1f},{k[1]:.1f} Q{m[0]:.1f},{m[1]:.1f} {e[0]:.1f},{e[1]:.1f}" '
                  f'stroke="{c}" stroke-width="{w:.1f}" stroke-linecap="round" fill="none"/>')
        return s + J(k, c, round(r * 0.26, 1))
    back = (-face[0], -face[1])
    k = (cx + back[0] * (r - 1) + up[0] * (-y), cy + back[1] * (r - 1) + up[1] * (-y))
    tail = norm(add(add((back[0] * 0.6, back[1] * 0.6), (-up[0], -up[1]), 0.6), (0, 0.3)))
    if tail[1] > 0.6 and face[1] < -0.5:  # lying face up: tails splay out along the floor
        tail = norm(add(up, (0, -0.05)))
    for spread, ln in ((-22, 1.35), (14, 1.15)):
        t = math.radians(spread)
        d = (tail[0] * math.cos(t) - tail[1] * math.sin(t), tail[0] * math.sin(t) + tail[1] * math.cos(t))
        e = add(k, d, r * ln)
        m = add(add(k, d, r * ln * 0.5), (0, 1), 3)
        s += (f'<path d="M{k[0]:.1f},{k[1]:.1f} Q{m[0]:.1f},{m[1]:.1f} {e[0]:.1f},{e[1]:.1f}" '
              f'stroke="{c}" stroke-width="{w:.1f}" stroke-linecap="round" fill="none"/>')
    return s + J(k, c, round(r * 0.26, 1))


def dashed(pts, c, w=4, dash=7, gap=6):
    s = ''
    for p, q in zip(pts, pts[1:]):
        d = math.dist(p, q)
        u = norm(sub(q, p))
        t = 0.0
        while t < d:
            a = add(p, u, t)
            b = add(p, u, min(t + dash, d))
            s += L(a, b, c, w)
            t += dash + gap
    return s


def limb_svg(limb, pal):
    layer, kind, (a, b, c), tint, toe = limb
    base = pal['band'] if tint else pal['fig']
    col = mix(base, pal['bg'], 0.38) if layer == 'far' and MUTE_FAR[0] else base
    w = LEG_W if kind == 'leg' else ARM_W
    s = L(a, b, col, w) + L(b, c, col, w)
    if kind == 'leg':
        if toe is not None:
            s += L(c, add(c, norm(toe), FOOT), col, 10)
        s += J(b, col, 9)
    else:
        s += J(b, col, 6.5) + J(c, col, 6)
    return s


def render(pose, pal, fit):
    sc, dx, dy = fit
    T = pal['fig']
    out = ['<svg viewBox="0 0 200 200" width="200" height="200" xmlns="http://www.w3.org/2000/svg">',
           f'<ellipse cx="100" cy="182" rx="72" ry="6" fill="{T}" opacity="0.18"/>']
    g = f'<g transform="translate({dx:.1f} {dy:.1f}) scale({sc:.3f})">' if fit != (1, 0, 0) else '<g>'
    out.append(g)
    for p in pose.props:
        kind, x, y, w, h = p
        out.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="4" fill="{pal["prop"]}"/>')
    far = [l for l in pose.limbs if l[0] == 'far']
    near = [l for l in pose.limbs if l[0] == 'near']
    # far side first, then torso and head, then near side
    far.sort(key=lambda l: l[1] == 'arm')  # far legs, then far arms
    for l in far:
        out.append(limb_svg(l, pal))
    hip, sh = pose.torso
    out.append(L(hip, sh, T, BODY_W))
    out.append(J(pose.head[0], T, HEAD_R))
    near.sort(key=lambda l: l[1] == 'arm')
    for l in near:
        out.append(limb_svg(l, pal))
    out.append(J(hip, T, 9))
    out.append(band(pose.head, pal['band']))
    for g_ in pose.guides:
        out.append(dashed(g_, pal['band']))
    out.append('</g></svg>')
    return ''.join(out)


def bounds(poses):
    xs, ys = [], []
    for p in poses:
        pts = [pt for l in p.limbs for pt in l[2]] + list(p.torso) + [p.head[0]]
        for l in p.limbs:
            if l[4] is not None:
                pts.append(add(l[2][2], norm(l[4]), FOOT))
        for pr in p.props:
            pts += [(pr[1], pr[2]), (pr[1] + pr[3], pr[2] + pr[4])]
        xs += [q[0] for q in pts]
        ys += [q[1] for q in pts]
    m = 12  # half a limb width, plus a little air
    return min(xs) - m, min(ys) - HEAD_R, max(xs) + m, max(ys) + 6


def fit_for(poses):
    """Scale down (never up) so every frame fits, keeping the floor line at y=180."""
    x0, y0, x1, y1 = bounds(poses)
    sc = min(1.0, 192 / (x1 - x0), (180 - 4) / (y1 - y0) if y1 > 0 else 1)
    if sc >= 1.0 and x0 >= 4 and x1 <= 196 and y0 >= 2:
        return (1, 0, 0)
    dx = 100 - sc * (x0 + x1) / 2
    dy = 180 - sc * y1 if y1 * sc + 0 > 0 else 0
    # keep feet on the floor: floor is y=180 in the scaled drawing
    dy = 180 - sc * 180 + (180 - y1) * 0  # anchor at floor
    dy = 180 * (1 - sc)
    return (round(sc, 3), round(dx, 1), round(dy, 1))


# ---------- moves ----------

# Start, middle, then hold the end position; the loop jumps back to the start.
# No return frames: the end pose is what the user should aim for.
SEQ3 = [(0, 500), (1, 350), (2, 1000)]


def toe_fwd():
    return (1, 0.15)


def squat():
    frames = []
    for hip, lean, arm in (((100, 94), 4, 8), ((88, 114), 22, 50), ((74, 132), 40, 88)):
        p = Pose()
        sh = standing_torso(hip, lean)
        p.body(hip, sh, head_tilt=lean * 0.45)
        p.leg('far', hip, (100, ANKLE_Y), (200, 0), toe_fwd())
        p.leg('near', hip, (104, ANKLE_Y), (200, 0), toe_fwd())
        p.arm_fk('far', sh, arm - 4, arm + 2)
        p.arm_fk('near', sh, arm, arm + 6)
        frames.append(p)
    return frames, SEQ3, 2


def _press_up(ankle, hand, sh_y, length=126, bench=None):
    p = Pose()
    dx = math.sqrt(max(length ** 2 - (ankle[1] - sh_y) ** 2, 0))
    sh = (ankle[0] + dx, sh_y)
    u = norm(sub(sh, ankle))
    hip = add(ankle, u, (THIGH + SHIN) * length / 128)
    p.body(hip, sh, head_tilt=4)
    for layer, off in (('far', -5), ('near', 0)):
        a = (ankle[0] + off, ankle[1])
        p.leg(layer, hip, a, add(hip, (0, 30)), (0.55, 0.85))
        p.arm(layer, sh, (hand[0] + off, hand[1]), add(sh, (-40, -10)))
    if bench:
        p.props.append(bench)
    return p


def _top_hand(ankle, hand_y, length=126, arm=UPPER + FORE - 1):
    """Where the hand goes so the arm is straight and upright-ish at the top."""
    # shoulder straight above the hand, on the circle of radius length around the ankle
    sh_y = hand_y - arm
    return ankle[0] + math.sqrt(length ** 2 - (ankle[1] - sh_y) ** 2), sh_y


def push_up():
    an = (30, 166)
    hx, top = _top_hand(an, 174)
    frames = [_press_up(an, (hx, 174), y) for y in (top, top + 18, top + 34)]
    return frames, SEQ3, 0  # still: top of the push-up reads best in lists


def incline_push_up():
    an = (34, 168)
    hand_y = 116
    # hands a little ahead of the shoulder: the body is at an angle
    sh_x, top = _top_hand(an, hand_y + 6)
    hand = (sh_x + 14, hand_y)
    bench = ('rect', hand[0] - 22, hand_y + 6, 56, 12)
    frames = [_press_up(an, hand, y, bench=bench) for y in (top, top + 12, top + 24)]
    for p in frames:
        p.props.append(('rect', hand[0] - 14, hand_y + 18, 8, 180 - hand_y - 18))
        p.props.append(('rect', hand[0] + 22, hand_y + 18, 8, 180 - hand_y - 18))
    return frames, SEQ3, 0  # still: top of the push-up reads best in lists


def _hands_on_hips(p, hip, sh):
    p.arm('far', sh, add(hip, (2, -10)), add(sh, (-40, 8)))
    p.arm('near', sh, add(hip, (6, -8)), add(sh, (-40, 12)))


def reverse_lunge():
    """Feet together, the right (near, tinted) foot steps back, then the bottom.

    The left (front) foot never moves; the body travels back with the step.
    """
    front = (104, ANKLE_Y)
    specs = [((102, 94), (100, ANKLE_Y), toe_fwd(), (200, 60)),   # standing, feet together
             ((96, 110), (58, 158), (0.45, 0.9), (94, 160)),        # right foot in the air, stepping back
             ((66, 132), (24, 168), (0.6, 0.8), (60, 190))]        # bottom: both knees about 90
    frames = []
    for hip, back, btoe, bhint in specs:
        p = Pose()
        sh = standing_torso(hip, 3)
        p.body(hip, sh)
        p.leg('far', hip, front, add(hip, (60, -10)), toe_fwd())
        p.leg('near', hip, back, bhint, btoe, tint=True)
        _hands_on_hips(p, hip, sh)
        frames.append(p)
    return frames, SEQ3, 2


def split_squat():
    """Staggered stance, right (near, tinted) foot back. The feet never move:
    tall, halfway, bottom. Dashes on the floor mark the planted feet."""
    front, back = (132, ANKLE_Y), (54, 166)
    frames = []
    for hip in ((93, 100), (92, 117), (91, 134)):
        p = Pose()
        sh = standing_torso(hip, 3)
        p.body(hip, sh)
        p.leg('far', hip, front, add(hip, (60, -10)), toe_fwd())
        p.leg('near', hip, back, add(hip, (-10, 60)), (0.6, 0.8), tint=True)
        _hands_on_hips(p, hip, sh)
        p.guides.append([(front[0] - 10, 186), (front[0] + 22, 186)])
        p.guides.append([(back[0] - 6, 186), (back[0] + 22, 186)])
        frames.append(p)
    return frames, SEQ3, 2


def glute_bridge():
    sh = (66, 166)
    frames = []
    for th in (0, 16, 32):
        p = Pose()
        hip = add(sh, (math.cos(math.radians(th)), -math.sin(math.radians(th))), TORSO)
        p.body(hip, sh, face=(0, -1))
        for layer, off in (('far', -4), ('near', 0)):
            p.leg(layer, hip, (138 + off, ANKLE_Y), (130, 90), toe_fwd())
            hand = (sh[0] + UPPER + FORE + off, 172)
            p.limbs.append((layer, 'arm', [sh, add(sh, sub(hand, sh), 0.5), hand], False, None))
        frames.append(p)
    return frames, SEQ3, 2


def plank():
    frames = []
    for guide in (False, True):
        p = Pose()
        elbow, sh = (150, 172), (150, 144)
        ankle = (150 - math.sqrt(128 ** 2 - 28 ** 2), 166)
        u = norm(sub(sh, ankle))
        hip = add(ankle, u, THIGH + SHIN)
        p.body(hip, sh, head_tilt=4)
        for layer, off in (('far', -5), ('near', 0)):
            p.leg(layer, hip, (ankle[0] + off, ankle[1]), add(hip, (-40, 30)), (0.55, 0.85))
            e = (elbow[0] + off, elbow[1])
            p.limbs.append((layer, 'arm', [sh, e, add(e, (FORE, 2))], False, None))
        if guide:
            p.guides.append([add(ankle, (0, -16)), add(sh, (0, -16))])
        frames.append(p)
    return frames, [(0, 900), (1, 900)], 0


def side_plank():
    """Front view, on the right forearm, head on the viewer's left, facing the viewer."""
    frames = []
    for guide in (False, True):
        p = Pose()
        sh, elbow = (54, 140), (54, 168)
        feet = (54 + math.sqrt(128 ** 2 - 32 ** 2), 172)
        u = norm(sub(feet, sh))
        hip = add(sh, u, TORSO)
        p.torso = (hip, sh)
        up = (-u[0], -u[1])
        p.head = (add(sh, up, NECK), up, 'front')
        p.limbs.append(('near', 'arm', [sh, elbow, add(elbow, (6, 3))], False, None))
        # top arm: hand on the hip, elbow up
        p.arm('far', add(sh, (2, -6)), add(hip, (-4, -10)), add(sh, (16, -40)))
        k = add(hip, u, THIGH)
        p.limbs.append(('far', 'leg', [hip, add(k, (0, -5)), add(feet, (-2, -9))], False, None))
        p.limbs.append(('near', 'leg', [hip, k, feet], False, None))
        if guide:
            p.guides.append([add(p.head[0], (-6, -22)), add(feet, (6, -22))])
        frames.append(p)
    return frames, [(0, 900), (1, 900)], 0


def superman():
    frames = []
    for lift in (0, 10, 20):
        p = Pose()
        hip = (82, 166)
        r = math.radians(lift)
        sh = add(hip, (math.cos(r), -math.sin(r)), TORSO)
        p.body(hip, sh, head_tilt=4 + lift * 0.5)
        # face down: rotate face vector to point at the floor-forward
        for layer, off in (('far', -3), ('near', 0)):
            la = 90 - lift * 1.2  # legs straight back, lifted
            a = add(hip, (-math.cos(math.radians(lift * 1.1)), -math.sin(math.radians(lift * 1.1))), THIGH + SHIN)
            p.limbs.append((layer, 'leg', [hip, add(hip, sub(a, hip), 0.5), add(a, (off, 0))], False, (0.2, 1)))
            ar = math.radians(lift * 1.6)
            hand = add(sh, (math.cos(ar), -math.sin(ar)), UPPER + FORE)
            p.limbs.append((layer, 'arm', [sh, add(sh, sub(hand, sh), 0.5), add(hand, (off, 0))], False, None))
        frames.append(p)
    return frames, SEQ3, 2


def dead_bug():
    """Right arm reaches back overhead while the left leg straightens low."""
    sh, hip = (64, 166), (112, 166)
    frames = []
    for t in (0, 0.5, 1):
        p = Pose()
        p.body(hip, sh, face=(0, -1))
        for layer in ('far', 'near'):
            off = -4 if layer == 'far' else 0
            moving_leg, moving_arm = layer == 'far', layer == 'near'
            lt = t if moving_leg else 0
            ta, sa = math.radians(90 + (14 - 90) * lt), math.radians(14 * lt)
            k = add((hip[0] + off, hip[1]), (math.cos(ta), -math.sin(ta)), THIGH)
            a = add(k, (math.cos(sa), -math.sin(sa)), SHIN)
            p.limbs.append((layer, 'leg', [hip, k, a], moving_leg and t > 0, (0.3, -1)))
            at = t if moving_arm else 0
            aa = math.radians(90 + (146 - 90) * at)
            hand = add((sh[0] + off + 2 * (1 - at), sh[1]), (math.cos(aa), -math.sin(aa)), UPPER + FORE)
            p.limbs.append((layer, 'arm', [sh, add(sh, sub(hand, sh), 0.5), hand], moving_arm and t > 0, None))
        frames.append(p)
    return frames, SEQ3, 2


def shoulder_tap():
    """High plank; the right hand lifts and taps the left shoulder."""
    an, hand = (26, 166), (148, 174)
    frames = []
    for t in (0, 0.5, 1):
        p = Pose()
        sh_y = 118
        dx = math.sqrt(130 ** 2 - (an[1] - sh_y) ** 2)
        sh = (an[0] + dx, sh_y)
        u = norm(sub(sh, an))
        hip = add(an, u, (THIGH + SHIN) * 130 / 128)
        p.body(hip, sh, head_tilt=4)
        for layer, off in (('far', -5), ('near', 0)):
            p.leg(layer, hip, (an[0] + off, an[1]), add(hip, (0, 30)), (0.55, 0.85))
            if layer == 'near' and t > 0:
                floor, tap = (hand[0], hand[1]), add(sh, (-4, 8))
                target = (floor[0] + (tap[0] - floor[0]) * t, floor[1] + (tap[1] - floor[1]) * t - 14 * (1 - t))
                p.arm(layer, sh, target, add(sh, (10, 40)), tint=True)
            else:
                p.arm(layer, sh, (hand[0] + off, hand[1]), add(sh, (-40, -20)))
        frames.append(p)
    return frames, SEQ3, 2


def wall_sit():
    frames = []
    for guide in (False, True):
        p = Pose()
        hip = (60, ANKLE_Y - SHIN)
        sh = (58, hip[1] - TORSO)
        p.body(hip, sh, head_tilt=0)
        p.props.append(('rect', 34, 30, 9, 150))
        for layer, off in (('far', -5), ('near', 0)):
            knee = (hip[0] + THIGH + off, hip[1])
            p.limbs.append((layer, 'leg', [hip, knee, (knee[0], ANKLE_Y)], False, toe_fwd()))
            p.arm(layer, sh, (knee[0] - 8 + off, knee[1] - 8), add(sh, (-10, 50)))
        if guide:
            k = (hip[0] + THIGH, hip[1])
            p.guides.append([add(k, (-16, -16)), add(k, (14, -16)), add(k, (14, 16))])
        frames.append(p)
    return frames, [(0, 900), (1, 900)], 0


def bird_dog():
    """On all fours; the right arm reaches forward and the left leg back."""
    sh, hip = (140, 118), (93, 128)
    frames = []
    for t in (0, 0.5, 1):
        p = Pose()
        p.body(hip, sh, head_tilt=6)
        for layer, off in (('far', -5), ('near', 0)):
            if layer == 'far' and t > 0:
                ta, sa = math.radians(-90 + (-183 + 90) * t), math.radians(180 - 3 * t)
                k = add(hip, (math.cos(ta), -math.sin(ta)), THIGH)
                a = add(k, (math.cos(sa), -math.sin(sa)), SHIN)
                p.limbs.append((layer, 'leg', [hip, k, a], True, (-0.2, 1)))
            else:
                k = (hip[0] + off, 168)
                p.limbs.append((layer, 'leg', [hip, k, (k[0] - SHIN, 170)], False, (-1, 0.1)))
            if layer == 'near' and t > 0:
                aa = math.radians(-90 + 94 * t)
                h = add(sh, (math.cos(aa), -math.sin(aa)), UPPER + FORE)
                p.limbs.append((layer, 'arm', [sh, add(sh, sub(h, sh), 0.5), h], True, None))
            else:
                p.arm(layer, sh, (sh[0] + off + 2, 174), add(sh, (-30, 28)))
        frames.append(p)
    return frames, SEQ3, 2


def march():
    """Right knee comes up while the left arm swings forward."""
    frames = []
    for t in (0, 0.5, 1):
        p = Pose()
        hip = (100, 94)
        sh = standing_torso(hip, 2)
        p.body(hip, sh)
        for layer in ('far', 'near'):
            off = -4 if layer == 'far' else 0
            if layer == 'near' and t > 0:
                p.leg_fk(layer, hip, 78 * t, -6 * t - 24 * math.sin(math.pi * t), (1, 0.5))
            else:
                p.leg(layer, hip, (100 + off, ANKLE_Y), (200, 60), toe_fwd())
            if layer == 'far':
                p.arm_fk(layer, sh, 2 + 43 * t, 16 + 104 * t)
            else:
                p.arm_fk(layer, sh, 6 - 38 * t, 16 + 4 * t)
        frames.append(p)
    return frames, SEQ3, 2


def good_morning():
    frames = []
    for hip, lean in (((104, 94), 2), ((97, 98), 38), ((88, 102), 72)):
        p = Pose()
        sh = standing_torso(hip, lean)
        p.body(hip, sh, head_tilt=lean * 0.15)
        down = norm(sub(hip, sh))
        face = p.head[2]
        for layer, off in (('far', -4), ('near', 0)):
            p.leg(layer, hip, (106 + off, ANKLE_Y), (220, 60), toe_fwd())
            hand = add(add(sh, down, 12 + (4 if layer == 'far' else 0)), face, 15)
            p.arm(layer, sh, hand, add(add(sh, down, 30), face, 10))
        frames.append(p)
    return frames, SEQ3, 2


def arm_circles():
    frames = []
    for i in range(4):
        p = Pose()
        hip = (100, 94)
        sh = (100, 46)
        p.torso = (hip, sh)
        p.head = ((100, 22), (0, -1), 'front')
        for side in (-1, 1):
            h = (hip[0] + side * 7, hip[1] + 2)
            p.limbs.append(('near', 'leg', [h, (100 + side * 10, 133), (100 + side * 13, ANKLE_Y)], False, None))
            s = (100 + side * 14, 52)
            phi = math.radians(i * 90)
            hand = (100 + side * 62 + side * 13 * math.cos(phi), 50 + 13 * math.sin(phi))
            el = add(s, sub(hand, s), 0.5)
            p.limbs.append(('near', 'arm', [s, el, hand], False, None))
            p.guides.append([(100 + side * 62 + side * 13 * math.cos(math.radians(a)),
                              50 + 13 * math.sin(math.radians(a))) for a in range(0, 361, 20)])
        frames.append(p)
    return frames, [(0, 300), (1, 300), (2, 300), (3, 300)], 0


MOVES = {
    'squat': squat, 'pushup': push_up, 'inclinePushup': incline_push_up,
    'reverseLunge': reverse_lunge, 'splitSquat': split_squat, 'gluteBridge': glute_bridge,
    'plank': plank, 'sidePlank': side_plank, 'superman': superman, 'deadBug': dead_bug,
    'shoulderTap': shoulder_tap, 'wallSit': wall_sit, 'birdDog': bird_dog, 'march': march,
    'goodMorning': good_morning, 'armCircles': arm_circles,
}

DART_HEAD = '''// Generated by tool/figures.py. Do not edit by hand.

/// One step of a figure animation: which frame file to show, and for how long.
class FigureFrame {
  const FigureFrame(this.frame, this.ms);
  final int frame;
  final int ms;
}

/// Frame order per figure. Frames live in `assets/figures/frames/<key>_<frame>.svg`.
const figureFrames = <String, List<FigureFrame>>{
'''


def main():
    os.makedirs('assets/figures/frames', exist_ok=True)
    for f in os.listdir('assets/figures/frames'):
        os.remove(os.path.join('assets/figures/frames', f))
    dart = DART_HEAD
    for key, fn in MOVES.items():
        print(key)
        MUTE_FAR[0] = key not in ('reverseLunge', 'splitSquat')
        frames, seq, still = fn()
        fit = fit_for(frames)
        for pal, suf in ((LIGHT, ''), (DARK, '_dark')):
            for i, p in enumerate(frames):
                open(f'assets/figures/frames/{key}_{i}{suf}.svg', 'w').write(render(p, pal, fit))
            open(f'assets/figures/{key}{suf}.svg', 'w').write(render(frames[still], pal, fit))
        items = [f'FigureFrame({a}, {b})' for a, b in seq]
        one = f"  '{key}': [{', '.join(items)}],"
        dart += (one if len(one) <= 80 else f"  '{key}': [\n" + ''.join(f'    {i},\n' for i in items) + '  ],') + '\n'
    dart += '};\n'
    open('lib/widgets/figure_frames.dart', 'w').write(dart)


if __name__ == '__main__':
    main()
