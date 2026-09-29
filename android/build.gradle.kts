allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
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
fun ensureTypedefsFile(moduleName: String, variant: String) {
    val capitalizedVariant = variant.substring(0, 1).uppercase() + variant.substring(1)

    val typedefsFile = rootProject.file(
        "../build/$moduleName/intermediates/annotations_typedef_file/$variant/extract${capitalizedVariant}Annotations/typedefs.txt"
    )

    typedefsFile.parentFile.mkdirs()

    if (!typedefsFile.exists()) {
        typedefsFile.writeText("")
    }
}

subprojects {
    listOf("debug", "release").forEach { variant ->
        ensureTypedefsFile(project.name, variant)
    }

    tasks.configureEach {
        val taskName = name.lowercase()

        if (taskName.startsWith("extract") && taskName.endsWith("annotations")) {
            enabled = false
        }

        if (taskName == "syncdebuglibjars") {
            doFirst {
                ensureTypedefsFile(project.name, "debug")
            }
        }

        if (taskName == "syncreleaselibjars") {
            doFirst {
                ensureTypedefsFile(project.name, "release")
            }
        }
    }
}
subprojects {
    tasks.configureEach {
        val taskName = name.lowercase()

        if (
            taskName.contains("lint") ||
            taskName == "lintvitalanalyzerelease" ||
            taskName == "lintvitalrelease"
        ) {
            enabled = false
        }
    }
}