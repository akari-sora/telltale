plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
}

android {
    namespace = "com.cbstudio.telltale.automotive"
    compileSdk = 36

    defaultConfig {
        // Prototype identity until AA-00 category eligibility is accepted.
        applicationId = "com.cbstudio.telltale.carproto.aaos"

        minSdk = 29
        targetSdk = 36

        versionCode = 1
        versionName = "0.0.1-aa01"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    implementation(project(":car-core"))
    implementation("androidx.car.app:app-automotive:1.7.0")
}
