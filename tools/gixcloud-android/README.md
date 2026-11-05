# GIXCLOUD pour Android — ton GitHub sur le téléphone, branché aux IA (MCP)

L'application GIXCLOUD fait tourner sur le téléphone un **GitHub complet** et un **serveur MCP intégré** :
n'importe quelle IA compatible MCP (Claude Code, Claude Desktop, Cursor…) peut s'y brancher
par le Wi-Fi local et utiliser ses **108 outils**, et n'importe quel client git peut faire
`git clone` / `git push` / `git pull` dessus, comme sur github.com. Aucun compte, aucun cloud :
les données restent dans le téléphone.

## Installer

1. Copier `GIXCLOUD-2.0.0.apk` sur le téléphone et l'ouvrir (autoriser « Installer des applis inconnues »).
2. Ouvrir GIXCLOUD : le serveur démarre (notification « GIXCLOUD — MCP actif »).
3. Onglet **IA / MCP** : l'adresse (`http://IP-du-téléphone:8765/mcp`) et le **jeton secret** s'affichent,
   avec des boutons pour copier la commande ou la configuration.

Android 8.0 minimum (API 26).

## Brancher une IA

Le téléphone et l'ordinateur doivent être sur le **même Wi-Fi** (ou l'ordinateur sur le partage de connexion du téléphone).

**Claude Code**

```bash
claude mcp add --transport http gixcloud http://192.168.1.20:8765/mcp --header "Authorization: Bearer gix_…"
```

**Claude Desktop, Cursor et autres** (fichier de configuration MCP) :

```json
{
  "mcpServers": {
    "gixcloud": {
      "command": "npx",
      "args": ["-y", "mcp-remote", "http://192.168.1.20:8765/mcp", "--allow-http", "--header", "Authorization: Bearer gix_…"]
    }
  }
}
```

**Toute IA qui accepte une URL MCP** : transport « Streamable HTTP », URL `http://IP:8765/mcp`,
en-tête `Authorization: Bearer <jeton>`.

Les assistants hébergés sur Internet (claude.ai, ChatGPT…) ne peuvent pas joindre une adresse
de réseau local : il faut une IA qui tourne sur un appareil du même réseau.

## Ce que GIXCLOUD sait faire (108 outils MCP)

