// Serveur MCP : donne à Claude l'accès à la bibliothèque et au moteur de montage
import crypto from 'node:crypto';
import { McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import { config } from './config.js';
import * as lib from './library.js';
import * as media from './media.js';
import * as montage from './montage.js';
import { importFromUrl } from './ingest.js';

export function signFile(id) {
  return crypto.createHmac('sha256', config.token).update('file:' + id).digest('base64url').slice(0, 22);
}

export function publicItem(it, base) {
  const out = {
    id: it.id,
    name: it.name,
    type: it.type,
    kind: it.kind,
    duration: it.duration,
    width: it.width,
    height: it.height,
    fps: it.fps,
    hasAudio: it.hasAudio,
    sizeMB: Math.round((it.sizeBytes / 1048576) * 10) / 10,
    notes: it.notes || undefined,
    tags: it.tags?.length ? it.tags : undefined,
    createdAt: it.createdAt,
  };
  if (base) out.downloadUrl = `${base}/f/${it.id}/${signFile(it.id)}/${encodeURIComponent(it.name)}.${it.file.split('.').pop()}`;
  return out;
}

const INSTRUCTIONS = `Video Studio : bibliothèque de vidéos, photos et musiques envoyées par l'utilisateur depuis son téléphone, avec un moteur de montage (ffmpeg).
Méthode recommandée pour un montage :
1. list_media pour voir les fichiers (lis les "notes" : l'utilisateur y décrit souvent ce qu'il veut).
2. view_storyboard pour REGARDER le contenu de chaque vidéo (planche d'images horodatées), view_frame pour vérifier un instant précis, detect_scenes / analyze_audio pour trouver de bons points de coupe.
3. create_montage avec quality "draft" pour un brouillon rapide, vérifie le résultat avec view_storyboard, puis relance en "final".
4. Donne à l'utilisateur le lien de téléchargement (downloadUrl). Le montage apparaît aussi dans l'app.`;

const clipSchema = z.object({
  media_id: z.string().describe('ID de la vidéo ou de la photo'),
  start: z.number().min(0).optional().describe('Début dans la source, en secondes (vidéo)'),
  end: z.number().min(0).optional().describe('Fin dans la source, en secondes (vidéo). Par défaut : fin du fichier'),
  duration: z.number().positive().optional().describe('Durée d’affichage pour une photo (défaut 3 s)'),
  speed: z.number().min(0.25).max(4).optional().describe('Vitesse (0.5 = ralenti, 2 = accéléré)'),
  volume: z.number().min(0).max(4).optional().describe('Volume du son d’origine (1 = normal)'),
  mute: z.boolean().optional().describe('Couper le son de ce clip'),
  text: z.string().optional().describe('Texte incrusté pendant ce clip (\\n pour un retour à la ligne)'),
  text_position: z.enum(['top', 'center', 'bottom']).optional(),
  text_size: z.enum(['small', 'medium', 'large', 'huge']).optional(),
});

const textSchema = z.object({
  text: z.string(),
  start: z.number().min(0).describe('Début en secondes sur la timeline du montage final'),
  end: z.number().min(0).describe('Fin en secondes sur la timeline du montage final'),
  position: z.enum(['top', 'center', 'bottom']).optional(),
  size: z.enum(['small', 'medium', 'large', 'huge']).optional(),
  color: z.string().optional().describe('Couleur ffmpeg, ex. white, yellow, #FF3366'),
  box: z.boolean().optional().describe('Fond semi-transparent derrière le texte (défaut true)'),
});

const montageShape = {
  name: z.string().describe('Nom du montage'),
  clips: z.array(clipSchema).min(1).describe('Clips dans l’ordre de la timeline'),
  format: z
    .object({
      aspect: z.enum(['16:9', '9:16', '1:1', '4:5', '4:3', 'source']).optional().describe('9:16 pour TikTok/Reels/Shorts'),
      height: z.number().int().min(240).max(2160).optional().describe('Petit côté en pixels (défaut 1080)'),
      fps: z.number().int().min(10).max(60).optional(),
      fit: z.enum(['cover', 'contain', 'blur']).optional().describe('cover = recadre, contain = bandes noires, blur = fond flouté'),
    })
    .optional(),
  transition: z
    .object({
      type: z.enum(['none', 'fade', 'dissolve', 'fadeblack', 'fadewhite', 'wipeleft', 'wiperight', 'wipeup', 'wipedown', 'slideleft', 'slideright', 'slideup', 'slidedown', 'circleopen', 'circleclose', 'radial', 'smoothleft', 'smoothright', 'zoomin', 'pixelize', 'hblur', 'distance']),
      duration: z.number().min(0.1).max(3).optional().describe('Durée en secondes (défaut 0.5)'),
    })
    .optional(),
  music: z
    .object({
      media_id: z.string().describe('ID d’un fichier audio (ou d’une vidéo dont on veut le son)'),
      volume: z.number().min(0).max(4).optional().describe('défaut 0.6'),
      start: z.number().min(0).optional().describe('Démarrer la musique à cet instant (s)'),
      fade_out: z.number().min(0).optional().describe('Fondu de fin de la musique (défaut 2 s)'),
      duck: z.boolean().optional().describe('Baisser la musique automatiquement quand quelqu’un parle'),
    })
    .optional(),
  texts: z.array(textSchema).optional().describe('Titres / sous-titres sur la timeline finale'),
  fade_in: z.number().min(0).max(5).optional().describe('Fondu d’ouverture (s)'),
  fade_out: z.number().min(0).max(5).optional().describe('Fondu de fin (s)'),
  quality: z.enum(['draft', 'final']).optional().describe('draft = 480p rapide pour vérifier, final = qualité normale'),
  notes: z.string().optional().describe('Description du montage (visible dans l’app)'),
};

const json = (o) => ({ content: [{ type: 'text', text: JSON.stringify(o, null, 2) }] });
const fail = (e) => ({ isError: true, content: [{ type: 'text', text: String(e.message || e) }] });

function jobView(job, base) {
  const out = { ...job };
  if (job.resultId) {
    const it = lib.get(job.resultId);
    if (it) out.result = publicItem(it, base);
  }
  return out;
}

export function createMcpServer(base) {
  const server = new McpServer({ name: 'video-studio', version: '1.0.0' }, { instructions: INSTRUCTIONS });

  const tool = (name, description, inputSchema, handler) =>
    server.registerTool(name, { description, inputSchema }, async (args) => {
      try {
        return await handler(args);
      } catch (e) {
        return fail(e);
      }
    });

  tool('list_media', 'Liste les vidéos, photos, musiques et montages de la bibliothèque.', {
    type: z.enum(['video', 'audio', 'image']).optional(),
    kind: z.enum(['upload', 'montage']).optional().describe('upload = envoyé par l’utilisateur, montage = créé par toi'),
    search: z.string().optional().describe('Recherche dans le nom, les notes et les tags'),
  }, async (a) => {
    const items = lib.list(a).map((i) => publicItem(i));
    return json({ count: items.length, items });
  });

  tool('get_media_info', 'Détails complets d’un média (et la description du montage s’il a été créé par create_montage).', {
    media_id: z.string(),
  }, async ({ media_id }) => {
    const it = lib.mustGet(media_id);
    return json({ ...publicItem(it, base), originalName: it.originalName, videoCodec: it.videoCodec, audioCodec: it.audioCodec, creationTime: it.creationTime, montageSpec: it.spec });
  });

  tool('view_frame', 'Renvoie l’image d’une vidéo à un instant précis (ou une photo) pour que tu puisses la voir.', {
    media_id: z.string(),
    time: z.number().min(0).optional().describe('Instant en secondes (défaut 0)'),
    width: z.number().int().min(160).max(1280).optional(),
  }, async ({ media_id, time = 0, width = 768 }) => {
    const it = lib.mustGet(media_id);
    if (it.type === 'audio') throw new Error('Fichier audio : pas d’image.');
    const t = it.duration ? Math.min(time, Math.max(0, it.duration - 0.05)) : 0;
    const data = await media.frameAt(lib.mediaPath(it), t, width);
    return { content: [{ type: 'text', text: `${it.name} @ ${media.fmtTime(t)}` }, { type: 'image', data, mimeType: 'image/jpeg' }] };
  });

  tool('view_storyboard', 'Planche contact : une grille d’images horodatées réparties sur la vidéo (ou un intervalle). Le meilleur moyen de "regarder" une vidéo.', {
    media_id: z.string(),
    start: z.number().min(0).optional(),
    end: z.number().min(0).optional(),
    columns: z.number().int().min(1).max(6).optional().describe('défaut 4'),
    rows: z.number().int().min(1).max(6).optional().describe('défaut 3'),
  }, async ({ media_id, start = 0, end, columns = 4, rows = 3 }) => {
    const it = lib.mustGet(media_id);
    if (it.type !== 'video') throw new Error('view_storyboard ne fonctionne que sur les vidéos.');
    const e = Math.min(end ?? it.duration, it.duration);
    const sb = await media.storyboard(lib.mediaPath(it), { start, end: e, columns, rows, aspect: (it.width || 16) / (it.height || 9) });
    return {
      content: [
        { type: 'text', text: `${it.name} (${it.duration}s) — images aux instants (s), de gauche à droite puis de haut en bas : ${sb.times.join(', ')}` },
        { type: 'image', data: sb.data, mimeType: 'image/jpeg' },
      ],
    };
  });

  tool('detect_scenes', 'Détecte les changements de plan dans une vidéo (instants en secondes).', {
    media_id: z.string(),
    threshold: z.number().min(0.05).max(0.9).optional().describe('Sensibilité (défaut 0.3, plus bas = plus de coupes)'),
  }, async ({ media_id, threshold = 0.3 }) => {
    const it = lib.mustGet(media_id);
    const cuts = await media.detectScenes(lib.mediaPath(it), threshold);
    return json({ media_id, duration: it.duration, sceneChanges: cuts });
  });

  tool('analyze_audio', 'Analyse le son : passages silencieux (utile pour couper les blancs) et volume global.', {
    media_id: z.string(),
    noise_db: z.number().optional().describe('Seuil de silence en dB (défaut -35)'),
    min_silence: z.number().optional().describe('Durée minimale d’un silence en s (défaut 0.5)'),
  }, async ({ media_id, noise_db, min_silence }) => {
    const it = lib.mustGet(media_id);
    if (!it.hasAudio && it.type !== 'audio') throw new Error('Ce média n’a pas de son.');
    return json({ media_id, duration: it.duration, ...(await media.analyzeAudio(lib.mediaPath(it), { noiseDb: noise_db, minSilence: min_silence })) });
  });

  tool('create_montage',
    'Crée un montage vidéo (coupes, enchaînement, transitions, textes, musique, format vertical…). Le rendu est enregistré dans la bibliothèque. Attend jusqu’à wait_seconds puis renvoie l’état du rendu ; si pas fini, utilise get_job.',
    { ...montageShape, wait_seconds: z.number().min(0).max(110).optional().describe('défaut 50') },
    async ({ wait_seconds = 50, ...spec }) => {
      const job = montage.startMontage(spec);
      await montage.waitForJob(job, wait_seconds * 1000);
      return json(jobView(job, base));
    });

  tool('get_job', 'État d’un rendu de montage (attend jusqu’à wait_seconds s’il est en cours).', {
    job_id: z.string(),
    wait_seconds: z.number().min(0).max(110).optional().describe('défaut 30'),
  }, async ({ job_id, wait_seconds = 30 }) => {
    const job = montage.getJob(job_id);
    if (!job) throw new Error('Rendu introuvable (le serveur a peut-être redémarré).');
    await montage.waitForJob(job, wait_seconds * 1000);
    return json(jobView(job, base));
  });

  tool('list_jobs', 'Liste les rendus récents.', {}, async () => json(montage.listJobs().map((j) => jobView(j, base))));

  tool('update_media', 'Renomme un média ou modifie ses notes / tags.', {
    media_id: z.string(),
    name: z.string().optional(),
    notes: z.string().optional(),
    tags: z.array(z.string()).optional(),
  }, async ({ media_id, ...patch }) => json(publicItem(await lib.update(media_id, patch), base)));

  tool('delete_media', 'Supprime définitivement un média. Ne supprime les fichiers de l’utilisateur que s’il le demande explicitement.', {
    media_id: z.string(),
  }, async ({ media_id }) => {
    const it = await lib.remove(media_id);
    return json({ deleted: it.id, name: it.name });
  });

  tool('import_from_url', 'Télécharge un fichier vidéo / audio / image depuis une URL directe et l’ajoute à la bibliothèque.', {
    url: z.string().url(),
    name: z.string().optional(),
  }, async ({ url, name }) => json(publicItem(await importFromUrl(url, name), base)));

  tool('get_download_link', 'Lien de téléchargement direct d’un média (à donner à l’utilisateur).', {
    media_id: z.string(),
  }, async ({ media_id }) => {
    const it = lib.mustGet(media_id);
    return json({ name: it.name, downloadUrl: publicItem(it, base).downloadUrl });
  });

  return server;
}
