import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// İmzalama:
//  • release  → android/key.properties varsa oradan (mağaza yükleme anahtarı).
//  • yoksa    → app/debug.keystore (repoya BİLEREK konuldu; şifresi herkese
//               açık "android"). Mağaza anahtarı DEĞİL — amacı: CI'nın ürettiği
//               test APK'larının her derlemede AYNI imzayla çıkması, böylece
//               test cihazlarında sürümü kaldırmadan güncelleyebilmek.
// Şablon: android/key.properties.example. Gerçek yükleme anahtarı + key.properties
// android/.gitignore'da.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.hattimudafaa.hatti_mudafaa"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.hattimudafaa.hatti_mudafaa"
        // Flame + programatik Canvas/shader tabanı için Android 7.0 taban alınır.
        minSdk = 24
        // targetSdk / compileSdk Flutter sürümüyle güncellensin.
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Repoya konulan sabit test anahtarı (debug + key.properties yoksa
        // release fallback). Standart Android debug anahtarı değerleri.
        getByName("debug") {
            storeFile = file("debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
        // Release imza yapılandırması yalnızca key.properties varsa oluşturulur.
        if (keystorePropertiesFile.exists()) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig =
                signingConfigs.findByName("release") ?: signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
