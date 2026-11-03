// Moteur de montage : transforme une description JSON en commande ffmpeg, avec file de rendus
import { spawn } from 'node:child_process';
import fsp from 'node:fs/promises';
import path from 'node:path';
import { config } from './config.js';
import * as lib from './library.js';
import { probe, makeThumb, round } from './media.js';

const jobs = new Map();
let queue = Promise.resolve();

const ASPECTS = { '16:9': [16, 9], '9:16': [9, 16], '1:1': [1, 1], '4:5': [4, 5], '4:3': [4, 3] };
const XFADES = new Set([
  'fade', 'dissolve', 'wipeleft', 'wiperight', 'wipeup', 'wipedown', 'slideleft', 'slideright',
  'slideup', 'slidedown', 'circleopen', 'circleclose', 'radial', 'smoothleft', 'smoothright',
  'zoomin', 'fadeblack', 'fadewhite', 'pixelize', 'hblur', 'distance',
]);

const even = (x) => Math.max(2, Math.round(x / 2) * 2);

function atempoChain(speed) {
  const parts = [];
  let s = speed;
  while (s > 2) { parts.push('atempo=2'); s /= 2; }
  while (s < 0.5) { parts.push('atempo=0.5'); s /= 0.5; }
  if (Math.abs(s - 1) > 1e-3) parts.push(`atempo=${s.toFixed(4)}`);
  return parts;
}

function fitFilter(fit, W, H, inLabel, outLabel, idx) {
  const cover = `scale=${W}:${H}:force_original_aspect_ratio=increase,crop=${W}:${H}`;
  const contain = `scale=${W}:${H}:force_original_aspect_ratio=decrease,pad=${W}:${H}:(ow-iw)/2:(oh-ih)/2:color=black`;
  if (fit === 'cover') return `[${inLabel}]${cover}[${outLabel}]`;
  if (fit === 'contain') return `[${inLabel}]${contain}[${outLabel}]`;
  // 'blur' : image entière au centre, fond flouté rempli (idéal 16:9 → 9:16)
  return (
    `[${inLabel}]split[bgs${idx}][fgs${idx}];` +
    `[bgs${idx}]scale=${Math.round(W / 4)}:${Math.round(H / 4)}:force_original_aspect_ratio=increase,crop=${Math.round(W / 4)}:${Math.round(H / 4)},boxblur=10:2,scale=${W}:${H}[bg${idx}];` +
    `[fgs${idx}]scale=${W}:${H}:force_original_aspect_ratio=decrease[fg${idx}];` +
    `[bg${idx}][fg${idx}]overlay=(W-w)/2:(H-h)/2[${outLabel}]`
  );
}

async function writeTextFile(dir, text) {
  const f = path.join(dir, `t${lib.newId()}.txt`);
  await fsp.writeFile(f, text);
  return f;
}

