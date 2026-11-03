# 🎬 Video Studio — tes vidéos + Claude monteur

Une app Android où tu envoies tes vidéos, photos et musiques, et un **serveur MCP** que tu connectes à Claude. Claude peut alors **regarder** tes vidéos (images, planches contact, scènes, silences) et **faire des montages** (coupes, transitions, textes, musique, format TikTok 9:16…). Les montages apparaissent directement dans l'app.

```
 Téléphone (APK)  ──upload──▶  Serveur Video Studio  ◀──MCP──  Claude
                  ◀─montages──  (Node.js + ffmpeg)
```

## 1. Lancer le serveur

Le serveur doit tourner sur une machine allumée (PC, mini-PC, VPS…) **et être joignable en HTTPS depuis Internet** pour que Claude puisse s'y connecter.

### Option A — Docker (le plus simple, avec HTTPS gratuit)

```bash
cd video-studio
ACCESS_TOKEN="choisis-un-long-mot-de-passe" docker compose up -d --build
docker compose logs tunnel | grep trycloudflare.com
```

La dernière commande affiche ton adresse publique, par exemple `https://abc-def.trycloudflare.com`.
⚠️ Avec ce tunnel « rapide », l'adresse change à chaque redémarrage. Pour une adresse fixe : un [tunnel Cloudflare nommé](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) (gratuit, nécessite un nom de domaine) ou un hébergeur (Railway, Render, Fly.io, VPS) avec un disque persistant monté sur `/data`.

### Option B — Sans Docker

Il faut Node.js 20+ et ffmpeg installés.

```bash
cd video-studio/server
npm install
ACCESS_TOKEN="choisis-un-long-mot-de-passe" npm start
# dans un autre terminal, pour l'HTTPS public :
cloudflared tunnel --url http://localhost:8787
```

### Variables d'environnement

| Variable | Rôle | Défaut |
|---|---|---|
| `ACCESS_TOKEN` | Jeton secret (app + Claude) | généré dans `data/token.txt` |
| `PORT` | Port HTTP | `8787` |
| `DATA_DIR` | Où sont stockés les fichiers | `./data` |
| `PUBLIC_URL` | Adresse publique (liens de téléchargement) | déduite de la requête |
| `MAX_UPLOAD_MB` | Taille max d'un fichier | `4096` |

## 2. Installer l'app Android

1. Télécharge **`video-studio/VideoStudio.apk`** sur ton téléphone.
2. Ouvre-le, autorise « Installer des applis inconnues » si Android le demande.
3. Au premier lancement : entre l'adresse du serveur (`https://…`) et ton jeton.

Dans l'app :
- **＋** pour ajouter des vidéos / photos / musiques (plusieurs à la fois).
- Depuis la **galerie** : *Partager → Video Studio* envoie directement les fichiers.
- Touche un fichier pour le lire, le renommer, écrire des **notes pour Claude** (« garder le moment du gâteau vers 1:20 »), le télécharger ou le supprimer.
- Onglet **Montages** : les vidéos créées par Claude (avec la progression du rendu en cours).
- Onglet **Claude** : l'adresse MCP à copier.

L'interface marche aussi dans un navigateur à l'adresse du serveur.

## 3. Connecter Claude

1. Dans l'app, onglet **Claude** → **Copier** (adresse du type `https://…/mcp/<jeton>`).
2. Sur claude.ai : **Paramètres → Connecteurs → Ajouter un connecteur personnalisé**, colle l'adresse.
3. Dans une conversation, active le connecteur *Video Studio* et demande :
   > « Regarde mes vidéos de vacances et fais un best-of de 30 s en vertical avec la musique *summer* et des fondus. »

Pour **Claude Code** :
```bash
claude mcp add --transport http video-studio https://…/mcp/<jeton>
```

## Outils MCP disponibles pour Claude

| Outil | Description |
|---|---|
| `list_media` | Liste des fichiers (filtre par type, recherche, notes) |
| `get_media_info` | Détails d'un fichier (durée, résolution, son, recette d'un montage) |
| `view_frame` | Voir l'image à un instant précis |
| `view_storyboard` | Planche contact horodatée : « regarder » une vidéo |
| `detect_scenes` | Changements de plan |
| `analyze_audio` | Silences (pour couper les blancs) et volume |
| `create_montage` | Le montage : clips coupés, vitesse, volume, transitions (fondu, glissé, zoom…), textes, musique avec atténuation auto sous la voix, fondus, formats 16:9 / 9:16 / 1:1 / 4:5, recadrage ou fond flouté, brouillon 480p ou final 1080p |
| `get_job` / `list_jobs` | Suivi des rendus |
| `update_media` / `delete_media` | Renommer, annoter, supprimer |
| `import_from_url` | Importer un fichier depuis un lien direct |
| `get_download_link` | Lien de téléchargement signé |

## Sécurité

- Le jeton protège l'app **et** l'adresse MCP : ne partage pas l'adresse `…/mcp/<jeton>`.
- Les liens de téléchargement donnés par Claude sont signés par fichier (ils ne révèlent pas le jeton).
- Pour changer le jeton : modifie `ACCESS_TOKEN`, redémarre, puis mets à jour l'app et le connecteur Claude.

## Recompiler l'APK

```bash
cd video-studio/android
./gradlew assembleRelease     # nécessite le SDK Android (ANDROID_HOME)
# → app/build/outputs/apk/release/app-release.apk
```
Le workflow GitHub `.github/workflows/video-studio-apk.yml` le compile aussi automatiquement (onglet *Actions* → artefact *VideoStudio-apk*). L'APK est signé avec une clé de debug : si tu installes une version compilée ailleurs, désinstalle d'abord l'ancienne.
