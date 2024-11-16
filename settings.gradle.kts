enableFeaturePreview("TYPESAFE_PROJECT_ACCESSORS")

pluginManagement {
    settings.extra[""] = ""
    repositories {
        google()
        gradlePluginPortal()
        mavenCentral()
    }
}
plugins {
    id("org.gradle.toolchains.foojay-resolver-convention") version "0.8.0"
}

dependencyResolutionManagement {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "singalong"

include(":api")
project(":api").projectDir = file("server/api")

apply(from = file("api_settings.gradle.kts"))
apply(from = file("client_settings.gradle.kts"))
