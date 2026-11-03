// Bibliothèque de médias : fichiers sur disque + métadonnées dans library.json
import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';
import crypto from 'node:crypto';
import { config } from './config.js';

const MEDIA_DIR = path.join(config.dataDir, 'media');
const THUMB_DIR = path.join(config.dataDir, 'thumbs');
const DB_FILE = path.join(config.dataDir, 'library.json');

fs.mkdirSync(MEDIA_DIR, { recursive: true });
fs.mkdirSync(THUMB_DIR, { recursive: true });
fs.mkdirSync(path.join(config.dataDir, 'tmp'), { recursive: true });

let items = [];
try {
  items = JSON.parse(fs.readFileSync(DB_FILE, 'utf8')).items || [];
} catch {
  items = [];
}

let writing = Promise.resolve();
function persist() {
  const data = JSON.stringify({ items }, null, 2);
  writing = writing.then(async () => {
    const tmp = DB_FILE + '.tmp';
    await fsp.writeFile(tmp, data);
    await fsp.rename(tmp, DB_FILE);
  });
  return writing;
}

export function newId() {
  return crypto.randomBytes(5).toString('hex');
}

export function mediaPath(item) {
  return path.join(MEDIA_DIR, item.file);
}

export function thumbPath(item) {
  return path.join(THUMB_DIR, item.id + '.jpg');
}

export function tmpDir() {
  return path.join(config.dataDir, 'tmp');
}

export function storagePathFor(id, ext) {
  return path.join(MEDIA_DIR, id + ext);
}

export function list({ kind, type, search } = {}) {
  let out = [...items];
  if (kind) out = out.filter((i) => i.kind === kind);
  if (type) out = out.filter((i) => i.type === type);
  if (search) {
    const s = search.toLowerCase();
    out = out.filter((i) =>
      [i.name, i.notes, ...(i.tags || [])].join(' ').toLowerCase().includes(s)
    );
  }
  return out.sort((a, b) => b.createdAt.localeCompare(a.createdAt));
}

export function get(id) {
  return items.find((i) => i.id === id) || null;
}

export function mustGet(id) {
  const it = get(id);
  if (!it) throw new Error(`Média introuvable : ${id}`);
  return it;
}

export async function add(item) {
  items.push(item);
  await persist();
  return item;
}

export async function update(id, patch) {
  const it = mustGet(id);
  for (const k of ['name', 'notes', 'tags']) {
    if (patch[k] !== undefined) it[k] = patch[k];
  }
  it.updatedAt = new Date().toISOString();
  await persist();
  return it;
}

export async function setFields(id, fields) {
  const it = mustGet(id);
  Object.assign(it, fields);
  await persist();
  return it;
}

export async function remove(id) {
  const it = mustGet(id);
  items = items.filter((i) => i.id !== id);
  await persist();
  await fsp.rm(mediaPath(it), { force: true });
  await fsp.rm(thumbPath(it), { force: true });
  return it;
}

export function typeFromMime(mime = '', filename = '') {
  const ext = path.extname(filename).toLowerCase();
  if (mime.startsWith('video/') || ['.mp4', '.mov', '.mkv', '.webm', '.avi', '.m4v', '.3gp'].includes(ext)) return 'video';
  if (mime.startsWith('audio/') || ['.mp3', '.wav', '.m4a', '.aac', '.ogg', '.flac', '.opus'].includes(ext)) return 'audio';
  if (mime.startsWith('image/') || ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.heic'].includes(ext)) return 'image';
  return null;
}
