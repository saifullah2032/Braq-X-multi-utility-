allprojects {
    repositories {
        google()
        mavenCentral()
    }

    // Workaround for sensors_plus namespace issue with AGP 8+
    gradle.projectsEvaluated {
        tasks.withType<JavaCompile> {
            options.compilerArgs.addAll(arrayOf("-Xlint:-unchecked", "-Xlint:-deprecation"))
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

    // Add namespace to library modules that don't have it
    afterEvaluate {
        if (pluginManager.hasPlugin("com.android.library")) {
            extensions.getByType<com.android.build.api.dsl.LibraryExtension>().apply {
                if (namespace == null) {
                    namespace = "com.example.barq_x"
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
