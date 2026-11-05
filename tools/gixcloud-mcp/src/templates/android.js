// Modèles de projets Android prêts à compiler en APK (Gradle + Java, sans dépendance AndroidX).

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const WRAPPER = path.join(path.dirname(fileURLToPath(import.meta.url)), 'gradle-wrapper');

const html = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const xmlRes = (s) => html(s).replace(/(["'@?])/g, '\\$1');
const groovy = (s) => String(s).replace(/["'\\$]/g, '');

/**
 * @param {{ appName: string, packageName: string, template: 'blank'|'webview', html?: string, versionName?: string, minSdk?: number }} o
 * @returns {{ path: string, content: string|Buffer, mode?: string }[]}
 */
export function androidTemplate(o) {
  const pkg = o.packageName;
  const pkgPath = pkg.replace(/\./g, '/');
  const minSdk = o.minSdk || 24;
  const files = [];
  const add = (p, content, mode) => files.push({ path: p, content, mode });

  add('settings.gradle', `pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}
rootProject.name = "${groovy(o.appName)}"
include ':app'
`);
  add('build.gradle', `plugins {
    id 'com.android.application' version '8.7.3' apply false
}
`);
  add('gradle.properties', `org.gradle.jvmargs=-Xmx2048m -Dfile.encoding=UTF-8
android.useAndroidX=false
android.nonTransitiveRClass=true
`);
  add('app/build.gradle', `plugins {
    id 'com.android.application'
}

android {
    namespace '${pkg}'
    compileSdk 34

    defaultConfig {
        applicationId '${pkg}'
        minSdk ${minSdk}
        targetSdk 34
        versionCode 1
        versionName '${o.versionName || '1.0.0'}'
    }

    buildTypes {
        release {
            minifyEnabled false
        }
    }

    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}
`);
  const internet = o.template === 'webview' ? '\n    <uses-permission android:name="android.permission.INTERNET" />\n' : '';
  add('app/src/main/AndroidManifest.xml', `<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
${internet}
    <application
        android:allowBackup="true"
        android:icon="@drawable/ic_launcher"
        android:label="@string/app_name"
        android:theme="@android:style/Theme.Material.Light.NoActionBar">
        <activity
            android:name=".MainActivity"
            android:configChanges="orientation|screenSize|keyboardHidden"
            android:exported="true">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>
</manifest>
`);
  add('app/src/main/res/values/strings.xml', `<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">${xmlRes(o.appName)}</string>
</resources>
`);
  add('app/src/main/res/drawable/ic_launcher.xml', `<?xml version="1.0" encoding="utf-8"?>
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:fillColor="#3DDC84" android:pathData="M0,0h108v108h-108z" />
    <path android:fillColor="#FFFFFF" android:pathData="M54,26 L80,78 L28,78 Z" />
</vector>
`);

  if (o.template === 'webview') {
    add(`app/src/main/java/${pkgPath}/MainActivity.java`, `package ${pkg};

import android.app.Activity;
import android.os.Bundle;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

/** Application Web : le contenu est dans app/src/main/assets/www/ (HTML, CSS, JS). */
public class MainActivity extends Activity {
    private WebView web;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        web = new WebView(this);
        WebSettings s = web.getSettings();
        s.setJavaScriptEnabled(true);
        s.setDomStorageEnabled(true);
        s.setAllowFileAccess(true);
        web.setWebViewClient(new WebViewClient());
        web.loadUrl("file:///android_asset/www/index.html");
        setContentView(web);
    }

    @Override
    public void onBackPressed() {
        if (web.canGoBack()) web.goBack();
        else super.onBackPressed();
    }
}
`);
    add('app/src/main/assets/www/index.html', o.html || `<!doctype html>
<html lang="fr">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${html(o.appName)}</title>
  <style>
    body { font-family: system-ui, sans-serif; margin: 0; min-height: 100vh; display: grid; place-items: center; background: #101418; color: #e8eef3; }
    button { font-size: 1.2rem; padding: .8rem 1.6rem; border: 0; border-radius: 12px; background: #3ddc84; color: #08210f; }
  </style>
</head>
<body>
  <main>
    <h1>${html(o.appName)}</h1>
    <p id="n">0</p>
    <button onclick="document.getElementById('n').textContent = +document.getElementById('n').textContent + 1">Toucher</button>
  </main>
</body>
</html>
`);
  } else {
    add(`app/src/main/java/${pkgPath}/MainActivity.java`, `package ${pkg};

import android.app.Activity;
import android.os.Bundle;
import android.widget.Button;
import android.widget.TextView;

public class MainActivity extends Activity {
    private int count = 0;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        TextView label = findViewById(R.id.label);
        Button button = findViewById(R.id.button);
        button.setOnClickListener(v -> label.setText(getString(R.string.app_name) + " : " + (++count)));
    }
}
`);
    add('app/src/main/res/layout/activity_main.xml', `<?xml version="1.0" encoding="utf-8"?>
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent"
    android:gravity="center"
    android:orientation="vertical"
    android:padding="24dp">

    <TextView
        android:id="@+id/label"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:text="@string/app_name"
        android:textSize="28sp" />

    <Button
        android:id="@+id/button"
        android:layout_width="wrap_content"
        android:layout_height="wrap_content"
        android:layout_marginTop="24dp"
        android:text="+1" />
</LinearLayout>
`);
  }

  add('.gitignore', '*.iml\n.gradle/\n/local.properties\n.idea/\n/build/\n/app/build/\n*.apk\n*.aab\n*.jks\n*.keystore\n');
  add('gixcloud.json', JSON.stringify({ build: { type: 'gradle', debug_task: 'assembleDebug', release_task: 'assembleRelease' } }, null, 2) + '\n');
  add('gradlew', fs.readFileSync(path.join(WRAPPER, 'gradlew')), '100755');
  add('gradlew.bat', fs.readFileSync(path.join(WRAPPER, 'gradlew.bat')));
  add('gradle/wrapper/gradle-wrapper.jar', fs.readFileSync(path.join(WRAPPER, 'gradle-wrapper.jar')));
  add('gradle/wrapper/gradle-wrapper.properties', fs.readFileSync(path.join(WRAPPER, 'gradle-wrapper.properties')));
  add('README.md', `# ${o.appName}

Application Android (${o.template === 'webview' ? 'WebView : modifiez app/src/main/assets/www/' : 'Java'}), paquet \`${pkg}\`.

Construire l’APK : outil MCP \`build_apk\`, ou \`./gradlew assembleDebug\`.
`);
  return files;
}