function drawtext(textFile, H, { position = 'bottom', size = 'medium', color = 'white', box = true }) {
  const fs = Math.round(H * ({ small: 0.04, medium: 0.055, large: 0.08, huge: 0.11 }[size] || 0.055));
  const y = {
    top: `h*0.08`,
    center: `(h-text_h)/2`,
    bottom: `h-text_h-h*0.1`,
  }[position] || `h-text_h-h*0.1`;
  const esc = (s) => s.replace(/\\/g, '/').replace(/:/g, '\\:').replace(/'/g, "\\'");
  return (
    `drawtext=fontfile='${esc(config.font)}':textfile='${esc(textFile)}':fontsize=${fs}:fontcolor=${color}` +
    `:x=(w-text_w)/2:y=${y}:line_spacing=${Math.round(fs * 0.25)}` +
    (box ? `:box=1:boxcolor=black@0.45:boxborderw=${Math.round(fs * 0.35)}` : `:borderw=${Math.max(2, Math.round(fs / 14))}:bordercolor=black`)
  );
}

// Construit la commande ffmpeg complète à partir de la description du montage
export async function buildCommand(spec, outFile, workDir) {
  const clips = spec.clips;
  if (!clips?.length) throw new Error('Le montage doit contenir au moins un clip.');
  const draft = spec.quality === 'draft';
  const fps = spec.format?.fps || 30;
  const fit = spec.format?.fit || 'cover';

  // Résolution des clips + validation
  const resolved = [];
  for (const [i, c] of clips.entries()) {
    const item = lib.mustGet(c.media_id);
    if (item.type === 'audio') throw new Error(`Clip ${i + 1} : ${item.id} est un fichier audio (utilise "music").`);
    const speed = item.type === 'image' ? 1 : Math.min(4, Math.max(0.25, c.speed || 1));
    let start = 0, srcDur;
    if (item.type === 'image') {
      srcDur = c.duration || 3;
    } else {
      start = Math.max(0, c.start || 0);
      const end = Math.min(c.end ?? item.duration, item.duration);
      if (end - start < 0.1) throw new Error(`Clip ${i + 1} : intervalle invalide (${start} → ${end}, durée source ${item.duration}s).`);
      srcDur = end - start;
    }
    resolved.push({ c, item, speed, start, srcDur, dur: srcDur / speed });
  }

  // Dimensions de sortie
  let H = spec.format?.height || 1080;
  if (draft) H = Math.min(H, 480);
  let W;
  const aspect = spec.format?.aspect || '16:9';
  if (aspect === 'source') {
    const ref = resolved.find((r) => r.item.width) || resolved[0];
    const ratio = (ref.item.width || 16) / (ref.item.height || 9);
    if (ratio < 1) { W = even(H); H = even(H / ratio); } else W = even(H * ratio);
  } else {
    const [aw, ah] = ASPECTS[aspect] || ASPECTS['16:9'];
    // "height" = petit côté pour les formats verticaux, pour garder une qualité cohérente
    if (aw < ah) { W = even(H); H = even((H * ah) / aw); } else { W = even((H * aw) / ah); H = even(H); }
  }

  const args = ['-y', '-hide_banner'];
  const filters = [];

  resolved.forEach((r, i) => {
    if (r.item.type === 'image') {
      args.push('-loop', '1', '-framerate', String(fps), '-t', String(r.dur), '-i', lib.mediaPath(r.item));
    } else {
      args.push('-ss', String(r.start), '-t', String(r.srcDur), '-i', lib.mediaPath(r.item));
    }
  });

  for (const [i, r] of resolved.entries()) {
    const pre = `[${i}:v]setpts=(PTS-STARTPTS)/${r.speed},fps=${fps}[pv${i}]`;
    filters.push(pre);
    filters.push(fitFilter(fit, W, H, `pv${i}`, `fv${i}`, i));
    let post = `[fv${i}]setsar=1,format=yuv420p,tpad=stop_mode=clone:stop_duration=1,trim=duration=${r.dur.toFixed(3)},setpts=PTS-STARTPTS`;
    if (r.c.text) {
      const tf = await writeTextFile(workDir, r.c.text);
      post += ',' + drawtext(tf, H, { position: r.c.text_position, size: r.c.text_size });
    }
    filters.push(post + `[v${i}]`);

    const vol = r.c.mute ? 0 : (r.c.volume ?? 1);
    if (r.item.type === 'video' && r.item.hasAudio && vol > 0) {
      const chain = [
        'asetpts=PTS-STARTPTS', ...atempoChain(r.speed), `volume=${vol}`,
        'aresample=48000', 'aformat=sample_fmts=fltp:channel_layouts=stereo',
        'apad', `atrim=duration=${r.dur.toFixed(3)}`, 'asetpts=PTS-STARTPTS',
      ];
      filters.push(`[${i}:a]${chain.join(',')}[a${i}]`);
    } else {
      filters.push(`anullsrc=r=48000:cl=stereo,atrim=duration=${r.dur.toFixed(3)},aformat=sample_fmts=fltp:channel_layouts=stereo[a${i}]`);
    }
  }

  // Enchaînement des clips
  const tType = spec.transition?.type || 'none';
  let total;
  if (resolved.length === 1) {
    filters.push(`[v0]null[vc]`, `[a0]anull[ac]`);
    total = resolved[0].dur;
  } else if (tType === 'none') {
    filters.push(`${resolved.map((_, i) => `[v${i}][a${i}]`).join('')}concat=n=${resolved.length}:v=1:a=1[vc][ac]`);
    total = resolved.reduce((s, r) => s + r.dur, 0);
  } else {
    const xt = XFADES.has(tType) ? tType : 'fade';
    const minDur = Math.min(...resolved.map((r) => r.dur));
    const td = Math.min(spec.transition?.duration ?? 0.5, minDur / 2.2);
    let vPrev = 'v0', aPrev = 'a0';
    let len = resolved[0].dur;
    for (let i = 1; i < resolved.length; i++) {
      const vo = i === resolved.length - 1 ? 'vc' : `vx${i}`;
      const ao = i === resolved.length - 1 ? 'ac' : `ax${i}`;
      filters.push(`[${vPrev}][v${i}]xfade=transition=${xt}:duration=${td.toFixed(3)}:offset=${(len - td).toFixed(3)}[${vo}]`);
      filters.push(`[${aPrev}][a${i}]acrossfade=d=${td.toFixed(3)}[${ao}]`);
      len = len + resolved[i].dur - td;
      vPrev = vo; aPrev = ao;
    }
    total = len;
  }

  // Textes sur la timeline globale, fondu d'ouverture / de fin
  const vPost = [];
  for (const t of spec.texts || []) {
    const tf = await writeTextFile(workDir, t.text);
    const s = Math.max(0, t.start ?? 0);
    const e = Math.min(total, t.end ?? total);
    vPost.push(drawtext(tf, H, t) + `:enable='between(t,${s.toFixed(2)},${e.toFixed(2)})'`);
  }
  const aPost = [];
  if (spec.fade_in) { vPost.push(`fade=t=in:st=0:d=${spec.fade_in}`); aPost.push(`afade=t=in:st=0:d=${spec.fade_in}`); }
  if (spec.fade_out) {
    const st = Math.max(0, total - spec.fade_out).toFixed(3);
    vPost.push(`fade=t=out:st=${st}:d=${spec.fade_out}`); aPost.push(`afade=t=out:st=${st}:d=${spec.fade_out}`);
  }
  filters.push(`[vc]${vPost.length ? vPost.join(',') : 'null'}[vout]`);

  // Musique de fond
  if (spec.music?.media_id) {
    const m = lib.mustGet(spec.music.media_id);
    if (!m.hasAudio && m.type !== 'audio') throw new Error(`La musique ${m.id} n'a pas de piste audio.`);
    const mi = resolved.length;
    args.push('-stream_loop', '-1', '-ss', String(spec.music.start || 0), '-i', lib.mediaPath(m));
    const mv = spec.music.volume ?? 0.6;
    const mfo = Math.min(spec.music.fade_out ?? 2, total / 2);
    filters.push(
      `[${mi}:a]aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo,volume=${mv},atrim=duration=${total.toFixed(3)},asetpts=PTS-STARTPTS,` +
        `afade=t=out:st=${Math.max(0, total - mfo).toFixed(3)}:d=${mfo.toFixed(3)}[mus]`
    );
    if (spec.music.duck) {
      filters.push(`[ac]asplit[acm][acs]`);
      filters.push(`[mus][acs]sidechaincompress=threshold=0.03:ratio=10:attack=20:release=400[musd]`);
      filters.push(`[acm][musd]amix=inputs=2:duration=first:normalize=0[amixed]`);
    } else {
      filters.push(`[ac][mus]amix=inputs=2:duration=first:normalize=0[amixed]`);
    }
    filters.push(`[amixed]${[...aPost, 'alimiter=limit=0.95'].join(',')}[aout]`);
  } else {
    filters.push(`[ac]${aPost.length ? aPost.join(',') : 'anull'}[aout]`);
  }

  args.push(
    '-filter_complex', filters.join(';'),
    '-map', '[vout]', '-map', '[aout]',
    '-c:v', 'libx264', '-preset', draft ? 'ultrafast' : 'veryfast', '-crf', draft ? '30' : '20',
    '-pix_fmt', 'yuv420p', '-r', String(fps),
    '-c:a', 'aac', '-b:a', draft ? '96k' : '192k',
    '-t', total.toFixed(3),
    '-movflags', '+faststart', '-progress', 'pipe:1', '-nostats',
    outFile,
  );
  return { args, total, width: W, height: H };
}

export function getJob(id) {
  return jobs.get(id) || null;
}

export function listJobs() {
  return [...jobs.values()].sort((a, b) => b.createdAt.localeCompare(a.createdAt)).slice(0, 30);
}

export function startMontage(spec) {
  const job = {
    id: 'job_' + lib.newId(),
    status: 'queued',
    progress: 0,
    name: spec.name || 'Montage',
    createdAt: new Date().toISOString(),
    error: null,
    resultId: null,
  };
  jobs.set(job.id, job);
  queue = queue.then(() => runJob(job, spec)).catch(() => {});
  return job;
}

async function runJob(job, spec) {
  const id = lib.newId();
  const workDir = path.join(lib.tmpDir(), job.id);
  await fsp.mkdir(workDir, { recursive: true });
  const outFile = lib.storagePathFor(id, '.mp4');
  try {
    job.status = 'running';
    const { args, total } = await buildCommand(spec, outFile, workDir);
    job.expectedDuration = round(total);
    await new Promise((resolve, reject) => {
      const p = spawn('ffmpeg', args, { stdio: ['ignore', 'pipe', 'pipe'] });
      let err = '';
      p.stdout.on('data', (d) => {
        const m = d.toString().match(/out_time_ms=(\d+)/g);
        if (m) {
          const us = Number(m[m.length - 1].split('=')[1]);
          job.progress = Math.min(99, Math.round((us / 1e6 / total) * 100));
        }
      });
      p.stderr.on('data', (d) => { err += d; if (err.length > 100000) err = err.slice(-50000); });
      p.on('error', reject);
      p.on('close', (code) => (code === 0 ? resolve() : reject(new Error(err.slice(-2000)))));
    });
    const info = await probe(outFile);
    const item = {
      id,
      file: path.basename(outFile),
      name: spec.name || 'Montage',
      originalName: (spec.name || 'montage') + '.mp4',
      type: 'video',
      kind: 'montage',
      mime: 'video/mp4',
      notes: spec.notes || '',
      tags: ['montage'],
      ...info,
      spec,
      createdAt: new Date().toISOString(),
    };
    item.hasThumb = await makeThumb(item, outFile, lib.thumbPath(item)).catch(() => false);
    await lib.add(item);
    job.status = 'done';
    job.progress = 100;
    job.resultId = id;
  } catch (e) {
    job.status = 'error';
    job.error = String(e.message || e);
    await fsp.rm(outFile, { force: true });
  } finally {
    await fsp.rm(workDir, { recursive: true, force: true });
  }
}

export async function waitForJob(job, ms) {
  const t0 = Date.now();
  while (Date.now() - t0 < ms && (job.status === 'queued' || job.status === 'running')) {
    await new Promise((r) => setTimeout(r, 500));
  }
  return job;
}
