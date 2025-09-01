plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.myafmzd"

    // API 36 está estable (Android 16). Requiere AGP y Studio mínimos.
    // targetSdk 35 cumple con Google Play (31-ago-2025+).
    compileSdk = 36

    // Si compilas código/FFI nativo, fija la NDK a la versión por defecto de AGP 8.12.
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.myafmzd"
        minSdk = 24
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            // Configura tu firma de release más adelante (firma propia).
            signingConfig = signingConfigs.getByName("debug")
            // minifyEnabled = true
            // proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
        }
    }
}

flutter {
    source = "../.."
}
