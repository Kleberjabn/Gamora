plugins {
    id("com.android.application")
}

val releaseStoreFile = System.getenv("GAMORAVET_KEYSTORE_PATH")
val releaseStorePassword = System.getenv("GAMORAVET_KEYSTORE_PASSWORD")
val releaseKeyAlias = System.getenv("GAMORAVET_KEY_ALIAS")
val releaseKeyPassword = System.getenv("GAMORAVET_KEY_PASSWORD")
val hasReleaseSigning = !releaseStoreFile.isNullOrBlank() &&
    !releaseStorePassword.isNullOrBlank() &&
    !releaseKeyAlias.isNullOrBlank() &&
    !releaseKeyPassword.isNullOrBlank()

android {
    namespace = "br.com.gamoravet.app"
    compileSdk = 35

    signingConfigs {
        getByName("debug") {
            enableV1Signing = true
            enableV2Signing = true
        }
        if (hasReleaseSigning) {
            create("release") {
                storeFile = file(releaseStoreFile!!)
                storePassword = releaseStorePassword
                keyAlias = releaseKeyAlias
                keyPassword = releaseKeyPassword
                enableV1Signing = true
                enableV2Signing = true
            }
        }
    }

    defaultConfig {
        applicationId = "br.com.gamoravet.app"
        minSdk = 24
        targetSdk = 35
        versionCode = 12
        versionName = "1.0.1"
    }

    buildTypes {
        getByName("debug") {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
        getByName("release") {
            isMinifyEnabled = false
            isShrinkResources = false
            if (hasReleaseSigning) {
                signingConfig = signingConfigs.getByName("release")
            }
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
