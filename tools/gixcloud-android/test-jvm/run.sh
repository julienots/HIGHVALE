#!/usr/bin/env bash
# Tests de l'appli GIXCLOUD sur la JVM (sans téléphone) : le vrai code Java (JGit, outils,
# serveur MCP HTTP, protocole git) tourne avec de petites cales Android, puis on le pilote
# comme une IA (MCP), avec le vrai client git, et l'interface dans Chromium (Playwright).
# Prérequis : ./gradlew assembleRelease déjà lancé, ANDROID_HOME, Java 17+, Node 18+, git.
set -euo pipefail
cd "$(dirname "$0")"
APP=../app/build/intermediates/javac/release/compileReleaseJavaWithJavac/classes
SDKJ="$ANDROID_HOME/platforms/android-34/android.jar"
mkdir -p lib out
[ -f lib/json.jar ] || curl -sSfLo lib/json.jar https://repo1.maven.org/maven2/org/json/json/20240303/json-20240303.jar
for j in org.eclipse.jgit-5.13.3.202401111512-r JavaEWAH-1.1.13 slf4j-api-1.7.36 slf4j-nop-1.7.36; do
  [ -f "lib/$j.jar" ] || cp "$(find ~/.gradle/caches -name "$j.jar" | head -1)" lib/
done
javac -nowarn -d out -cp "$SDKJ" shim/android/content/*.java shim/android/util/*.java
javac -nowarn -d out -cp "out:$APP:lib/*:$SDKJ" Harness.java
rm -rf data work && mkdir work
java -cp "out:$APP:lib/*:$SDKJ" Harness "$PWD/data" 18765 > harness.log 2>&1 &
PID=$!
trap 'kill $PID 2>/dev/null' EXIT
sleep 4
node client.mjs
(cd work && git clone -q http://gix:testtoken@127.0.0.1:18765/git/moi/demo.git demo && echo "✓ git clone par HTTP")
node client2.mjs
node ui.cjs
