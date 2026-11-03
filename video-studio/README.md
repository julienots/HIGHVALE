# 🎬 Video Studio — tes vidéos sur ton téléphone, Claude au montage

Une app Android où tu ajoutes tes vidéos, photos et musiques. Tu connectes Claude via MCP, et Claude peut **regarder** tes vidéos et **faire des montages** (coupes, vitesse, fondus, textes, musique, format TikTok 9:16…).

**Tout reste sur ton téléphone** : les fichiers ne sont jamais envoyés en ligne, il n'y a pas de limite de taille, et c'est le téléphone qui calcule les montages (encodage matériel Android / Media3). Pas besoin de PC.

```
 Claude ──MCP──▶ Relais (Supabase, gratuit) ◀──connexion── App Android
                 ne transporte que les commandes          stocke + monte
                 et de petites images d'aperçu            les vidéos
```

## Installation

1. Télécharge **`video-studio/VideoStudio.apk`** sur ton téléphone (Android 10 ou plus) et installe-le (autorise « applis inconnues » si demandé).
2. Ajoute tes fichiers avec **＋**, ou depuis la galerie : *Partager → Video Studio*.
3. Onglet **Claude** :
   - active **« Connecté à Claude »** (une notification indique que la connexion est active) ;
   - **Copier** l'adresse, puis sur claude.ai : **Paramètres → Connecteurs → Ajouter un connecteur personnalisé**, colle-la (nom : *Video Studio*).
4. Dans une conversation avec le connecteur activé :
   > « Regarde mes vidéos de vacances et fais un best-of de 30 s en vertical avec la musique *summer*. »

Le montage apparaît dans l'onglet **Montages** et dans la galerie (`Movies/VideoStudio`).

Pour Claude Code : `claude mcp add --transport http video-studio <adresse copiée>`

## Bon à savoir

- L'app doit être **connectée** (interrupteur activé + Internet) quand tu demandes quelque chose à Claude. Sinon Claude te dira que le téléphone n'est pas joignable.
- Pour un long montage : garde l'app ouverte et le téléphone branché.
- Les fichiers ajoutés avec **＋** ne sont pas copiés (l'app garde juste un accès). « Retirer » un fichier l'enlève de l'app sans toucher à l'original. Les fichiers reçus par *Partager* sont copiés dans le dossier de l'app.
- L'adresse du connecteur contient une clé secrète propre à ton téléphone : ne la partage pas. « Créer une nouvelle adresse secrète » invalide l'ancienne.

## Outils MCP disponibles pour Claude

| Outil | Description |
|---|---|
| `list_media`, `get_media_info` | Bibliothèque, notes de l'utilisateur, recette des montages |
| `view_frame` | Voir l'image à un instant précis |
| `view_storyboard` | Planche contact horodatée pour « regarder » une vidéo |
| `detect_scenes` | Changements de plan (par échantillonnage) |
| `analyze_audio` | Silences (couper les blancs) et niveau sonore |
| `create_montage` + `get_job` / `list_jobs` | Montage : clips coupés, vitesse 0.25–4×, volume/muet, fondus au noir entre clips, textes par clip ou sur la timeline, musique de fond en boucle, fondus d'ouverture/fin, 16:9 / 9:16 / 1:1 / 4:5 / 4:3, recadrage ou bandes noires, brouillon 480p ou final 1080p |
| `update_media`, `delete_media` | Renommer, annoter, retirer |
| `import_from_url` | Télécharger un fichier vers le téléphone |
| `device_status` | Connexion, batterie, espace libre |

## Structure

- `android/` — l'app (Kotlin, WebView pour l'interface, Media3 Transformer pour le montage, service de connexion au relais).
- `relay/` — le relais MCP : Edge Function Supabase (`index.ts`) et sa base (`schema.sql`). Déployé sur le projet Supabase `video-studio-relay`.

## Recompiler l'APK

```bash
cd video-studio/android
./gradlew assembleRelease     # nécessite le SDK Android 36 (ANDROID_HOME)
```
Le workflow GitHub `.github/workflows/video-studio-apk.yml` le compile aussi (onglet *Actions* → artefact *VideoStudio-apk*). L'APK est signé avec une clé de debug : si tu installes une version compilée ailleurs, désinstalle d'abord l'ancienne.

Pour utiliser ton propre relais : déploie `relay/index.ts` comme Edge Function `video-studio` (sans vérification JWT), applique `relay/schema.sql`, et change `RELAY_URL` dans `android/app/build.gradle.kts`.
