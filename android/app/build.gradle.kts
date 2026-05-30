plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "co.tunnl.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        // Required for Razorpay + java.time desugaring on older Android versions
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "co.tunnl.app"
        // Razorpay requires API 21+
        minSdk = maxOf(flutter.minSdkVersion, 21)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            // Use debug signing for now so `flutter run --release` works.
            // Replace with your own keystore before publishing to Play Store.
            signingConfig = signingConfigs.getByName("debug")

            // ✅ Disable code shrinking/obfuscation. Razorpay's native bridge
            // (and many Flutter plugins) crash at runtime if R8 strips
            // reflective classes. Re-enable later with proper keep rules.
            isMinifyEnabled = false
            isShrinkResources = false

            // If you ever turn minification back on, ProGuard rules below
            // will be applied. Safe to keep referenced even when disabled.
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    // Required so Razorpay's CheckOutTheme parent (Theme.AppCompat.*) resolves
    implementation("androidx.appcompat:appcompat:1.7.0")
    implementation("androidx.multidex:multidex:2.0.1")
}

flutter {
    source = "../.."
}
