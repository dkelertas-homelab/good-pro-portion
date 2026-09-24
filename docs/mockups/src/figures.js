/**
 * Flat figure with rounded limbs + body mass.
 * Own artwork. colour: teal (light) or coral (dark).
 */
const THEMES = {
  teal:  { fill: '#0F766E', soft: '#14B8A6', ground: 'rgba(15,118,110,0.28)' },
  coral: { fill: '#FF6B4A', soft: '#FF8A70', ground: 'rgba(255,107,74,0.35)' },
};

function lerp(a, b, t) { return a + (b - a) * t; }
function lerpPt(a, b, t) { return [lerp(a[0], b[0], t), lerp(a[1], b[1], t)]; }

/** Draw a capsule limb from (x1,y1) to (x2,y2) */
function limb(x1, y1, x2, y2, w, color) {
  return `<line x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}" stroke="${color}" stroke-width="${w}" stroke-linecap="round"/>`;
}
function joint(cx, cy, r, color) {
  return `<circle cx="${cx}" cy="${cy}" r="${r}" fill="${color}"/>`;
}
function head(cx, cy, r, color) {
  return `<circle cx="${cx}" cy="${cy}" r="${r}" fill="${color}"/>`;
}
function torso(x, y, w, h, color) {
  // rounded body mass
  const rx = w / 2, ry = Math.min(h / 2, 18);
  return `<rect x="${x - w/2}" y="${y}" width="${w}" height="${h}" rx="${rx}" ry="${ry}" fill="${color}"/>`;
}
function ground(cx, cy, rx = 28) {
  return `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="5" fill="currentColor" opacity="0.2"/>`;
}

/**
 * Pose is a set of named points. Render with body mass between neck and hips.
 * Points: head, neck, hip, lShoulder, rShoulder, lElbow, rElbow, lHand, rHand,
 *         lKnee, rKnee, lFoot, rFoot
 */
function renderPose(pose, size = 200, themeName = 'teal') {
  const T = THEMES[themeName] || THEMES.teal;
  const C = T.fill;
  const headR = pose.headR ?? 16;
  const limbW = pose.limbW ?? 16;
  const armW = pose.armW ?? 14;
  const torsoW = pose.torsoW ?? 32;
  const [nx, ny] = pose.neck;
  const [hx, hy] = pose.hip;
  // torso centre along neck→hip
  const torsoH = Math.max(22, Math.hypot(hx - nx, hy - ny) * 0.92);
  const torsoY = ny + 2;

  const parts = [];
  // soft ground if requested
  if (pose.ground) {
    parts.push(`<ellipse cx="${pose.ground[0]}" cy="${pose.ground[1]}" rx="${pose.ground[2] || 36}" ry="6" fill="${C}" opacity="0.18"/>`);
  }
  // legs first (behind)
  parts.push(limb(...pose.hip, ...pose.lKnee, limbW, C));
  parts.push(limb(...pose.hip, ...pose.rKnee, limbW, C));
  parts.push(limb(...pose.lKnee, ...pose.lFoot, limbW, C));
  parts.push(limb(...pose.rKnee, ...pose.rFoot, limbW, C));
  parts.push(joint(...pose.lKnee, 8, C));
  parts.push(joint(...pose.rKnee, 8, C));
  parts.push(joint(...pose.lFoot, 6, C));
  parts.push(joint(...pose.rFoot, 6, C));
  // torso mass
  // orient torso roughly toward hip
  const angle = Math.atan2(hy - ny, hx - nx) * 180 / Math.PI - 90;
  const midX = (nx + hx) / 2;
  const midY = (ny + hy) / 2;
  parts.push(`<g transform="rotate(${angle} ${midX} ${midY})">
    <rect x="${midX - torsoW/2}" y="${midY - torsoH/2}" width="${torsoW}" height="${torsoH}" rx="${torsoW/2}" fill="${C}"/>
  </g>`);
  // arms
  parts.push(limb(...pose.lShoulder, ...pose.lElbow, armW, C));
  parts.push(limb(...pose.rShoulder, ...pose.rElbow, armW, C));
  parts.push(limb(...pose.lElbow, ...pose.lHand, armW, C));
  parts.push(limb(...pose.rElbow, ...pose.rHand, armW, C));
  parts.push(joint(...pose.lElbow, 6, C));
  parts.push(joint(...pose.rElbow, 6, C));
  parts.push(joint(...pose.lHand, 5.5, C));
  parts.push(joint(...pose.rHand, 5.5, C));
  // shoulders / hip joints
  parts.push(joint(...pose.lShoulder, 8, C));
  parts.push(joint(...pose.rShoulder, 8, C));
  parts.push(joint(...pose.hip, 9, C));
  // head
  parts.push(head(...pose.head, headR, C));
  // props
  if (pose.props) parts.push(pose.props(T));

  return `<svg viewBox="0 0 200 200" width="${size}" height="${size}" xmlns="http://www.w3.org/2000/svg">${parts.join('')}</svg>`;
}

