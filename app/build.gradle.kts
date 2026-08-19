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
        applicationId = "br.com.gamoravet.app"
        minSdk = 24
        targetSdk = 35
        versionCode = 10
        versionName = "1.0.0"
    }
}
