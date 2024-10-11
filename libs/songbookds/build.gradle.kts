plugins {
    alias(libs.plugins.kotlinJvm)
    alias(libs.plugins.ktlint)
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
    implementation(projects.common)
    implementation(projects.mongoDs)
    implementation(projects.songbook)
    testImplementation(kotlin("test"))
}
tasks.test {
    useJUnitPlatform()
}
kotlin {
    jvmToolchain(21)
}