function lerpPose(a, b, t) {
  const keys = ['head','neck','hip','lShoulder','rShoulder','lElbow','rElbow','lHand','rHand','lKnee','rKnee','lFoot','rFoot'];
  const out = { ...a, props: undefined, ground: a.ground && b.ground
    ? [lerp(a.ground[0], b.ground[0], t), lerp(a.ground[1], b.ground[1], t), lerp(a.ground[2]||36, b.ground[2]||36, t)]
    : (a.ground || b.ground) };
  for (const k of keys) {
    if (a[k] && b[k]) out[k] = lerpPt(a[k], b[k], t);
  }
  out.headR = lerp(a.headR ?? 15, b.headR ?? 15, t);
  out.limbW = lerp(a.limbW ?? 14, b.limbW ?? 14, t);
  out.armW = lerp(a.armW ?? 12, b.armW ?? 12, t);
  out.torsoW = lerp(a.torsoW ?? 28, b.torsoW ?? 28, t);
  return out;
}

// ---------- Pose library ----------
const poses = {
  // standing / squat up
  squatUp: {
    head:[100,28], neck:[100,44], hip:[100,100],
    lShoulder:[82,52], rShoulder:[118,52],
    lElbow:[70,78], rElbow:[130,78],
    lHand:[64,100], rHand:[136,100],
    lKnee:[88,145], rKnee:[112,145],
    lFoot:[84,178], rFoot:[116,178],
    ground:[100,182,40],
  },
  // deep squat
  squat: {
    head:[100,48], neck:[100,64], hip:[100,108],
    lShoulder:[80,72], rShoulder:[120,72],
    lElbow:[68,92], rElbow:[132,92],
    lHand:[62,112], rHand:[138,112],
    lKnee:[70,138], rKnee:[130,138],
    lFoot:[62,178], rFoot:[138,178],
    ground:[100,182,48],
  },
  // high plank / push-up start
  pushup: {
    head:[38,78], neck:[52,86], hip:[118,92],
    lShoulder:[58,88], rShoulder:[58,88],
    lElbow:[48,118], rElbow:[52,118],
    lHand:[42,138], rHand:[48,138],
    lKnee:[145,100], rKnee:[150,100],
    lFoot:[168,138], rFoot:[175,138],
    ground:[110,142,70], torsoW: 26,
  },
  // push-up bottom
  pushupDown: {
    head:[44,108], neck:[58,112], hip:[120,116],
    lShoulder:[64,114], rShoulder:[64,114],
    lElbow:[50,128], rElbow:[54,128],
    lHand:[42,142], rHand:[48,142],
    lKnee:[145,120], rKnee:[150,120],
    lFoot:[168,142], rFoot:[175,142],
    ground:[110,146,70], torsoW: 26,
  },
  inclinePushup: {
    head:[42,92], neck:[56,96], hip:[115,88],
    lShoulder:[62,96], rShoulder:[62,96],
    lElbow:[78,108], rElbow:[82,108],
    lHand:[100,78], rHand:[105,78],
    lKnee:[140,105], rKnee:[145,105],
    lFoot:[160,140], rFoot:[168,140],
    ground:[120,144,55],
    props: (T) => `<rect x="100" y="68" width="55" height="14" rx="4" fill="${T.soft}" opacity="0.55"/>`,
  },
  reverseLunge: {
    head:[108,26], neck:[108,42], hip:[100,98],
    lShoulder:[92,50], rShoulder:[124,50],
    lElbow:[80,78], rElbow:[138,72],
    lHand:[74,102], rHand:[148,92],
    lKnee:[78,140], rKnee:[132,148],
    lFoot:[70,178], rFoot:[155,178],
    ground:[110,182,55],
  },
  splitSquat: {
    head:[100,30], neck:[100,46], hip:[100,100],
    lShoulder:[84,54], rShoulder:[116,54],
    lElbow:[72,80], rElbow:[128,80],
    lHand:[66,104], rHand:[134,104],
    lKnee:[68,142], rKnee:[138,145],
    lFoot:[58,178], rFoot:[150,178],
    ground:[105,182,55],
  },
  gluteBridgeDown: {
    head:[40,118], neck:[55,118], hip:[115,122],
    lShoulder:[58,122], rShoulder:[58,122],
    lElbow:[48,140], rElbow:[52,140],
    lHand:[42,152], rHand:[48,152],
    lKnee:[145,125], rKnee:[150,125],
    lFoot:[158,152], rFoot:[168,152],
    ground:[105,156,65], torsoW: 26,
  },
  gluteBridge: {
    head:[40,112], neck:[55,108], hip:[112,82],
    lShoulder:[58,110], rShoulder:[58,110],
    lElbow:[48,135], rElbow:[52,135],
    lHand:[42,150], rHand:[48,150],
    lKnee:[142,115], rKnee:[148,115],
    lFoot:[158,150], rFoot:[168,150],
    ground:[105,154,65], torsoW: 26,
  },
  plank: {
    head:[36,88], neck:[50,94], hip:[120,96],
    lShoulder:[56,96], rShoulder:[56,96],
    lElbow:[48,124], rElbow:[52,124],
    lHand:[44,142], rHand:[50,142],
    lKnee:[148,102], rKnee:[152,102],
    lFoot:[168,142], rFoot:[176,142],
    ground:[110,146,70], torsoW: 26,
  },
  sidePlank: {
    head:[48,58], neck:[58,72], hip:[130,98],
    lShoulder:[62,80], rShoulder:[70,78],
    lElbow:[55,115], rElbow:[95,60],
    lHand:[50,142], rHand:[100,42],
    lKnee:[150,105], rKnee:[155,100],
    lFoot:[172,118], rFoot:[168,108],
    ground:[100,146,55], torsoW: 24,
  },
  superman: {
    head:[42,88], neck:[56,94], hip:[120,100],
    lShoulder:[62,92], rShoulder:[62,96],
    lElbow:[40,72], rElbow:[45,78],
    lHand:[28,58], rHand:[32,66],
    lKnee:[145,88], rKnee:[150,94],
    lFoot:[172,70], rFoot:[175,80],
    ground:[105,118,55], torsoW: 26,
  },
  deadBug: {
    head:[55,58], neck:[65,72], hip:[110,108],
    lShoulder:[72,78], rShoulder:[78,74],
    lElbow:[55,55], rElbow:[100,50],
    lHand:[42,40], rHand:[118,38],
    lKnee:[140,85], rKnee:[130,130],
    lFoot:[165,70], rFoot:[148,152],
    ground:[100,158,50], torsoW: 26,
  },
  shoulderTap: {
    head:[40,78], neck:[54,86], hip:[120,92],
    lShoulder:[58,88], rShoulder:[62,86],
    lElbow:[48,120], rElbow:[88,68],
    lHand:[42,140], rHand:[78,58],
    lKnee:[148,100], rKnee:[152,100],
    lFoot:[168,140], rFoot:[176,140],
    ground:[110,144,70], torsoW: 26,
  },
  wallSit: {
    head:[118,32], neck:[118,48], hip:[118,102],
    lShoulder:[102,56], rShoulder:[118,56],
    lElbow:[88,82], rElbow:[130,82],
    lHand:[80,106], rHand:[138,106],
    lKnee:[95,138], rKnee:[140,138],
    lFoot:[88,178], rFoot:[148,178],
    ground:[118,182,40],
    props: (T) => `<rect x="152" y="18" width="10" height="165" rx="3" fill="${T.soft}" opacity="0.45"/>`,
  },
  birdDog: {
    head:[48,78], neck:[60,88], hip:[118,96],
    lShoulder:[68,90], rShoulder:[72,88],
    lElbow:[52,118], rElbow:[50,68],
    lHand:[48,140], rHand:[38,55],
    lKnee:[140,120], rKnee:[145,92],
    lFoot:[148,142], rFoot:[172,70],
    ground:[100,146,55], torsoW: 26,
  },
  march: {
    head:[100,26], neck:[100,42], hip:[100,100],
    lShoulder:[84,50], rShoulder:[116,50],
    lElbow:[72,42], rElbow:[130,78],
    lHand:[66,28], rHand:[138,102],
    lKnee:[88,148], rKnee:[122,128],
    lFoot:[84,178], rFoot:[128,155],
    ground:[100,182,40],
  },
  goodMorning: {
    head:[68,48], neck:[78,62], hip:[110,100],
    lShoulder:[72,68], rShoulder:[90,64],
    lElbow:[62,90], rElbow:[100,88],
    lHand:[58,112], rHand:[108,110],
    lKnee:[100,145], rKnee:[122,145],
    lFoot:[94,178], rFoot:[128,178],
    ground:[110,182,40],
  },
  armCircles: {
    head:[100,30], neck:[100,46], hip:[100,102],
    lShoulder:[82,52], rShoulder:[118,52],
    lElbow:[52,48], rElbow:[148,48],
    lHand:[38,42], rHand:[162,42],
    lKnee:[88,148], rKnee:[112,148],
    lFoot:[84,178], rFoot:[116,178],
    ground:[100,182,40],
    props: (T) => `
      <circle cx="38" cy="42" r="20" fill="none" stroke="${T.soft}" stroke-width="3" stroke-dasharray="5 4" opacity="0.75"/>
      <circle cx="162" cy="42" r="20" fill="none" stroke="${T.soft}" stroke-width="3" stroke-dasharray="5 4" opacity="0.75"/>`,
  },
  // calm breathe pose for rest — seated cross-legged-ish / kneeling calm
  breathe: {
    head:[100,42], neck:[100,58], hip:[100,118],
    lShoulder:[80,66], rShoulder:[120,66],
    lElbow:[62,88], rElbow:[138,88],
    lHand:[78,108], rHand:[122,108],
    lKnee:[70,140], rKnee:[130,140],
    lFoot:[78,158], rFoot:[122,158],
    ground:[100,164,45], torsoW: 30,
    props: (T) => `
      <path d="M70 28 Q100 8 130 28" fill="none" stroke="${T.soft}" stroke-width="3" stroke-linecap="round" opacity="0.7"/>
      <path d="M78 20 Q100 4 122 20" fill="none" stroke="${T.soft}" stroke-width="2.5" stroke-linecap="round" opacity="0.5"/>`,
  },
};

/** Public API matching previous names */
function makeFigure(poseName, size = 200, theme = 'teal') {
  const pose = poses[poseName];
  if (!pose) throw new Error('Unknown pose ' + poseName);
  return renderPose(pose, size, theme);
}

const figures = {};
for (const name of Object.keys(poses)) {
  figures[name] = (size = 200, theme = 'teal') => makeFigure(name, size, theme);
}

/** Build interpolated SVG frames between two poses (t in 0..1) */
function frameBetween(fromName, toName, t, size = 200, theme = 'teal') {
  return renderPose(lerpPose(poses[fromName], poses[toName], t), size, theme);
}

module.exports = { figures, poses, frameBetween, renderPose, lerpPose, THEMES };