| Fonction GitHub | Outils |
|---|---|
| Dépôts | `create_repository`, `list_repositories`, `get_repository`, `update_repository`, `set_repository_settings` (archiver, sujets, site), `delete_repository`, `fork_repository`, `import_repository` (depuis GitHub/GitLab/URL), `star_repository`, `list_starred`, `repository_stats`, `get_clone_urls` |
| **git clone / push / pull** | protocole git « smart HTTP » : `git clone http://IP:8765/git/<propriétaire>/<dépôt>.git` (mot de passe = jeton) |
| Code | `get_file_contents`, `get_tree`, `create_or_update_file`, `push_files`, `delete_file`, `search_code`, `blame`, fichiers bruts `/raw`, archives ZIP `/archive` |
| Branches & historique | `list_branches`, `create_branch`, `rename_branch`, `delete_branch`, `list_commits`, `get_commit`, `compare`, `merge_branches`, `revert_commit`, `cherry_pick`, `list_tags`, `create_tag`, `delete_tag` |
| Protection de branches | `set_branch_protection` (PR obligatoire, approbations, statuts de CI requis, push forcé/suppression interdits — appliqué aussi aux `git push`), `get_branch_protection`, `remove_branch_protection` |
| Tickets | `create_issue`, `list_issues`, `get_issue`, `update_issue` (fermer, étiquettes, assignés, jalon, verrouiller), `add_issue_comment`, `search_issues` |
| Étiquettes & jalons | `create_label`, `list_labels`, `delete_label`, `create_milestone`, `list_milestones` (avancement), `update_milestone` |
| Pull requests | `create_pull_request` (aussi depuis un fork), `list_pull_requests`, `get_pull_request` (diff, conflits, revues, checks), `update_pull_request`, `update_pull_request_branch`, `create_review`, `merge_pull_request` (merge, squash, rebase ; « Fixes #n » ferme le ticket) |
| CI (statuts) | `create_check_run`, `list_check_runs` : une IA ou un PC publie le résultat des tests/builds, la fusion peut l'exiger |
| Versions | `create_release` (notes générées), `list_releases`, `get_release`, `upload_release_asset`, `delete_release` |
| Wiki | `list_wiki_pages`, `get_wiki_page`, `write_wiki_page`, `delete_wiki_page` (versionné dans `<dépôt>.wiki`) |
| Gists | `create_gist`, `list_gists`, `get_gist`, `update_gist`, `delete_gist` (clonables aussi) |
| Pages | `enable_pages`, `get_pages`, `disable_pages` : site statique servi sur `/pages/<propriétaire>/<dépôt>/` |
| Discussions | `create_discussion`, `list_discussions`, `get_discussion`, `add_discussion_comment` (réponse acceptée) |
| Projets (kanban) | `create_project`, `list_projects`, `get_project`, `add_project_card`, `move_project_card` |
| Activité | `list_events`, `list_notifications`, `mark_notifications_read`, webhooks `create_webhook` / `list_webhooks` / `delete_webhook` (signés `X-Hub-Signature-256`) |
| Accès | `create_token`, `list_tokens`, `revoke_token`, `whoami` : un jeton par IA ou personne, read / write / admin ; ses commits portent son nom |
| Synchro avec un vrai GitHub | `list_remotes`, `add_remote`, `remove_remote`, `push_to_remote`, `pull_from_remote` |
| APK et téléphone | `upload_apk`, `list_apks`, `apk_info`, `install_apk`, `save_apk_to_downloads`, `delete_apk`, `list_installed_apps`, `launch_app`, `uninstall_app`, `device_info` |

Ce qui n'est pas sur le téléphone : exécuter la CI elle-même (Android ne peut pas lancer Gradle) —
la CI tourne sur le PC (GIXCLOUD PC : `run_workflow`, `build_apk`) et publie son résultat avec `create_check_run`.

## Routes HTTP (toutes avec le jeton)

| Route | Rôle |
|---|---|
| `POST /mcp` | Protocole MCP (JSON-RPC) |
| `PUT /upload/<nom>.apk[?install=1]` | Envoyer un APK au téléphone (corps brut) |
| `GET /download/apk/<nom>` | Récupérer un APK |
| `GET /download/release/<propriétaire>/<dépôt>/<tag>/<fichier>` | Fichier joint à une version |
| `GET/POST /git/<propriétaire>/<dépôt>.git/…` | Protocole git (clone, fetch, push) — authentification Basic, mot de passe = jeton |
| `GET /raw/<propriétaire>/<dépôt>/<ref>/<chemin>` | Fichier brut |
| `GET /archive/<propriétaire>/<dépôt>/<ref>.zip` | Archive ZIP |
| `GET /pages/<propriétaire>/<dépôt>/…` | Site GIXCLOUD Pages (**sans jeton**, si activé) |

Envoyer un APK depuis l'ordinateur :

```bash
curl -T monappli.apk -H "Authorization: Bearer gix_…" http://192.168.1.20:8765/upload/monappli.apk
```

ou avec GIXCLOUD sur PC : `build_apk` / `send_apk` avec `send_to` / `to` = `gixcloud://192.168.1.20:8765?token=gix_…&install=1`.

## Sécurité

- Le jeton est généré au premier lancement ; « Nouveau jeton » dans Réglages le change.
- Réglages → désactiver « Accessible depuis le Wi-Fi local » : seul le téléphone lui-même (127.0.0.1) peut se connecter.
- Le trafic n'est pas chiffré (HTTP) : à utiliser sur un réseau de confiance (maison), pas sur un Wi-Fi public.
- Installer ou désinstaller une appli demande toujours une confirmation sur le téléphone.

## Construire l'APK

```bash
cd tools/gixcloud-android
./gradlew assembleRelease     # → app/build/outputs/apk/release/app-release.apk
```

Tests sans téléphone (code réel sur la JVM, vrai client git, interface dans Chromium) : `test-jvm/run.sh`.

Il faut le JDK 17+ et le SDK Android (variable `ANDROID_HOME` ou fichier `local.properties`).
Moteur git : JGit 5.13 ; interface : `app/src/main/assets/ui/index.html`.
