plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

// CI (GitHub Actions) passes the upload key as env vars instead of key.properties:
// ANDROID_KEYSTORE_PATH (decoded from the ANDROID_KEYSTORE_BASE64 secret),
// ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS, ANDROID_KEY_PASSWORD.
fun env(name: String): String? = System.getenv(name)?.takeIf { it.isNotBlank() }
val envKeystorePath = env("ANDROID_KEYSTORE_PATH")
val hasEnvSigning = envKeystorePath != null && file(envKeystorePath).exists() &&
    listOf("ANDROID_KEYSTORE_PASSWORD", "ANDROID_KEY_ALIAS", "ANDROID_KEY_PASSWORD").all { env(it) != null }

// key.properties wins when it's present; otherwise the CI env vars.
val requiredKeys = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
val useKeyProperties = keystorePropertiesFile.exists()
val hasReleaseSigning = if (useKeyProperties) {
    requiredKeys.all { !keystoreProperties.getProperty(it).isNullOrBlank() } &&
        file(keystoreProperties.getProperty("storeFile")).exists()
} else {
    hasEnvSigning
}

// Debug-signed release builds are opt-in only (e.g. CI dry runs without secrets):
// ALLOW_DEBUG_SIGNING=true. They can't go to Play and are easy to ship by mistake.
val allowDebugSigning = env("ALLOW_DEBUG_SIGNING") == "true"

android {
    namespace = "space.d11s.niceproportions"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "space.d11s.niceproportions"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (useKeyProperties && hasReleaseSigning) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            } else if (hasEnvSigning) {
                keyAlias = env("ANDROID_KEY_ALIAS")
                keyPassword = env("ANDROID_KEY_PASSWORD")
                storeFile = file(envKeystorePath!!)
                storePassword = env("ANDROID_KEYSTORE_PASSWORD")
            }
        }
    }

    buildTypes {
        release {
            // Sign with the upload key (key.properties or the CI env vars). The debug
            // key is only used when ALLOW_DEBUG_SIGNING=true is set explicitly.
            signingConfig = if (!hasReleaseSigning && allowDebugSigning) {
                signingConfigs.getByName("debug")
            } else {
                signingConfigs.getByName("release")
            }
        }
    }
}

// Fail early, with a clear message, if a release build is requested without
// a usable upload key and without the explicit debug opt-in.
gradle.taskGraph.whenReady {
    val wantsRelease = allTasks.any { it.project == project && it.name.contains("Release") }
    if (wantsRelease && !hasReleaseSigning) {
        if (allowDebugSigning) {
            logger.warn("ALLOW_DEBUG_SIGNING=true: this release build is DEBUG-SIGNED (not for Play).")
        } else {
            val detail = if (useKeyProperties) {
                val missing = requiredKeys.filter { keystoreProperties.getProperty(it).isNullOrBlank() }
                if (missing.isNotEmpty()) {
                    "android/key.properties lacks ${missing.joinToString()}"
                } else {
                    "storeFile in android/key.properties does not exist"
                }
            } else {
                "no android/key.properties and no ANDROID_KEYSTORE_PATH/ANDROID_KEYSTORE_PASSWORD/" +
                    "ANDROID_KEY_ALIAS/ANDROID_KEY_PASSWORD env vars"
            }
            throw GradleException(
                "Release signing is not configured: $detail. Release builds must be signed " +
                    "with the upload key; set ALLOW_DEBUG_SIGNING=true to build a debug-signed " +
                    "release on purpose."
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
