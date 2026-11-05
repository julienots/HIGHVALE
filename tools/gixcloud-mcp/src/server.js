#!/usr/bin/env node
// GIXCLOUD — un « GitHub » 100 % local, utilisable par Claude via MCP (stdio).
// Dépôts git, fichiers, branches, commits, tickets, pull requests, revues,
// versions… et en plus : création, build, signature, analyse, envoi et
// installation d’APK Android. Aucun serveur, aucun compte, aucun réseau requis.

import { startServer } from './mcp.js';
import { repoTools } from './tools/repos.js';
import { collabTools } from './tools/collab.js';
import { apkTools } from './tools/apk.js';
import { HOME, APK_DIR, ensureDir } from './store.js';

ensureDir(HOME);

startServer({
  name: 'gixcloud',
  version: '1.0.0',
  instructions: `GIXCLOUD : forge git locale (équivalent de GitHub sans serveur) + usine à APK.
Données dans ${HOME} ; APK produits dans ${APK_DIR}.
- « repo » accepte « nom » ou « propriétaire/nom ».
- Dépôts clonables avec git : get_repository donne clone_command (chemin local).
- Pour une appli Android : create_android_app → build_apk (variant debug) → send_apk ou install_apk.
- Pour publier : publish_apk_release fait version + tag + build + release + envoi.
- android_environment indique ce qui manque (SDK, Java…) si un build échoue.`,
  tools: [...repoTools, ...collabTools, ...apkTools],
});
