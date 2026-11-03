import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseRequested = gradle.startParameter.taskNames.any {
    it.contains("release", ignoreCase = true)
}
val signingPropertiesFile = rootProject.file("key.properties")
val signingProperties = Properties()

if (signingPropertiesFile.isFile) {
    signingPropertiesFile.inputStream().use(signingProperties::load)
} else if (releaseRequested) {
    error("android/key.properties is required for release builds. See README.md for the required signing properties.")
}

fun requiredSigningProperty(name: String): String =
    signingProperties.getProperty(name)?.takeIf(String::isNotBlank)
        ?: error("Missing release signing property: $name")

android {
    namespace = "com.bazartrack.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.bazartrack.app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (signingPropertiesFile.isFile) {
            create("release") {
                val keystore = file(requiredSigningProperty("storeFile"))
                require(keystore.isFile) {
                    "Release keystore does not exist: $keystore"
                }
                storeFile = keystore
                storePassword = requiredSigningProperty("storePassword")
                keyAlias = requiredSigningProperty("keyAlias")
                keyPassword = requiredSigningProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (signingPropertiesFile.isFile) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
