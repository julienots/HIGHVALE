#!/usr/bin/env bash
# Exporte l'APK Android de HIGHVALE.
# Prérequis : Godot 4.3, modèles d'export 4.3 installés, SDK Android
# (platform-tools, build-tools 34) et JDK 17+ déclarés dans les paramètres
# de l'éditeur (Éditeur → Paramètres → Export → Android), avec un keystore.
# Utilisation : tools/build_apk.sh [chemin/vers/godot] [debug|release]
GODOT="${1:-godot}"
MODE="${2:-debug}"
cd "$(dirname "$0")/.." || exit 1
mkdir -p build
"$GODOT" --headless --import >/dev/null 2>&1 || "$GODOT" --headless --editor --quit >/dev/null 2>&1
"$GODOT" --headless "--export-$MODE" "Android" "build/HIGHVALE-$MODE.apk"
ls -la "build/HIGHVALE-$MODE.apk"
