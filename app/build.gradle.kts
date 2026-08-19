plugins {
    id("com.android.application")
}

android {
    namespace = "br.com.gamoravet.app"
    compileSdk = 35

    signingConfigs {
        getByName("debug") {
            enableV1Signing = true
            enableV2Signing = true
        }
    }

    defaultConfig {
        applicationId = "br.com.gamoravet.s23test"
        minSdk = 24
        targetSdk = 35
        versionCode = 4
        versionName = "0.4.0-s23"
    }
}
