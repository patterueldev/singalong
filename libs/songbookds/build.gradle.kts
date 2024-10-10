plugins {
    alias(libs.plugins.kotlinJvm)
}

group = "io.patterueldev"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencies {
    implementation(libs.kotlinxCoroutinesCore)
    implementation(libs.springBootDataMongo)
    implementation(projects.shared)
//    implementation(project(":shared"))
    implementation(projects.common)
//    implementation(project(":common"))
    implementation(projects.mongoDs)
//    implementation(project(":mongo-ds"))
    implementation(projects.songbook)
//    implementation(project(":songbook"))
    testImplementation(kotlin("test"))
}
tasks.test {
    useJUnitPlatform()
}
kotlin {
    jvmToolchain(21)
}