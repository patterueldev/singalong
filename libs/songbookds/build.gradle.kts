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
    implementation(project(":shared"))
    implementation(project(":mongo-ds"))
    implementation(project(":songbook"))
    testImplementation(kotlin("test"))
}
tasks.test {
    useJUnitPlatform()
}
kotlin {
    jvmToolchain(21)
}