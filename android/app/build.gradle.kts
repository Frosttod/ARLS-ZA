import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Signing material lives outside the repository. See PROCEDURA_RELEASE.md.
// android/key.properties is gitignored and holds: storeFile, storePassword, keyAlias, keyPassword.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}

// Fail the build instead of falling back to debug keys. Set by the release pipeline:
//   flutter build appbundle --release -Prequire-signing=true
val requireSigning = (project.findProperty("require-signing") as String?)?.toBoolean() ?: false

android {
    namespace = "com.raidodevelopment.arlsza"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.raidodevelopment.arlsza"
        minSdk = 26          // vibration amplitude control (design doc §14.2)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                storeFile = keystoreProperties.getProperty("storeFile")?.let { file(it) }
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                if (requireSigning) {
                    throw GradleException(
                        "Release signing requested but android/key.properties is missing. " +
                            "See PROCEDURA_RELEASE.md."
                    )
                }
                // Local release builds stay usable, but this artifact must never be published.
                logger.warn(
                    "WARNING: android/key.properties not found — signing the release build with " +
                        "DEBUG keys. This artifact cannot be published to Google Play."
                )
                signingConfig = signingConfigs.getByName("debug")
            }
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
