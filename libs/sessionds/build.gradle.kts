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
    implementation(projects.commonds)
    api(projects.session)
    testImplementation(kotlin("test"))
}
tasks.test {
    useJUnitPlatform()
}
kotlin {
    jvmToolchain(21)
}
