// Ajout d'un fichier à la bibliothèque (upload depuis l'app ou import par URL)
import fsp from 'node:fs/promises';
import fs from 'node:fs';
import path from 'node:path';
import { Readable } from 'node:stream';
import { pipeline } from 'node:stream/promises';
import * as lib from './library.js';
import { probe, makeThumb } from './media.js';

export async function ingestFile(tmpPath, originalName, mime, { notes = '', tags = [] } = {}) {
  const type = lib.typeFromMime(mime, originalName);
  if (!type) {
    await fsp.rm(tmpPath, { force: true });
    throw new Error(`Type de fichier non pris en charge : ${originalName} (${mime})`);
  }
  const id = lib.newId();
  const ext = (path.extname(originalName) || { video: '.mp4', audio: '.mp3', image: '.jpg' }[type]).toLowerCase();
  const dest = lib.storagePathFor(id, ext);
  await fsp.rename(tmpPath, dest).catch(async () => {
    await fsp.copyFile(tmpPath, dest);
    await fsp.rm(tmpPath, { force: true });
  });
  let info;
  try {
    info = await probe(dest);
  } catch (e) {
    await fsp.rm(dest, { force: true });
    throw new Error(`Fichier illisible (${originalName}) : ${e.message}`);
  }
  const item = {
    id,
    file: path.basename(dest),
    name: path.basename(originalName, path.extname(originalName)),
    originalName,
    type,
    kind: 'upload',
    mime,
    notes,
    tags,
    ...info,
    createdAt: new Date().toISOString(),
  };
  if (type === 'image') item.duration = null;
  item.hasThumb = await makeThumb(item, dest, lib.thumbPath(item)).catch(() => false);
  await lib.add(item);
  return item;
}

export async function importFromUrl(url, name) {
  const res = await fetch(url, { redirect: 'follow' });
  if (!res.ok || !res.body) throw new Error(`Téléchargement impossible (${res.status})`);
  const mime = (res.headers.get('content-type') || '').split(';')[0];
  let fname = name || decodeURIComponent(new URL(url).pathname.split('/').pop() || 'import');
  if (!path.extname(fname)) {
    const ext = { 'video/mp4': '.mp4', 'video/webm': '.webm', 'video/quicktime': '.mov', 'audio/mpeg': '.mp3', 'audio/wav': '.wav', 'image/jpeg': '.jpg', 'image/png': '.png' }[mime];
    if (ext) fname += ext;
  }
  const tmp = path.join(lib.tmpDir(), 'dl_' + lib.newId());
  await pipeline(Readable.fromWeb(res.body), fs.createWriteStream(tmp));
  return ingestFile(tmp, fname, mime);
}
