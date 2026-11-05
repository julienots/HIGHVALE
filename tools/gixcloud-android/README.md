# GIXCLOUD pour Android — ton GitHub sur le téléphone, branché aux IA (MCP)

L'application GIXCLOUD fait tourner sur le téléphone une forge git complète (dépôts, fichiers,
branches, commits, tickets, pull requests, revues, versions) et un **serveur MCP intégré** :
n'importe quelle IA compatible MCP (Claude Code, Claude Desktop, Cursor…) peut s'y brancher
par le Wi-Fi local et utiliser ses 46 outils. Aucun compte, aucun cloud : les données restent
dans le téléphone.

## Installer

1. Copier `GIXCLOUD-1.0.0.apk` sur le téléphone et l'ouvrir (autoriser « Installer des applis inconnues »).
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

## Outils exposés aux IA (46)

- **Dépôts** : `create_repository`, `list_repositories`, `get_repository`, `update_repository`, `delete_repository`, `fork_repository`
- **Fichiers** : `get_file_contents`, `get_tree`, `create_or_update_file`, `push_files`, `delete_file`, `search_code`
- **Historique** : `list_branches`, `create_branch`, `delete_branch`, `list_commits`, `get_commit`, `compare`, `list_tags`, `create_tag`
- **Tickets** : `create_issue`, `list_issues`, `get_issue`, `update_issue`, `add_issue_comment`
- **Pull requests** : `create_pull_request` (aussi depuis un fork), `list_pull_requests`, `get_pull_request`, `update_pull_request`, `create_review`, `merge_pull_request` (merge, squash, rebase en avance rapide ; « Fixes #n » ferme le ticket)
- **Versions** : `create_release`, `list_releases`, `get_release`, `upload_release_asset`, `delete_release`
- **APK et téléphone** : `upload_apk`, `list_apks`, `apk_info`, `install_apk` (l'utilisateur confirme), `save_apk_to_downloads`, `delete_apk`, `list_installed_apps`, `launch_app`, `uninstall_app`, `device_info`

## Routes HTTP (toutes avec le jeton)

| Route | Rôle |
|---|---|
| `POST /mcp` | Protocole MCP (JSON-RPC) |
| `PUT /upload/<nom>.apk[?install=1]` | Envoyer un APK au téléphone (corps brut) |
| `GET /download/apk/<nom>` | Récupérer un APK |
| `GET /download/release/<propriétaire>/<dépôt>/<tag>/<fichier>` | Fichier joint à une version |

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

Il faut le JDK 17+ et le SDK Android (variable `ANDROID_HOME` ou fichier `local.properties`).
Moteur git : JGit 5.13 ; interface : `app/src/main/assets/ui/index.html`.
