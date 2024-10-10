plugins {
    alias(libs.plugins.kotlinJvm)
    alias(libs.plugins.kotlinSpring)
}

group = "io.patterueldev"
version = "1.0-SNAPSHOT"

dependencies {
    implementation(libs.springBootDataMongo)
    testImplementation(kotlin("test"))
}
tasks.test {
    useJUnitPlatform()
}
kotlin {
    jvmToolchain(21)
}