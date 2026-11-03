// Relais MCP Video Studio (Supabase Edge Function).
// Claude parle MCP à ce relais ; le relais transmet chaque appel d'outil au téléphone (long-polling)
// et renvoie sa réponse. Les vidéos ne transitent jamais ici : elles restent sur le téléphone.
//
//   POST /video-studio/mcp/<jeton>                 ← Claude (MCP Streamable HTTP, réponses JSON)
//   GET  /video-studio/device/<jeton>/next         ← téléphone : attend la prochaine commande
//   POST /video-studio/device/<jeton>/result/<id>  ← téléphone : renvoie le résultat
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

const db = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!, {
  auth: { persistSession: false },
});

const CALL_WAIT_MS = 110_000; // limite d'une Edge Function gratuite : 150 s
const POLL_WAIT_MS = 25_000;
const DEVICE_TIMEOUT_MS = 75_000;
const sleep = (ms: number) => new Promise((r) => setTimeout(r, ms));

async function hashToken(t: string) {
  const d = await crypto.subtle.digest("SHA-256", new TextEncoder().encode("vs:" + t));
  return [...new Uint8Array(d)].map((b) => b.toString(16).padStart(2, "0")).join("");
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json", "Access-Control-Allow-Origin": "*" },
  });

// ---------------------------------------------------------------- outils
const INSTRUCTIONS = `Video Studio : les vidéos, photos et musiques de l'utilisateur sont stockées sur son téléphone Android, qui fait aussi les montages. Ce relais transmet tes appels au téléphone.
Méthode : list_media (lis les "notes" de l'utilisateur) → view_storyboard pour REGARDER chaque vidéo → view_frame / detect_scenes / analyze_audio pour choisir les points de coupe → create_montage (quality "draft" d'abord) → get_job jusqu'à "done" → view_storyboard du résultat pour vérifier → version "final".
Le montage final est enregistré dans la galerie du téléphone (dossier Movies/VideoStudio) et dans l'onglet Montages de l'app.
Si le téléphone n'est pas connecté, demande à l'utilisateur d'ouvrir l'app Video Studio.`;

const str = (description?: string) => ({ type: "string", ...(description ? { description } : {}) });
const num = (description?: string, extra: Record<string, unknown> = {}) => ({ type: "number", ...(description ? { description } : {}), ...extra });
const bool = (description?: string) => ({ type: "boolean", ...(description ? { description } : {}) });
const en = (values: string[], description?: string) => ({ type: "string", enum: values, ...(description ? { description } : {}) });
const obj = (properties: Record<string, unknown>, required: string[] = []) => ({ type: "object", properties, required, additionalProperties: false });

