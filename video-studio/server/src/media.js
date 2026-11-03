// Outils ffmpeg / ffprobe : analyse, miniatures, images, planches, détection de scènes et de silences
import { spawn } from 'node:child_process';
import fsp from 'node:fs/promises';
import path from 'node:path';
import { config } from './config.js';
import { tmpDir, newId } from './library.js';

export function run(cmd, args, { onStderr, timeoutMs = 0 } = {}) {
  return new Promise((resolve, reject) => {
    const p = spawn(cmd, args, { stdio: ['ignore', 'pipe', 'pipe'] });
    const out = [];
    let err = '';
    let timer;
    if (timeoutMs) timer = setTimeout(() => p.kill('SIGKILL'), timeoutMs);
    p.stdout.on('data', (d) => out.push(d));
    p.stderr.on('data', (d) => {
      const s = d.toString();
      err += s;
      if (err.length > 200000) err = err.slice(-100000);
      onStderr?.(s);
    });
    p.on('error', reject);
    p.on('close', (code) => {
      clearTimeout(timer);
      if (code === 0) resolve({ stdout: Buffer.concat(out), stderr: err });
      else reject(new Error(`${cmd} a échoué (code ${code}) : ${err.slice(-1500)}`));
    });
  });
}

export async function probe(file) {
  const { stdout } = await run('ffprobe', [
    '-v', 'error', '-print_format', 'json', '-show_format', '-show_streams', file,
  ]);
  const j = JSON.parse(stdout.toString());
  const v = j.streams.find((s) => s.codec_type === 'video' && !s.disposition?.attached_pic);
  const a = j.streams.find((s) => s.codec_type === 'audio');
  let fps = null;
  if (v?.avg_frame_rate && v.avg_frame_rate !== '0/0') {
    const [n, d] = v.avg_frame_rate.split('/').map(Number);
    if (d) fps = Math.round((n / d) * 100) / 100;
  }
  // Rotation (vidéos de téléphone en portrait)
  let rotation = 0;
  const sd = v?.side_data_list?.find((x) => x.rotation !== undefined);
  if (sd) rotation = Number(sd.rotation);
  else if (v?.tags?.rotate) rotation = Number(v.tags.rotate);
  let width = v?.width ?? null;
  let height = v?.height ?? null;
  if (Math.abs(rotation) % 180 === 90) [width, height] = [height, width];
  return {
    duration: j.format?.duration ? Math.round(Number(j.format.duration) * 1000) / 1000 : null,
    width,
    height,
    fps,
    videoCodec: v?.codec_name ?? null,
    hasAudio: !!a,
    audioCodec: a?.codec_name ?? null,
    sizeBytes: Number(j.format?.size || 0),
    bitrate: Number(j.format?.bit_rate || 0),
    creationTime: j.format?.tags?.creation_time ?? null,
  };
}

export async function makeThumb(item, src, dest) {
  if (item.type === 'audio') return false;
  const t = item.type === 'video' ? Math.min(1, (item.duration || 0) / 2) : 0;
  await run('ffmpeg', [
    '-y', ...seek(t), '-i', src, '-frames:v', '1',
    '-vf', 'scale=480:-2', '-q:v', '5', dest,
  ]);
  return true;
}

// "-ss 0" sur une photo ne produit aucune image : on ne cherche que si t > 0
const seek = (t) => (t > 0 ? ['-ss', String(t)] : []);

function tmpFile(ext) {
  return path.join(tmpDir(), `${newId()}${ext}`);
}

// Une image à un instant donné (JPEG en base64)
export async function frameAt(src, time, width = 768) {
  const out = tmpFile('.jpg');
  try {
    await run('ffmpeg', [
      '-y', ...seek(time), '-i', src, '-frames:v', '1',
      '-vf', `scale=${width}:-2`, '-q:v', '4', out,
    ]);
    return (await fsp.readFile(out)).toString('base64');
  } finally {
    await fsp.rm(out, { force: true });
  }
}

