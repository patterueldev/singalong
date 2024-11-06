enableFeaturePreview("TYPESAFE_PROJECT_ACCESSORS")

pluginManagement {
    settings.extra[""] = ""
    repositories {
        google()
        gradlePluginPortal()
        mavenCentral()
    }
}

dependencyResolutionManagement {
    versionCatalogs {
        val libs by creating {
            val versionsPath = file("../gradle").resolve("libs.versions.toml")
            from(files(versionsPath))
        }
    }
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "singalong"

include(":singalong-api")
project(":singalong-api").projectDir = file("api")

apply(from = file("../api_settings.gradle.kts"))