const TOOLS = [
  {
    name: "list_media",
    description: "Liste les vidéos, photos, musiques et montages enregistrés dans l'app sur le téléphone.",
    inputSchema: obj({
      type: en(["video", "image", "audio"]),
      kind: en(["upload", "montage"], "upload = ajouté par l'utilisateur, montage = créé par toi"),
      search: str("Recherche dans le nom, les notes et les tags"),
    }),
  },
  {
    name: "get_media_info",
    description: "Détails d'un média (et la recette JSON d'un montage créé par create_montage).",
    inputSchema: obj({ media_id: str() }, ["media_id"]),
  },
  {
    name: "view_frame",
    description: "Renvoie l'image d'une vidéo à un instant précis (ou une photo) pour que tu puisses la voir.",
    inputSchema: obj({
      media_id: str(),
      time: num("Instant en secondes (défaut 0)", { minimum: 0 }),
      width: num("Largeur en pixels (défaut 768)", { minimum: 160, maximum: 1280 }),
    }, ["media_id"]),
  },
  {
    name: "view_storyboard",
    description: "Planche contact : grille d'images horodatées réparties sur la vidéo ou un intervalle. Le meilleur moyen de « regarder » une vidéo.",
    inputSchema: obj({
      media_id: str(),
      start: num("Début (s)", { minimum: 0 }),
      end: num("Fin (s)", { minimum: 0 }),
      columns: num("défaut 4", { minimum: 1, maximum: 6 }),
      rows: num("défaut 3", { minimum: 1, maximum: 6 }),
    }, ["media_id"]),
  },
  {
    name: "detect_scenes",
    description: "Détecte les changements de plan (instants en secondes), par comparaison d'images échantillonnées.",
    inputSchema: obj({
      media_id: str(),
      threshold: num("Sensibilité 0.1–0.9 (défaut 0.35, plus bas = plus de coupes)"),
      interval: num("Pas d'échantillonnage en s (défaut 0.5)"),
    }, ["media_id"]),
  },
  {
    name: "analyze_audio",
    description: "Analyse le son : passages silencieux (pour couper les blancs) et niveau moyen.",
    inputSchema: obj({
      media_id: str(),
      noise_db: num("Seuil de silence en dBFS (défaut -35)"),
      min_silence: num("Durée minimale d'un silence en s (défaut 0.5)"),
    }, ["media_id"]),
  },
  {
    name: "create_montage",
    description:
      "Lance un montage sur le téléphone (coupes, vitesse, volume, fondus, textes, musique, format 16:9 / 9:16 / 1:1 / 4:5). Renvoie un job_id : suis-le avec get_job. Le résultat va dans la galerie et l'app.",
    inputSchema: obj({
      name: str("Nom du montage"),
      clips: {
        type: "array",
        minItems: 1,
        description: "Clips dans l'ordre de la timeline",
        items: obj({
          media_id: str("ID de la vidéo ou de la photo"),
          start: num("Début dans la source (s, vidéo)", { minimum: 0 }),
          end: num("Fin dans la source (s, vidéo). Défaut : fin du fichier", { minimum: 0 }),
          duration: num("Durée d'affichage d'une photo (défaut 3 s)", { minimum: 0.2 }),
          speed: num("Vitesse 0.25–4 (0.5 = ralenti, 2 = accéléré)", { minimum: 0.25, maximum: 4 }),
          volume: num("Volume du son d'origine (1 = normal)", { minimum: 0, maximum: 4 }),
          mute: bool("Couper le son de ce clip"),
          text: str("Texte incrusté pendant tout ce clip (\\n = retour à la ligne)"),
          text_position: en(["top", "center", "bottom"]),
          text_size: en(["small", "medium", "large", "huge"]),
        }, ["media_id"]),
      },
      format: obj({
        aspect: en(["16:9", "9:16", "1:1", "4:5", "4:3", "source"], "9:16 pour TikTok/Reels/Shorts"),
        height: num("Petit côté en pixels (défaut 1080)", { minimum: 240, maximum: 2160 }),
        fit: en(["cover", "contain"], "cover = recadre pour remplir, contain = image entière avec bandes noires"),
      }),
      transition: obj({
        type: en(["none", "fade"], "fade = fondu au noir entre les clips"),
        duration: num("Durée du fondu en s (défaut 0.4)", { minimum: 0.1, maximum: 2 }),
      }),
      music: obj({
        media_id: str("ID d'une musique (ou d'une vidéo dont on veut le son)"),
        volume: num("défaut 0.5", { minimum: 0, maximum: 4 }),
        start: num("Démarrer la musique à cet instant (s)", { minimum: 0 }),
        fade_out: num("Fondu de fin de la musique (défaut 2 s)", { minimum: 0 }),
      }, ["media_id"]),
      texts: {
        type: "array",
        description: "Titres / sous-titres placés sur la timeline finale",
        items: obj({
          text: str(),
          start: num("Début (s, timeline finale)", { minimum: 0 }),
          end: num("Fin (s, timeline finale)", { minimum: 0 }),
          position: en(["top", "center", "bottom"]),
          size: en(["small", "medium", "large", "huge"]),
          color: str("Couleur CSS : white, yellow, #FF3366…"),
          box: bool("Fond semi-transparent derrière le texte (défaut true)"),
        }, ["text", "start", "end"]),
      },
      fade_in: num("Fondu d'ouverture (s)", { minimum: 0, maximum: 5 }),
      fade_out: num("Fondu de fin (s)", { minimum: 0, maximum: 5 }),
      quality: en(["draft", "final"], "draft = 480p rapide pour vérifier, final = qualité normale"),
      notes: str("Description du montage (visible dans l'app)"),
    }, ["name", "clips"]),
  },
  {
    name: "get_job",
    description: "État d'un montage en cours (attend jusqu'à wait_seconds s'il n'est pas fini).",
    inputSchema: obj({ job_id: str(), wait_seconds: num("défaut 40, max 90", { minimum: 0, maximum: 90 }) }, ["job_id"]),
  },
  {
    name: "list_jobs",
    description: "Liste les montages récents et leur état.",
    inputSchema: obj({}),
  },
  {
    name: "update_media",
    description: "Renomme un média ou modifie ses notes / tags.",
    inputSchema: obj({ media_id: str(), name: str(), notes: str(), tags: { type: "array", items: { type: "string" } } }, ["media_id"]),
  },
  {
    name: "delete_media",
    description: "Retire un média de l'app (pour un montage, supprime aussi le fichier). Les originaux de la galerie ne sont jamais supprimés. Uniquement si l'utilisateur le demande.",
    inputSchema: obj({ media_id: str() }, ["media_id"]),
  },
  {
    name: "import_from_url",
    description: "Télécharge un fichier vidéo / audio / image depuis une URL directe vers le téléphone et l'ajoute à l'app.",
    inputSchema: obj({ url: str(), name: str() }, ["url"]),
  },
  {
    name: "device_status",
    description: "Vérifie si le téléphone est connecté et donne l'espace libre, la batterie et le nombre de médias.",
    inputSchema: obj({}),
  },
  {
    name: "get_command_result",
    description: "Récupère le résultat d'une commande qui a pris trop de temps (command_id donné par une réponse précédente).",
    inputSchema: obj({ command_id: str(), wait_seconds: num("défaut 60, max 100", { minimum: 0, maximum: 100 }) }, ["command_id"]),
  },
];

