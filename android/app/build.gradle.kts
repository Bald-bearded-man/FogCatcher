import groovy.json.JsonSlurper
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keyProps = Properties()
val keyFile = rootProject.file("key.properties")
if (keyFile.exists()) keyFile.inputStream().use { keyProps.load(it) }

// The launcher label comes from the active content pack.
val packJson = JsonSlurper().parse(rootProject.file("../pack/pack.json")) as Map<*, *>
val appLabel = (packJson["appName"] as String)
    .replace("&", "&amp;").replace("<", "&lt;").replace("\"", "&quot;")

android {
    namespace = "com.baldman.fogcatcher"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.baldman.fogcatcher"
        // Optional suffix for a side-by-side build flavor with its own package.
        applicationIdSuffix = System.getenv("APP_ID_SUFFIX") ?: ""
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = appLabel
    }

    signingConfigs {
        if (keyFile.exists()) {
            create("upload") {
                keyAlias = keyProps["keyAlias"] as String
                keyPassword = keyProps["keyPassword"] as String
                storeFile = file(keyProps["storeFile"] as String)
                storePassword = keyProps["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
            // Without key.properties, fall back to the debug key so local release builds work.
            signingConfig = if (keyFile.exists()) {
                signingConfigs.getByName("upload")
            } else {
                logger.warn("WARNING: android/key.properties missing, signing release with the debug key.")
                signingConfigs.getByName("debug")
            }
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
