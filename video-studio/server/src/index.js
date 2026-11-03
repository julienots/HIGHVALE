import express from 'express';
import multer from 'multer';
import path from 'node:path';
import fs from 'node:fs';
import crypto from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { StreamableHTTPServerTransport } from '@modelcontextprotocol/sdk/server/streamableHttp.js';
import { config } from './config.js';
import * as lib from './library.js';
import * as montage from './montage.js';
import { ingestFile } from './ingest.js';
import { createMcpServer, publicItem, signFile } from './mcp.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const app = express();
app.set('trust proxy', true);

const baseUrl = (req) => config.publicUrl || `${req.protocol}://${req.get('x-forwarded-host') || req.get('host')}`;
const safeEq = (a, b) => {
  const x = Buffer.from(String(a || '')), y = Buffer.from(String(b || ''));
  return x.length === y.length && crypto.timingSafeEqual(x, y);
};
function tokenFrom(req) {
  const h = req.get('authorization') || '';
  if (h.startsWith('Bearer ')) return h.slice(7);
  return req.query.token;
}
function auth(req, res, next) {
  if (safeEq(tokenFrom(req), config.token)) return next();
  res.status(401).json({ error: 'Jeton invalide' });
}

// ---------- API de l'app ----------
const upload = multer({
  dest: lib.tmpDir(),
  limits: { fileSize: config.maxUploadMb * 1024 * 1024 },
});

app.get('/api/info', auth, (req, res) => {
  const base = baseUrl(req);
  res.json({ mcpUrl: `${base}/mcp/${config.token}`, base, count: lib.list().length });
});

app.get('/api/media', auth, (req, res) => {
  const base = baseUrl(req);
  res.json(lib.list(req.query).map((i) => publicItem(i, base)));
});

app.post('/api/upload', auth, upload.array('files', 50), async (req, res) => {
  const added = [], errors = [];
  for (const f of req.files || []) {
    try {
      const name = Buffer.from(f.originalname, 'latin1').toString('utf8');
      added.push(publicItem(await ingestFile(f.path, name, f.mimetype, { notes: req.body?.notes || '' })));
    } catch (e) {
      errors.push(String(e.message || e));
    }
  }
  res.status(added.length || !errors.length ? 200 : 400).json({ added, errors });
});

// Upload brut (utilisé par la fonction "Partager" de l'app Android)
app.put('/api/upload-raw', auth, async (req, res) => {
  const name = String(req.query.name || 'video.mp4');
  const tmp = path.join(lib.tmpDir(), 'raw_' + lib.newId());
  const out = fs.createWriteStream(tmp);
  req.pipe(out);
  out.on('finish', async () => {
    try {
      res.json(publicItem(await ingestFile(tmp, name, req.get('content-type') || '')));
    } catch (e) {
      res.status(400).json({ error: String(e.message || e) });
    }
  });
  out.on('error', (e) => res.status(500).json({ error: String(e) }));
});

app.patch('/api/media/:id', auth, express.json(), async (req, res) => {
  try {
    res.json(publicItem(await lib.update(req.params.id, req.body || {}), baseUrl(req)));
  } catch (e) {
    res.status(404).json({ error: e.message });
  }
});

app.delete('/api/media/:id', auth, async (req, res) => {
  try {
    await lib.remove(req.params.id);
    res.json({ ok: true });
  } catch (e) {
    res.status(404).json({ error: e.message });
  }
});

app.get('/api/media/:id/file', auth, (req, res) => {
  const it = lib.get(req.params.id);
  if (!it) return res.sendStatus(404);
  res.sendFile(lib.mediaPath(it));
});

app.get('/api/media/:id/thumb', auth, (req, res) => {
  const it = lib.get(req.params.id);
  if (!it || !it.hasThumb) return res.sendStatus(404);
  res.set('Cache-Control', 'private, max-age=86400');
  res.sendFile(lib.thumbPath(it));
});

app.get('/api/jobs', auth, (req, res) => res.json(montage.listJobs()));

// Liens de téléchargement signés (sans le jeton principal)
app.get('/f/:id/:sig/:name?', (req, res) => {
  const it = lib.get(req.params.id);
  if (!it || !safeEq(req.params.sig, signFile(it.id))) return res.sendStatus(404);
  if (req.query.dl) res.attachment(`${it.name}.${it.file.split('.').pop()}`);
  res.sendFile(lib.mediaPath(it));
});

// ---------- MCP (Claude) ----------
async function handleMcp(req, res) {
  const server = createMcpServer(baseUrl(req));
  const transport = new StreamableHTTPServerTransport({ sessionIdGenerator: undefined, enableJsonResponse: true });
  res.on('close', () => {
    transport.close();
    server.close();
  });
  try {
    await server.connect(transport);
    await transport.handleRequest(req, res, req.body);
  } catch (e) {
    console.error('MCP', e);
    if (!res.headersSent) res.status(500).json({ jsonrpc: '2.0', error: { code: -32603, message: 'Erreur interne' }, id: null });
  }
}
const mcpJson = express.json({ limit: '4mb' });
const notAllowed = (req, res) => res.status(405).set('Allow', 'POST').json({ jsonrpc: '2.0', error: { code: -32000, message: 'Méthode non autorisée' }, id: null });

// URL secrète à coller dans Claude : https://…/mcp/<jeton>
app.post('/mcp/:token', (req, res, next) => (safeEq(req.params.token, config.token) ? next() : res.sendStatus(404)), mcpJson, handleMcp);
app.get('/mcp/:token', notAllowed);
app.delete('/mcp/:token', notAllowed);
// Variante avec en-tête Authorization: Bearer <jeton>
app.post('/mcp', auth, mcpJson, handleMcp);
app.get('/mcp', notAllowed);

// ---------- Interface web (aussi utilisée par l'app Android) ----------
app.use(express.static(path.join(__dirname, '..', 'public'), { index: 'index.html' }));
app.get('/health', (req, res) => res.json({ ok: true }));

app.listen(config.port, () => {
  console.log(`\n🎬 Video Studio sur http://localhost:${config.port}`);
  console.log(`   Jeton d'accès : ${config.token}`);
  console.log(`   Données : ${config.dataDir}`);
  console.log(`   URL MCP pour Claude : <URL publique>/mcp/${config.token}\n`);
});
