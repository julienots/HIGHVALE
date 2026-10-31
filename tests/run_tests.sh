#!/usr/bin/env bash
# Lance les tests headless et échoue aussi sur toute erreur de script
# (une erreur d'exécution GDScript interrompt un test sans le marquer en échec).
# Utilisation : tests/run_tests.sh [chemin/vers/godot]
GODOT="${1:-godot}"
cd "$(dirname "$0")/.." || exit 1
OUT="$("$GODOT" --headless res://tests/test_runner.tscn 2>&1)"
STATUS=$?
echo "$OUT" | grep -vE "^Godot Engine|Parse JSON failed|sauvegarde illisible|^\s+at: "
if echo "$OUT" | grep -q "SCRIPT ERROR"; then
	echo "Erreurs de script détectées pendant les tests."
	exit 1
fi
exit $STATUS
