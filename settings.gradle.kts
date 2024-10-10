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
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "singalong"
include(":api")

include(":clients")

include(":shared")
project(":shared").projectDir = file("./libs/shared")

////include(":sharedds")
////project(":sharedds").projectDir = file("./libs/sharedds")
////
////include(":shared-domain")
////project(":shared-domain").projectDir = file("./libs/shared-domain")

include(":mongo-ds")
project(":mongo-ds").projectDir = file("./libs/mongo-ds")

include(":sessionroom")
project(":sessionroom").projectDir = file("./libs/sessionroom")

include(":songidentifier")
project(":songidentifier").projectDir = file("./libs/songidentifier")

include(":songidentifierds")
project(":songidentifierds").projectDir = file("./libs/songidentifierds")

include(":songbook")
project(":songbook").projectDir = file("./libs/songbook")

include(":songbookds")
project(":songbookds").projectDir = file("./libs/songbookds")