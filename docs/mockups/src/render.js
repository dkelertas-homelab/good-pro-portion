const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');
const { frameBetween, figures } = require('./figures');

const SRC = __dirname;
const OUT = path.join(__dirname, '..');
const W = 412, H = 915, SCALE = 2;

async function shot(browser, htmlName, outName) {
  const page = await browser.newPage({ viewport: { width: W, height: H }, deviceScaleFactor: SCALE });
  await page.goto('file://' + path.join(SRC, htmlName), { waitUntil: 'networkidle' });
  await page.waitForTimeout(80);
  await page.screenshot({ path: path.join(OUT, outName), type: 'png' });
  await page.close();
  console.log('shot', outName);
}

async function contactSheet(browser, files, outName, title, subtitle) {
  const thumbs = files.map(([f, label]) => {
    const b64 = fs.readFileSync(path.join(OUT, f)).toString('base64');
    return `<div class="cell"><img src="data:image/png;base64,${b64}"/><div class="label">${label}</div></div>`;
  }).join('');
  const html = `<!DOCTYPE html><html><head><style>
    body{margin:0;padding:32px;background:#E8ECF1;font-family:Inter,system-ui,sans-serif}
    h1{font-size:28px;margin:0 0 6px;color:#1A1D23}
    .sub{color:#5C6570;margin-bottom:24px}
    .grid{display:grid;grid-template-columns:repeat(6,1fr);gap:20px}
    .cell{background:#fff;border-radius:16px;padding:12px;box-shadow:0 2px 10px rgba(0,0,0,.06)}
    .cell img{width:100%;height:auto;border-radius:10px;display:block;border:1px solid #EEF1F5}
    .label{text-align:center;font-weight:700;font-size:13px;margin-top:10px;color:#1A1D23}
  </style></head><body>
  <h1>${title}</h1>
  <p class="sub">${subtitle}</p>
  <div class="grid">${thumbs}</div></body></html>`;
  const tmp = path.join(SRC, '_contact_tmp.html');
  fs.writeFileSync(tmp, html);
  const page = await browser.newPage({ viewport: { width: 1600, height: 1200 }, deviceScaleFactor: 2 });
  await page.goto('file://' + tmp, { waitUntil: 'networkidle' });
  const height = await page.evaluate(() => document.body.scrollHeight + 40);
  await page.setViewportSize({ width: 1600, height: Math.min(height, 2400) });
  await page.screenshot({ path: path.join(OUT, outName), type: 'png', fullPage: true });
  await page.close();
  fs.unlinkSync(tmp);
  console.log('sheet', outName);
}

