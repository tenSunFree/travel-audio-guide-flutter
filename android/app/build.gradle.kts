import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing config
// If key.properties cannot be found during local development, automatically fallback to using debug key for signing.
// Ensures that environments without signing (such as those cloned by a new colleague or forked for CI) can still run.
// `flutter build apk --release` will not directly fail to build.
// On CI, GitHub Actions restores the android/key.properties + keystore files from secrets.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties()
val hasKeystoreProperties = keystorePropertiesFile.exists()
if (hasKeystoreProperties) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.tensunfree.flutter_travel_audio_guide.flutter_travel_audio_guide"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required for java.time APIs (used by Health Connect) on API < 26 desugaring;
        // also needed on API 26+ for coreLibraryDesugaring support in older minSdks.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.tensunfree.flutter_travel_audio_guide.flutter_travel_audio_guide"
        // Health Connect requires API 26+.
        minSdk = 26
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Flavor: staging / production
    // - Add ".staging" suffix to the staging applicationId to allow it to coexist and install with the official version on the same device.
    // - Keep the production applicationId unchanged to prevent changes after official release.
    // - Place the corresponding google-services.json for each flavor in
    // android/app/src/staging/google-services.json
    // android/app/src/production/google-services.json
    // The Android Gradle Plugin will automatically fetch the corresponding files based on the flavor source set; no additional configuration is required.
    flavorDimensions += "environment"
    productFlavors {
        create("staging") {
            dimension = "environment"
            applicationIdSuffix = ".staging"
            versionNameSuffix = "-staging"
            resValue("string", "app_name", "Travel Audio Guide Staging")
        }
        create("production") {
            dimension = "environment"
            resValue("string", "app_name", "Travel Audio Guide")
        }
    }

    signingConfigs {
        create("release") {
            if (hasKeystoreProperties) {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            // Use the official signature only if there is a key.properties file (local or after CI restoration); otherwise, use the debug key for fallback.
            signingConfig = if (hasKeystoreProperties) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("androidx.health.connect:connect-client:1.1.0-rc01")
}
