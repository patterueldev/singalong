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

include(":commonds")
project(":commonds").projectDir = file("./libs/commonds")

include(":mongo-ds")
project(":mongo-ds").projectDir = file("./libs/mongo-ds")

include(":session")
project(":session").projectDir = file("./libs/session")

include(":sessionds")
project(":sessionds").projectDir = file("./libs/sessionds")

include(":songidentifier")
project(":songidentifier").projectDir = file("./libs/songidentifier")

include(":songidentifierds")
project(":songidentifierds").projectDir = file("./libs/songidentifierds")

include(":songbook")
project(":songbook").projectDir = file("./libs/songbook")

include(":songbookds")
project(":songbookds").projectDir = file("./libs/songbookds")
