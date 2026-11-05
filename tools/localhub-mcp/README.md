# LocalHub — ton GitHub 100 % local pour Claude (MCP)

LocalHub est un **serveur MCP** qui donne à Claude tout ce que fait GitHub — dépôts, fichiers,
branches, commits, tickets, pull requests, revues, versions — **plus une usine à APK Android**.
Tout reste sur ton ordinateur : **aucun serveur, aucun compte, aucun port réseau ouvert**.
Claude le lance lui-même et lui parle par l’entrée/sortie standard (stdio).

- Aucune dépendance npm : il suffit de **Node.js 18+** et de **git 2.40+**.
- Fonctionne sous Windows, macOS, Linux, et sur Android avec Termux.
- Les dépôts sont de vrais dépôts git : tu peux faire `git clone`, `git push` et `git pull` dessus.

## Installation

```bash
# copie le dossier tools/localhub-mcp où tu veux, puis :
node /chemin/vers/localhub-mcp/src/server.js   # test : affiche « prêt (66 outils) », Ctrl+C pour quitter
```

### Claude Code

```bash
claude mcp add localhub -s user -- node /chemin/vers/localhub-mcp/src/server.js
```

### Claude Desktop

Réglages → Développeur → Modifier la configuration (`claude_desktop_config.json`) :

```json
{
  "mcpServers": {
    "localhub": {
      "command": "node",
      "args": ["/chemin/vers/localhub-mcp/src/server.js"],
      "env": {
        "LOCALHUB_HOME": "/chemin/vers/LocalHub",
        "LOCALHUB_APK_DIR": "/chemin/vers/Téléchargements/APK",
        "ANDROID_HOME": "/chemin/vers/Android/Sdk"
      }
    }
  }
}
```

Sous Windows, écris les chemins avec des `\\` (ex. `"C:\\Users\\moi\\localhub-mcp\\src\\server.js"`).
Redémarre Claude Desktop : les outils « localhub » apparaissent.

### Réglages (variables d’environnement, toutes facultatives)

| Variable | Rôle | Défaut |
|---|---|---|
| `LOCALHUB_HOME` | Où sont stockés dépôts et données | `~/LocalHub` |
| `LOCALHUB_APK_DIR` | Boîte de sortie des APK produits | `~/LocalHub/apk` |
| `LOCALHUB_OWNER` | Ton nom de propriétaire par défaut | nom d’utilisateur |
| `LOCALHUB_USER_NAME` / `LOCALHUB_USER_EMAIL` | Auteur des commits | config git globale |
| `ANDROID_HOME` | SDK Android (sinon cherché aux emplacements habituels) | — |
| `LOCALHUB_GODOT` | Exécutable Godot 4 (projets Godot comme HIGHVALE) | `godot` |
| `LOCALHUB_KEYSTORE_PASSWORD` | Mot de passe de la clé de signature | — |

## Pour construire des APK

Il faut le **JDK 17+** et le **SDK Android** (le plus simple : installer Android Studio une fois,
qui installe le SDK dans `~/Android/Sdk`, `~/Library/Android/sdk` ou `%LOCALAPPDATA%\Android\Sdk`).
Demande à Claude « vérifie mon environnement Android » : l’outil `android_environment` dit ce qui manque.

Les applis créées par `create_android_app` contiennent le wrapper Gradle : rien d’autre à installer.
Au tout premier build, Gradle télécharge ses composants (une seule fois, quelques minutes).

Types de projets reconnus automatiquement : **Gradle/Android Studio** (Java/Kotlin), **Godot 4**,
**Flutter**, **Capacitor**, ou n’importe quelle commande via un fichier `localhub.json` :

```json
{
  "build": { "type": "custom", "command": "./mon-script.sh", "apk_glob": "out/**/*.apk" },
  "ci": "npm test"
}
```

## Exemples à demander à Claude

- « Crée une appli Android WebView “Mes Notes” avec une page HTML de prise de notes, puis fais-moi l’APK. »
- « Construis l’APK de HIGHVALE en debug et copie-le dans mon dossier Téléchargements. »
- « Installe le dernier APK sur mon téléphone et lance-le. » (câble USB ou débogage Wi-Fi)
- « Il plante au démarrage : montre-moi les logs du téléphone. »
- « Crée une branche `menu`, change le titre, ouvre une pull request, vérifie-la et fusionne-la. »
- « Publie la version : monte la version, signe avec ma clé et joins l’APK à la release. »

