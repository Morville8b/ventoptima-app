import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "dk.ventoptima.app"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "dk.ventoptima.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36

        versionCode = 33
        versionName = "1.0.23"

        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            val keystoreProperties = Properties()
            val keystoreFile = rootProject.file("key.properties")

            if (keystoreFile.exists()) {
                keystoreFile.inputStream().use { keystoreProperties.load(it) }

                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
            }
        }
    }

    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
}