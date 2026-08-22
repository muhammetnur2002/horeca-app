import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

// Читаем реальные ключи подписи релиза из android/key.properties (в .gitignore,
// на устройство не попадает и в репозиторий не коммитится). Если файла нет —
// используем debug-подпись как раньше, чтобы сборка для разработки не ломалась,
// но публиковать такой release-APK/AAB в магазины нельзя.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.akyl.horeca"
    compileSdk = 36

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    defaultConfig {
        applicationId = "com.akyl.horeca"
        // Firebase (firebase_auth/cloud_firestore) требует minSdk 23+.
        // ВНИМАНИЕ: `flutter build`/`flutter upgrade` иногда переписывает эту
        // строку обратно на flutter.minSdkVersion при "Upgrading build.gradle.kts" —
        // проверяйте после апгрейдов Flutter, что тут снова стоит 23.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
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
            // ВАЖНО: без android/key.properties релиз всё ещё подписывается
            // debug-ключом (общий для всех Flutter-установок) — это нельзя
            // публиковать в Play Store. Создайте свой keystore и key.properties,
            // тогда сборка автоматически переключится на него.
            signingConfig = if (hasReleaseKeystore)
                signingConfigs.getByName("release")
            else
                signingConfigs.getByName("debug")

            // R8: минификация + удаление неиспользуемых ресурсов в релизе.
            // Уменьшает размер APK и затрудняет реверс-инжиниринг кода.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }

    // Навсегда отключаем нативную C++ сборку
    configurations.all {
        exclude(group = "org.jetbrains.kotlin", module = "kotlin-stdlib-jdk7")
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

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
