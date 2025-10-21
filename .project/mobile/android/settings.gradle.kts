pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "InfiniR"
include(":app")

// Link to frontend components from monorepo
includeBuild("../../../.frontend/android") {
    dependencySubstitution {
        substitute(module("com.ricemono:components")).using(project(":components"))
    }
}