// Planche contact : N images réparties entre start et end, avec horodatage incrusté
export async function storyboard(src, { start, end, columns, rows, tileWidth = 320, aspect = 16 / 9 }) {
  const n = columns * rows;
  // Vignettes au format de la vidéo (verticales pour une vidéo de téléphone)
  const tileH = Math.round(Math.min(tileWidth * 1.8, tileWidth / aspect) / 2) * 2;
  const span = Math.max(0.1, end - start);
  const step = span / n;
  const outs = [];
  try {
    for (let i = 0; i < n; i++) {
      const t = start + step * (i + 0.5);
      const f = tmpFile('.jpg');
      const label = fmtTime(t).replace(/:/g, '\\:');
      await run('ffmpeg', [
        '-y', '-ss', String(t), '-i', src, '-frames:v', '1',
        '-vf',
        `scale=${tileWidth}:${tileH}:force_original_aspect_ratio=decrease,` +
          `pad=${tileWidth}:${tileH}:(ow-iw)/2:(oh-ih)/2:color=black,` +
          `drawtext=fontfile='${config.font}':text='${label}':x=6:y=6:fontsize=20:fontcolor=white:box=1:boxcolor=black@0.6:boxborderw=4`,
        '-q:v', '4', f,
      ]).catch(() => null);
      outs.push({ t, f });
    }
    const existing = [];
    for (const o of outs) {
      try {
        await fsp.access(o.f);
        existing.push(o);
      } catch {}
    }
    if (!existing.length) throw new Error('Impossible d’extraire des images.');
    const sheet = tmpFile('.jpg');
    const args = ['-y'];
    for (const o of existing) args.push('-i', o.f);
    const cols = Math.min(columns, existing.length);
    const rws = Math.ceil(existing.length / cols);
    const layout = existing
      .map((_, i) => `${(i % cols) === 0 ? '0' : Array.from({ length: i % cols }, () => 'w0').join('+')}_${Math.floor(i / cols) === 0 ? '0' : Array.from({ length: Math.floor(i / cols) }, () => 'h0').join('+')}`)
      .join('|');
    if (existing.length === 1) {
      args.push('-frames:v', '1', sheet);
    } else {
      args.push('-filter_complex', `${existing.map((_, i) => `[${i}:v]`).join('')}xstack=inputs=${existing.length}:layout=${layout}:fill=black`, '-frames:v', '1', '-q:v', '4', sheet);
    }
    await run('ffmpeg', args);
    const data = (await fsp.readFile(sheet)).toString('base64');
    await fsp.rm(sheet, { force: true });
    return { data, times: existing.map((o) => Math.round(o.t * 100) / 100), cols, rows: rws };
  } finally {
    for (const o of outs) await fsp.rm(o.f, { force: true });
  }
}

export async function detectScenes(src, threshold = 0.3) {
  const { stderr } = await run('ffmpeg', [
    '-hide_banner', '-i', src, '-an',
    '-vf', `scale=320:-2,select='gt(scene,${threshold})',showinfo`, '-f', 'null', '-',
  ]);
  const times = [];
  for (const m of stderr.matchAll(/pts_time:([0-9.]+)/g)) times.push(Math.round(Number(m[1]) * 100) / 100);
  return times;
}

export async function analyzeAudio(src, { noiseDb = -35, minSilence = 0.5 } = {}) {
  const { stderr } = await run('ffmpeg', [
    '-hide_banner', '-i', src, '-vn',
    '-af', `silencedetect=noise=${noiseDb}dB:d=${minSilence},ebur128=peak=true`, '-f', 'null', '-',
  ]);
  const silences = [];
  let cur = null;
  for (const line of stderr.split('\n')) {
    let m = line.match(/silence_start: ([0-9.\-e]+)/);
    if (m) cur = { start: Math.max(0, Number(m[1])) };
    m = line.match(/silence_end: ([0-9.]+) \| silence_duration: ([0-9.]+)/);
    if (m && cur) {
      cur.end = Number(m[1]);
      cur.duration = Number(m[2]);
      silences.push(cur);
      cur = null;
    }
  }
  const loud = stderr.match(/Integrated loudness:\s+I:\s+([\-0-9.]+) LUFS/);
  const peak = stderr.match(/True peak:\s+Peak:\s+([\-0-9.]+) dBFS/);
  return {
    integratedLufs: loud ? Number(loud[1]) : null,
    truePeakDb: peak ? Number(peak[1]) : null,
    silences: silences.map((s) => ({
      start: round(s.start), end: round(s.end), duration: round(s.duration),
    })),
  };
}

export function round(x) {
  return Math.round(x * 100) / 100;
}

export function fmtTime(t) {
  const m = Math.floor(t / 60);
  const s = t - m * 60;
  return `${String(m).padStart(2, '0')}:${s.toFixed(1).padStart(4, '0')}`;
}
