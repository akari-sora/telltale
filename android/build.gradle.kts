allprojects {
    repositories {
        google()
        // Central repeatedly rate-limits this 152 MiB Robolectric runtime on CI.
        // Use Google's Central mirror for this exact artifact, including its POM;
        // Gradle requires a module's metadata and artifacts from the same repository.
        exclusiveContent {
            forRepository {
                maven {
                    url = uri("https://maven-central.storage-download.googleapis.com/maven2/")
                }
            }
            filter {
                includeVersion("org.robolectric", "nativeruntime-dist-compat", "1.0.19")
            }
        }
        mavenCentral()
    }
}

// Robolectric downloads instrumented Android SDKs inside the test JVM, separately
// from Gradle's repositories. Use the same Central mirror for those downloads.
subprojects {
    tasks.withType<org.gradle.api.tasks.testing.Test>().configureEach {
        systemProperty("robolectric.dependency.repo.url", "https://maven-central.storage-download.googleapis.com/maven2/")
        systemProperty("robolectric.dependency.repo.id", "google-maven-central")
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
// Flutter's generated/plugin subprojects keep the historical dependency on
// :app evaluation. Native car modules must not: :app depends on :car-core,
// so making :car-core evaluation-dependent on :app introduces a configuration
// cycle as soon as the shared car module is wired into the projected flavor.
subprojects {
    if (path !in setOf(":app", ":car-core", ":automotive")) {
        project.evaluationDependsOn(":app")
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