const textResult = (text: string, isError = false) => ({ content: [{ type: "text", text }], ...(isError ? { isError: true } : {}) });

async function waitResult(id: string, ms: number) {
  const t0 = Date.now();
  while (Date.now() - t0 < ms) {
    const { data } = await db.from("vs_commands").select("status,result").eq("id", id).maybeSingle();
    if (!data) return textResult("Commande introuvable.", true);
    if (data.status === "done" || data.status === "error") {
      await db.from("vs_commands").delete().eq("id", id);
      return data.result ?? textResult("Réponse vide du téléphone.", true);
    }
    await sleep(Date.now() - t0 < 5000 ? 250 : 600);
  }
  return textResult(
    `Le téléphone travaille encore (command_id: ${id}). Appelle get_command_result avec ce command_id pour récupérer la réponse.`,
  );
}

async function callTool(tokenHash: string, name: string, args: Record<string, unknown>) {
  if (!TOOLS.some((t) => t.name === name)) return textResult(`Outil inconnu : ${name}`, true);

  if (name === "get_command_result") {
    const wait = Math.min(Number(args.wait_seconds ?? 60), 100) * 1000;
    const { data } = await db.from("vs_commands").select("token_hash").eq("id", String(args.command_id)).maybeSingle();
    if (!data || data.token_hash !== tokenHash) return textResult("Commande introuvable (déjà récupérée ou expirée).", true);
    return waitResult(String(args.command_id), wait);
  }

  const { data: dev } = await db.from("vs_devices").select("last_seen,info").eq("token_hash", tokenHash).maybeSingle();
  const online = dev && Date.now() - new Date(dev.last_seen).getTime() < DEVICE_TIMEOUT_MS;
  if (!online) {
    return textResult(
      "Le téléphone n'est pas connecté. Demande à l'utilisateur d'ouvrir l'app Video Studio sur son téléphone (avec Internet) et de vérifier que « Connecté à Claude » est activé, puis réessaie." +
        (dev ? ` Dernière connexion : ${new Date(dev.last_seen).toISOString()}.` : ""),
      true,
    );
  }

  // get_job peut attendre côté téléphone : on borne pour rester sous la limite du relais
  if (name === "get_job") args = { ...args, wait_seconds: Math.min(Number(args.wait_seconds ?? 40), 90) };

  const { data: cmd, error } = await db.from("vs_commands").insert({ token_hash: tokenHash, tool: name, args }).select("id").single();
  if (error) return textResult("Erreur du relais : " + error.message, true);

  // Ménage occasionnel
  if (Math.random() < 0.05) {
    await db.from("vs_commands").delete().lt("created_at", new Date(Date.now() - 86_400_000).toISOString());
  }
  return waitResult(cmd.id, CALL_WAIT_MS);
}

