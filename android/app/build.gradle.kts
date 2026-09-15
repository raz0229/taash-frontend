import java.util.Properties

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
}

val signingProperties = Properties()
val signingFile = rootProject.file("key.properties")
if (signingFile.exists()) signingFile.inputStream().use { signingProperties.load(it) }

android {
    namespace = "com.sheraztech.taash"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion
    System.getenv("TAASH_NDK_PATH")?.let { ndkPath = it }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    defaultConfig {
        applicationId = "com.sheraztech.taash"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Google test app ID used as fallback so builds run without env vars.
        // Override with ADMOB_APP_ID (e.g. "ca-app-pub-XXXX~YYYY") for production.
        val admobAppId = System.getenv("ADMOB_APP_ID")
            ?: "ca-app-pub-3940256099942544~3347511713"
        manifestPlaceholders["adMobAppId"] = admobAppId
    }
    signingConfigs {
        if (signingFile.exists()) create("upload") {
            keyAlias = signingProperties.getProperty("keyAlias")
            keyPassword = signingProperties.getProperty("keyPassword")
            storeFile = file(signingProperties.getProperty("storeFile"))
            storePassword = signingProperties.getProperty("storePassword")
        }
    }
    buildTypes {
        release {
            // Without owner upload credentials the release artifact is unsigned.
            // Debug signing is never silently substituted for release signing.
            if (signingFile.exists()) signingConfig = signingConfigs.getByName("upload")
        }
    }
}
kotlin { compilerOptions { jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17 } }
flutter { source = "../.." }
