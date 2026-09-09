import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")

if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.example.family_finance_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.family_finance_app"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (!keystorePropertiesFile.exists()) {
                throw GradleException(
                    "android/key.properties não encontrado. Configure a keystore permanente antes de gerar um APK release."
                )
            }

            val storeFilePath = keystoreProperties["storeFile"] as String?
                ?: throw GradleException("storeFile ausente em android/key.properties")
            val storePasswordValue = keystoreProperties["storePassword"] as String?
                ?: throw GradleException("storePassword ausente em android/key.properties")
            val keyAliasValue = keystoreProperties["keyAlias"] as String?
                ?: throw GradleException("keyAlias ausente em android/key.properties")
            val keyPasswordValue = keystoreProperties["keyPassword"] as String?
                ?: throw GradleException("keyPassword ausente em android/key.properties")

            storeFile = rootProject.file(storeFilePath)
            storePassword = storePasswordValue
            keyAlias = keyAliasValue
            keyPassword = keyPasswordValue
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

flutter {
    source = "../.."
}
