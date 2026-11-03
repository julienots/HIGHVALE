plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "fr.videostudio.app"
    compileSdk = 36

    defaultConfig {
        applicationId = "fr.videostudio.app"
        minSdk = 29
        targetSdk = 35
        versionCode = 2
        versionName = "2.0.0"
        buildConfigField("String", "RELAY_URL", "\"https://pwnjdmemczrhuhsyuboc.supabase.co/functions/v1/video-studio\"")
    }
    buildFeatures { buildConfig = true }

    buildTypes {
        debug {
            // Tests en émulateur : relais local (RELAY_URL=http://10.0.2.2:9000/video-studio)
            System.getenv("RELAY_URL")?.let { buildConfigField("String", "RELAY_URL", "\"$it\"") }
        }
        release {
            isMinifyEnabled = false
            // Signé avec la clé de debug pour pouvoir installer l'APK directement
            signingConfig = signingConfigs.getByName("debug")
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions { jvmTarget = "17" }
}

dependencies {
    val media3 = "1.11.1"
    implementation("androidx.media3:media3-transformer:$media3")
    implementation("androidx.media3:media3-effect:$media3")
    implementation("androidx.media3:media3-common:$media3")
}
