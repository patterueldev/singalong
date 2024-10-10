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

include(":shared")
project(":shared").projectDir = file("./libs/shared")

include(":common")
project(":common").projectDir = file("./libs/common")

////include(":sharedds")
////project(":sharedds").projectDir = file("./libs/sharedds")
////
////include(":shared-domain")
////project(":shared-domain").projectDir = file("./libs/shared-domain")

include(":mongo-ds")
project(":mongo-ds").projectDir = file("./libs/mongo-ds")

include(":sessionroom")
project(":sessionroom").projectDir = file("./libs/sessionroom")

include(":sessionroomds")
project(":sessionroomds").projectDir = file("./libs/sessionroomds")

include(":songidentifier")
project(":songidentifier").projectDir = file("./libs/songidentifier")

include(":songidentifierds")
project(":songidentifierds").projectDir = file("./libs/songidentifierds")

include(":songbook")
project(":songbook").projectDir = file("./libs/songbook")

include(":songbookds")
project(":songbookds").projectDir = file("./libs/songbookds")