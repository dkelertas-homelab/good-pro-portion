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
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Always sign release builds with the upload key. There is deliberately
            // no debug fallback: a debug-signed release can't be uploaded to Play
            // and is easy to ship by mistake. Debug builds don't need key.properties.
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

// Fail early, with a clear message, if a release build is requested without
// the signing config (see android/key.properties in the README).
gradle.taskGraph.whenReady {
    val wantsRelease = allTasks.any { it.project == project && it.name.contains("Release") }
    if (wantsRelease) {
        val required = listOf("storeFile", "storePassword", "keyAlias", "keyPassword")
        val missing = if (keystorePropertiesFile.exists()) {
            required.filter { keystoreProperties.getProperty(it).isNullOrBlank() }
        } else {
            required
        }
        if (missing.isNotEmpty()) {
            throw GradleException(
                "Release signing is not configured: android/key.properties is missing " +
                    "or lacks ${missing.joinToString()}. Release builds must be signed " +
                    "with the upload key; there is no debug fallback."
            )
        }
        if (!file(keystoreProperties.getProperty("storeFile")).exists()) {
            throw GradleException("Release signing: storeFile in android/key.properties does not exist.")
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
