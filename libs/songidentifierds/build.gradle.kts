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
    implementation(libs.openai.client)
    implementation(libs.spring.boot.webflux)
    implementation(libs.spring.boot.data.mongodb)
    implementation(libs.ktor.client.cio)
    implementation(projects.mongoDs)
    implementation(projects.common)
    api(projects.songidentifier)
    testImplementation(kotlin("test"))
}
tasks.test {
    useJUnitPlatform()
}
kotlin {
    jvmToolchain(21)
}