## Les 66 outils

**Comme GitHub**

| Domaine | Outils |
|---|---|
| Dépôts | `create_repository`, `list_repositories`, `get_repository`, `update_repository` (renommer, description, sujets, branche par défaut), `delete_repository`, `fork_repository`, `import_repository`, `export_repository` (.bundle), `star_repository` |
| Fichiers | `get_file_contents`, `get_tree`, `create_or_update_file`, `push_files` (plusieurs fichiers, ou dossiers du disque), `delete_file`, `checkout_to_folder` |
| Branches & commits | `list_branches`, `create_branch`, `delete_branch`, `list_commits`, `get_commit`, `compare`, `blame`, `revert_commit` |
| Tags & versions | `list_tags`, `create_tag`, `delete_tag`, `create_release` (notes générées, fichiers joints), `list_releases`, `get_release`, `upload_release_asset`, `delete_release` |
| Tickets | `create_issue`, `list_issues`, `get_issue`, `update_issue`, `add_issue_comment`, `list_labels` |
| Pull requests | `create_pull_request` (aussi depuis un fork), `list_pull_requests`, `get_pull_request` (diff, conflits), `update_pull_request`, `create_review`, `merge_pull_request` (merge, squash, rebase en avance rapide ; « Fixes #12 » ferme le ticket) |
| Recherche | `search_code` (un dépôt ou tous), `repository_stats` (langages, contributeurs) |
| « Actions » locales | `run_workflow` (tests sur une branche ou une PR, copie isolée), `list_workflow_runs`, `get_workflow_run` |

**En plus de GitHub : Android et APK**

| Outil | Rôle |
|---|---|
| `android_environment` | Vérifie SDK, Java, Gradle, adb, apksigner, Godot, Flutter |
| `create_android_app` | Nouveau dépôt avec appli Android prête à compiler (native Java ou WebView HTML/JS) |
| `build_apk` | Construit l’APK d’une branche, d’un tag ou d’une PR ; peut le joindre à une version, le copier, l’installer |
| `list_builds`, `get_build` | Historique et journaux des builds |
| `list_apks`, `apk_info`, `delete_apk` | Boîte de sortie ; analyse (paquet, version, SDK, permissions, ABI, signature, SHA-256) |
| `send_apk` | **Envoi local** : copie dans un dossier (Téléchargements, clé USB, dossier synchronisé) ou dans `Download` du téléphone par adb |
| `list_devices`, `connect_device` | Téléphones connectés (USB ou débogage sans fil avec code d’appairage) |
| `install_apk`, `uninstall_app`, `device_logs` | Installer/lancer, désinstaller, lire les journaux et plantages |
| `create_keystore`, `sign_apk` | Clé de signature et signature (zipalign + apksigner) |
| `set_app_version` | Monte versionCode/versionName (Gradle ou Godot) avec un commit |
| `publish_apk_release` | Tout-en-un : version → build → signature → tag + release → envoi/installation |

## Où sont mes données ?

```
~/LocalHub/
  repos/<propriétaire>/<dépôt>.git    dépôts git (git clone ~/LocalHub/repos/moi/appli.git)
  meta/<propriétaire>/<dépôt>.json    tickets, PR, versions, builds
  releases/…                          fichiers joints aux versions
  workspaces/…                        copies de travail des builds (caches Gradle conservés)
  builds/…                            journaux
  keys/                               clés de signature — À SAUVEGARDER
  apk/                                APK produits
```

Sauvegarder tout LocalHub = copier ce dossier. **Garde une copie de `keys/`** : sans la clé,
impossible de publier une mise à jour d’une appli déjà installée.

## Sur Android avec Termux

```bash
pkg install nodejs git openjdk-17
termux-setup-storage   # pour envoyer les APK dans ~/storage/downloads
LOCALHUB_APK_DIR=~/storage/downloads node localhub-mcp/src/server.js
```

Sur le téléphone, la gestion de dépôts, tickets, PR et versions marche entièrement ; la
compilation d’APK Gradle demande un SDK Android pour Termux (plus délicat) : construis plutôt
sur l’ordinateur et envoie l’APK au téléphone avec `send_apk` (« device ») ou `install_apk`.

## Tests

```bash
npm test                                            # forge (dépôts, PR, fusions, conflits, forks…)
LOCALHUB_TEST_APK=1 ANDROID_HOME=~/Android/Sdk npm test   # + build réel, signature et release d’un APK
```
