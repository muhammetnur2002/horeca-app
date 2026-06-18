allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Принудительно убираем нативную сборку для всех subprojects
subprojects {
    afterEvaluate {
        extensions.findByName("android")?.let { ext ->
            try {
                val android = ext as com.android.build.gradle.BaseExtension
                android.compileSdkVersion(36)
            } catch (_: Exception) {}
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}