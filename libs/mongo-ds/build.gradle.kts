plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.kotlin.spring)
    alias(libs.plugins.ktlint)
}

group = "io.patterueldev"
version = "1.0-SNAPSHOT"

dependencies {
    implementation(libs.spring.boot.data.mongodb)
    implementation(libs.spring.boot.security)
    implementation(projects.common)
    testImplementation(kotlin("test"))
}
tasks.test {
    useJUnitPlatform()
}
kotlin {
    jvmToolchain(21)
}
