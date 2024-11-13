plugins {
    alias(libs.plugins.kotlin.jvm)
    alias(libs.plugins.ktlint)
}

group = "io.patterueldev"
version = "1.0-SNAPSHOT"

repositories {
    mavenCentral()
}

dependencies {
    implementation(libs.kotlinx.coroutines.core)
    implementation(libs.spring.boot.data.mongodb)
    implementation(libs.spring.boot.web)
    implementation(libs.spring.boot.security)
    implementation(projects.mongoDs)
    implementation(libs.jackson.kotlin)
    implementation(libs.jsonwebtoken.api)
    runtimeOnly(libs.jsonwebtoken.impl)
    runtimeOnly(libs.jsonwebtoken.jackson)
    api(projects.common)
    testImplementation(kotlin("test"))
}
tasks.test {
    useJUnitPlatform()
}
kotlin {
    jvmToolchain(21)
}
