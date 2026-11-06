import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Релизная подпись. key.properties и *.jks в .gitignore: секретов в репозитории нет.
// Если файла или keystore нет — release собирается debug-ключом, чтобы обычная
// сборка не требовала чужих секретов.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    FileInputStream(keystorePropertiesFile).use { keystoreProperties.load(it) }
}
val releaseKeystore = keystoreProperties.getProperty("storeFile")
    ?.let { file(it) }
    ?.takeIf { it.exists() }

android {
    namespace = "com.norman.english_edu"
    // Литерал, а не flutter.compileSdkVersion: смена дефолта во Flutter не
    // должна незаметно менять Android-таргет (ADR-017).
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        // Требование flutter_local_notifications 10+: java.time в minSdk 26.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    signingConfigs {
        if (releaseKeystore != null) {
            create("release") {
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
                storeFile = releaseKeystore
                storePassword = keystoreProperties.getProperty("storePassword")
            }
        }
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.norman.english_edu"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // sentry_flutter 10.x requires minSdk 26 (Android 8.0).
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        // Требование flutter_local_notifications: методов больше лимита DEX.
        multiDexEnabled = true
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Реальный keystore, если он есть; иначе debug-ключ, иначе CI и
            // локальная сборка требовали бы чужих секретов.
            signingConfig = if (releaseKeystore != null) {
                signingConfigs.getByName("release")
            } else {
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
    // Бэкпорт java.time для minSdk 26 — требование flutter_local_notifications.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
