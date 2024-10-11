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
    implementation(libs.openAIClient)
    implementation(libs.springBootWebflux)
    implementation(libs.springBootDataMongo)
    implementation(project(":shared"))
    implementation(project(":mongo-ds"))
    implementation(project(":songidentifier"))
    testImplementation(kotlin("test"))
}
tasks.test {
    useJUnitPlatform()
}
kotlin {
    jvmToolchain(21)
}