async function handleRpc(tokenHash: string, msg: any) {
  const { id, method, params } = msg ?? {};
  const reply = (result: unknown) => ({ jsonrpc: "2.0", id, result });
  switch (method) {
    case "initialize":
      return reply({
        protocolVersion: params?.protocolVersion || "2025-06-18",
        capabilities: { tools: { listChanged: false } },
        serverInfo: { name: "video-studio", title: "Video Studio", version: "2.0.0" },
        instructions: INSTRUCTIONS,
      });
    case "ping":
      return reply({});
    case "tools/list":
      return reply({ tools: TOOLS });
    case "tools/call":
      try {
        return reply(await callTool(tokenHash, params?.name, params?.arguments ?? {}));
      } catch (e) {
        return reply(textResult("Erreur du relais : " + (e as Error).message, true));
      }
    case "resources/list":
      return reply({ resources: [] });
    case "prompts/list":
      return reply({ prompts: [] });
    default:
      if (id === undefined || id === null) return null; // notification
      return { jsonrpc: "2.0", id, error: { code: -32601, message: `Méthode inconnue : ${method}` } };
  }
}

// ---------------------------------------------------------------- routes
Deno.serve(async (req) => {
  const url = new URL(req.url);
  const parts = url.pathname.split("/").filter(Boolean);
  const i = parts.indexOf("video-studio");
  const [section, token, action, extra] = parts.slice(i + 1);

  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
        "Access-Control-Allow-Headers": "content-type,authorization,mcp-protocol-version,mcp-session-id",
      },
    });
  }
  if (!section) return json({ ok: true, service: "video-studio-relay" });
  if (!token || token.length < 24) return json({ error: "Jeton invalide" }, 404);
  const tokenHash = await hashToken(token);

  // ----- Claude (MCP) -----
  if (section === "mcp") {
    if (req.method !== "POST") {
      return json({ jsonrpc: "2.0", error: { code: -32000, message: "Méthode non autorisée" }, id: null }, 405);
    }
    let body: any;
    try {
      body = await req.json();
    } catch {
      return json({ jsonrpc: "2.0", error: { code: -32700, message: "JSON invalide" }, id: null }, 400);
    }
    if (Array.isArray(body)) {
      const out = (await Promise.all(body.map((m) => handleRpc(tokenHash, m)))).filter(Boolean);
      return out.length ? json(out) : new Response(null, { status: 202 });
    }
    const out = await handleRpc(tokenHash, body);
    return out ? json(out) : new Response(null, { status: 202 });
  }

  // ----- Téléphone -----
  if (section === "device") {
    if (action === "next" && req.method === "GET") {
      const info = url.searchParams.get("info");
      const seen = async () =>
        db.from("vs_devices").upsert({
          token_hash: tokenHash,
          last_seen: new Date().toISOString(),
          ...(info ? { info: JSON.parse(info) } : {}),
        });
      await seen();
      const t0 = Date.now();
      let n = 0;
      while (Date.now() - t0 < POLL_WAIT_MS) {
        const { data, error } = await db.rpc("vs_claim", { p_token_hash: tokenHash });
        if (error) return json({ error: error.message }, 500);
        if (data?.length) {
          const c = data[0];
          return json({ command: { id: c.id, tool: c.tool, args: c.args } });
        }
        if (++n % 15 === 0) await seen();
        await sleep(500);
      }
      return json({ command: null });
    }
    if (action === "result" && extra && req.method === "POST") {
      const body = await req.json().catch(() => null);
      if (!body) return json({ error: "JSON invalide" }, 400);
      const { error } = await db
        .from("vs_commands")
        .update({ status: body.isError ? "error" : "done", result: body, updated_at: new Date().toISOString() })
        .eq("id", extra)
        .eq("token_hash", tokenHash);
      if (error) return json({ error: error.message }, 500);
      await db.from("vs_devices").upsert({ token_hash: tokenHash, last_seen: new Date().toISOString() });
      return json({ ok: true });
    }
  }
  return json({ error: "Introuvable" }, 404);
});
