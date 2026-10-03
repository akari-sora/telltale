allprojects {
    repositories {
        google()
        mavenCentral()
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