async function makeSmoothGifs(browser) {
  const anims = [
    { name: 'squat', from: 'squatUp', to: 'squat' },
    { name: 'pushup', from: 'pushup', to: 'pushupDown' },
    { name: 'glute-bridge', from: 'gluteBridgeDown', to: 'gluteBridge' },
  ];
  const STEPS = 7; // 0..1 inclusive → 8 frames one way; ping-pong
  const page = await browser.newPage({ viewport: { width: 320, height: 320 }, deviceScaleFactor: 2 });
  const tmpDir = path.join(OUT, '_anim_frames');
  fs.mkdirSync(tmpDir, { recursive: true });

  for (const anim of anims) {
    const frameFiles = [];
    // forward
    for (let i = 0; i <= STEPS; i++) {
      const t = i / STEPS;
      const svg = frameBetween(anim.from, anim.to, t, 260, 'teal');
      const html = `<!DOCTYPE html><html><body style="margin:0;background:#CCFBF1;display:flex;align-items:center;justify-content:center;width:320px;height:320px;">${svg}</body></html>`;
      const hf = path.join(tmpDir, `${anim.name}_${String(i).padStart(2,'0')}.html`);
      fs.writeFileSync(hf, html);
      await page.goto('file://' + hf);
      await page.waitForTimeout(30);
      const pf = path.join(tmpDir, `${anim.name}_${String(i).padStart(2,'0')}.png`);
      await page.screenshot({ path: pf, type: 'png' });
      frameFiles.push(pf);
    }
    // ping-pong: reverse without duplicating endpoints
    const pingpong = [...frameFiles, ...frameFiles.slice(1, -1).reverse()];

    // filmstrip (4 key samples)
    const samples = [0, Math.floor(STEPS/3), Math.floor(2*STEPS/3), STEPS];
    const stripHtml = `<!DOCTYPE html><html><body style="margin:0;background:#F7F8FA;display:flex;gap:12px;padding:16px;align-items:center;">
      ${samples.map((si, idx) => {
        const svg = frameBetween(anim.from, anim.to, si/STEPS, 140, 'teal');
        return `<div style="background:#CCFBF1;border-radius:16px;padding:8px;text-align:center;">
          <div style="font:600 11px Inter,sans-serif;color:#0F766E;margin-bottom:4px;">Frame ${idx+1}</div>${svg}</div>`;
      }).join('')}
      <div style="font:700 14px Inter,sans-serif;color:#1A1D23;padding:0 8px;">${anim.name}<br/><span style="font-weight:500;color:#5C6570;font-size:12px;">smooth loop</span></div>
    </body></html>`;
    fs.writeFileSync(path.join(tmpDir, `strip_${anim.name}.html`), stripHtml);
    await page.setViewportSize({ width: 720, height: 200 });
    await page.goto('file://' + path.join(tmpDir, `strip_${anim.name}.html`));
    await page.screenshot({ path: path.join(OUT, `anim-${anim.name}-strip.png`), type: 'png' });
    await page.setViewportSize({ width: 320, height: 320 });

    // GIF via ffmpeg or convert
    const gif = path.join(OUT, `anim-${anim.name}.gif`);
    let tool = null;
    try { execSync('which convert', {stdio:'pipe'}); tool = 'convert'; } catch {}
    if (!tool) { try { execSync('which magick', {stdio:'pipe'}); tool = 'magick'; } catch {} }
    if (!tool) { try { execSync('which ffmpeg', {stdio:'pipe'}); tool = 'ffmpeg'; } catch {} }

    if (tool === 'convert' || tool === 'magick') {
      const cmd = tool === 'magick' ? 'magick' : 'convert';
      // delay 8 = 80ms per frame ≈ smooth
      execSync(`${cmd} -delay 8 -loop 0 ${pingpong.map(f => `"${f}"`).join(' ')} "${gif}"`);
    } else if (tool === 'ffmpeg') {
      // copy frames into numbered sequence for ffmpeg
      const seqDir = path.join(tmpDir, `seq_${anim.name}`);
      fs.mkdirSync(seqDir, { recursive: true });
      pingpong.forEach((f, i) => fs.copyFileSync(f, path.join(seqDir, `f${String(i).padStart(3,'0')}.png`)));
      execSync(`ffmpeg -y -framerate 12 -i "${seqDir}/f%03d.png" -vf "scale=320:-1:flags=lanczos,split[s0][s1];[s0]palettegen=max_colors=64[p];[s1][p]paletteuse" "${gif}"`, {stdio:'pipe'});
    }
    console.log('gif', anim.name, 'frames', pingpong.length);
  }
  await page.close();
  // cleanup
  execSync(`rm -rf "${tmpDir}"`);
}

(async () => {
  const browser = await chromium.launch();
  const manifest = JSON.parse(fs.readFileSync(path.join(SRC, 'screens.json'), 'utf8'));

  for (const name of manifest.light) {
    await shot(browser, `${name}.html`, `${name}.png`);
  }
  for (const name of manifest.dark) {
    await shot(browser, `${name}.html`, `${name}.png`);
  }
  // alt-style aliases
  fs.copyFileSync(path.join(OUT, 'dark-01-home.png'), path.join(OUT, 'alt-style-home.png'));
  fs.copyFileSync(path.join(OUT, 'dark-04-timer-work.png'), path.join(OUT, 'alt-style-timer.png'));

  await makeSmoothGifs(browser);

  const labels = [
    ['01-home.png','Home'],['02-routine.png','Routine'],['03-exercise.png','Exercise'],
    ['04-timer-work.png','Timer · work'],['05-timer-rest.png','Timer · rest'],
    ['06-done.png','Done'],['07-meals.png','Meals'],['08-settings.png','Settings'],
    ['09-remove-ads.png','Remove ads'],
    ['10-reminders-setup.png','Reminders setup'],['11-reminder-notification.png','Reminder notif'],
  ];
  await contactSheet(browser, labels, 'contact-sheet.png',
    'Nice Pro Portions — Phase 1 mockups (light teal)',
    'Default theme · Round 2 figures · 24 Sep 2026 · for David to review');
  await contactSheet(browser, labels.map(([f,l]) => ['dark-' + f, l]), 'contact-sheet-dark.png',
    'Nice Pro Portions — Phase 1 mockups (dark coral)',
    'Dark mode · Round 2 figures · 24 Sep 2026 · for David to review');

  await browser.close();
  console.log('ALL DONE');
})().catch(e => { console.error(e); process.exit(1); });
