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
    implementation(libs.springBootDataMongo)
    implementation(libs.springBootSecurity)
    implementation(projects.mongoDs)
    api(projects.common)
    testImplementation(kotlin("test"))
}
tasks.test {
    useJUnitPlatform()
}
kotlin {
    jvmToolchain(21)
}
