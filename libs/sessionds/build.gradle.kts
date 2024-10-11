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
    implementation(libs.springBootWeb)
    implementation(libs.springBootSecurity)
    implementation(libs.jsonWebTokenApi)
    implementation(libs.jacksonKotlin)
    runtimeOnly(libs.jsonWebTokenImpl)
    runtimeOnly(libs.jsonWebTokenJackson)
    implementation(projects.shared)
    implementation(projects.common)
    implementation(projects.mongoDs)
    implementation(projects.session)
    testImplementation(kotlin("test"))
}
tasks.test {
    useJUnitPlatform()
}
kotlin {
    jvmToolchain(21)
}
